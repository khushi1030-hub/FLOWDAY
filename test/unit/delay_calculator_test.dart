import 'package:flutter_test/flutter_test.dart';
import 'package:flow_day/features/delay/domain/delay_calculator.dart';
import 'package:flow_day/features/tasks/domain/entities/task.dart';

void main() {
  const calculator = DelayCalculator();

  Task createTask({
    required String id,
    required String title,
    required int startMin,
    required int endMin,
    String dateKey = '2026-05-14',
    bool isFixed = false,
    String kind = 'task',
    String status = 'pending',
  }) {
    return Task(
      id: id,
      title: title,
      dateKey: dateKey,
      startMin: startMin,
      endMin: endMin,
      isFixed: isFixed,
      kind: kind,
      status: status,
      createdAt: 1000,
      updatedAt: 1000,
    );
  }

  group('DelayCalculator Worked Example (FLOWDAY.md Section 6)', () {
    // Schedule: 09:00-10:00 Study, 10:00-10:30 Breakfast, 10:30-11:30 Assignment,
    // 11:30-12:00 Break (protected), 12:00-13:00 Exercise (fixed).
    final study = createTask(id: 't1', title: 'Study', startMin: 540, endMin: 600);
    final breakfast = createTask(id: 't2', title: 'Breakfast', startMin: 600, endMin: 630);
    final assignment = createTask(id: 't3', title: 'Assignment', startMin: 630, endMin: 690);
    final morningBreak = createTask(id: 't4', title: 'Break', startMin: 690, endMin: 720, kind: 'break');
    final exercise = createTask(id: 't5', title: 'Exercise', startMin: 720, endMin: 780, isFixed: true);

    final allTasks = [study, breakfast, assignment, morningBreak, exercise];

    test('extending Study by +30 min shifts flexible tasks and detects collision with fixed Exercise', () {
      final result = calculator.calculateImpact(
        delayedTask: study,
        extraMinutes: 30,
        dayTasks: allTasks,
        dayEndMin: 1380, // 23:00
      );

      expect(result.newEndMin, 630); // 10:30
      expect(result.hasFixedCollision, isTrue);
      expect(result.firstConflictingTask?.title, 'Exercise');

      // Breakfast shifted 10:30 -> 11:00
      final breakfastImpact = result.impactedItems.firstWhere((i) => i.task.id == 't2');
      expect(breakfastImpact.newStartMin, 630);
      expect(breakfastImpact.newEndMin, 660);
      expect(breakfastImpact.impactType, DelayImpactType.shifted);

      // Assignment shifted 11:00 -> 12:00
      final assignmentImpact = result.impactedItems.firstWhere((i) => i.task.id == 't3');
      expect(assignmentImpact.newStartMin, 660);
      expect(assignmentImpact.newEndMin, 720);
      expect(assignmentImpact.impactType, DelayImpactType.shifted);

      // Break overlaps or pushes into fixed Exercise (12:00)
      final breakImpact = result.impactedItems.firstWhere((i) => i.task.id == 't4');
      expect(breakImpact.impactType, DelayImpactType.overlapsFixed);
      expect(breakImpact.conflictingWithTask?.title, 'Exercise');
    });
  });

  group('DelayCalculator Clean Ripple Shifts (No Fixed Collisions)', () {
    test('shifts flexible downstream tasks cleanly without collision', () {
      final taskA = createTask(id: 'a', title: 'Task A', startMin: 540, endMin: 600); // 09:00 - 10:00
      final taskB = createTask(id: 'b', title: 'Task B', startMin: 600, endMin: 660); // 10:00 - 11:00
      final taskC = createTask(id: 'c', title: 'Task C', startMin: 660, endMin: 720); // 11:00 - 12:00

      final result = calculator.calculateImpact(
        delayedTask: taskA,
        extraMinutes: 15,
        dayTasks: [taskA, taskB, taskC],
        dayEndMin: 1380,
      );

      expect(result.newEndMin, 615); // 10:15
      expect(result.hasFixedCollision, isFalse);
      expect(result.impactedItems.length, 2);

      expect(result.impactedItems[0].task.id, 'b');
      expect(result.impactedItems[0].newStartMin, 615);
      expect(result.impactedItems[0].newEndMin, 675);
      expect(result.impactedItems[0].impactType, DelayImpactType.shifted);

      expect(result.impactedItems[1].task.id, 'c');
      expect(result.impactedItems[1].newStartMin, 675);
      expect(result.impactedItems[1].newEndMin, 735);
      expect(result.impactedItems[1].impactType, DelayImpactType.shifted);

      final toUpdate = result.tasksToUpdate;
      expect(toUpdate.length, 2);
      expect(toUpdate[0].startMin, 615);
      expect(toUpdate[0].wasRescheduled, isTrue);
      expect(toUpdate[1].startMin, 675);
      expect(toUpdate[1].wasRescheduled, isTrue);
    });

    test('absorbed by existing free gap with zero downstream tasks affected', () {
      final taskA = createTask(id: 'a', title: 'Task A', startMin: 540, endMin: 600); // 09:00 - 10:00
      final taskB = createTask(id: 'b', title: 'Task B', startMin: 660, endMin: 720); // 11:00 - 12:00

      // +30 min ends at 10:30, which is before Task B's start at 11:00
      final result = calculator.calculateImpact(
        delayedTask: taskA,
        extraMinutes: 30,
        dayTasks: [taskA, taskB],
        dayEndMin: 1380,
      );

      expect(result.newEndMin, 630);
      expect(result.impactedItems, isEmpty);
      expect(result.hasFixedCollision, isFalse);
      expect(result.tasksToUpdate, isEmpty);
    });
  });

  group('DelayCalculator Free Slot Search', () {
    test('findFirstFreeSlotToday finds earliest gap fitting duration', () {
      final currentTask = createTask(id: 'a', title: 'Current Task', startMin: 540, endMin: 600); // 60 min duration
      final nextTask1 = createTask(id: 'b', title: 'Task B', startMin: 600, endMin: 720); // 10:00 - 12:00
      final nextTask2 = createTask(id: 'c', title: 'Task C', startMin: 780, endMin: 840); // 13:00 - 14:00

      // Free gap between 12:00 (720) and 13:00 (780) is 60 minutes
      final slot = calculator.findFirstFreeSlotToday(
        task: currentTask,
        dayTasks: [currentTask, nextTask1, nextTask2],
        currentMin: 600,
        dayEndMin: 1380,
      );

      expect(slot, isNotNull);
      expect(slot?.startMin, 720);
      expect(slot?.endMin, 780);
      expect(slot?.durationMin, 60);
    });

    test('findFirstFreeSlotToday returns null when no gap fits task duration', () {
      final currentTask = createTask(id: 'a', title: 'Big Task', startMin: 540, endMin: 660); // 120 min duration
      final busy1 = createTask(id: 'b', title: 'Busy 1', startMin: 660, endMin: 1000);
      final busy2 = createTask(id: 'c', title: 'Busy 2', startMin: 1010, endMin: 1380);

      final slot = calculator.findFirstFreeSlotToday(
        task: currentTask,
        dayTasks: [currentTask, busy1, busy2],
        currentMin: 660,
        dayEndMin: 1380,
      );

      expect(slot, isNull);
    });

    test('findFirstFreeSlotTomorrow finds first slot starting at wakeMin', () {
      final task = createTask(id: 'a', title: 'Study', startMin: 540, endMin: 600); // 60 min
      final tomorrowTask1 = createTask(
        id: 'tm1',
        title: 'Morning Run',
        dateKey: '2026-05-15',
        startMin: 420, // 07:00
        endMin: 480, // 08:00
      );

      final candidate = calculator.findFirstFreeSlotTomorrow(
        task: task,
        tomorrowDateKey: '2026-05-15',
        tomorrowTasks: [tomorrowTask1],
        wakeMin: 420, // 07:00
        sleepMin: 1380,
      );

      // Earliest free gap is at 08:00 (480) for 60m -> 480 to 540 (09:00)
      expect(candidate.dateKey, '2026-05-15');
      expect(candidate.startMin, 480);
      expect(candidate.endMin, 540);
    });
  });

  group('DelayCalculator Bedtime Boundaries & Edge Cases', () {
    test('detects when ripple shift exceeds dayEndMin', () {
      final taskA = createTask(id: 'a', title: 'Late Task', startMin: 1320, endMin: 1360); // 22:00 - 22:40
      final taskB = createTask(id: 'b', title: 'Last Task', startMin: 1360, endMin: 1380); // 22:40 - 23:00

      final result = calculator.calculateImpact(
        delayedTask: taskA,
        extraMinutes: 30, // ends at 1390
        dayTasks: [taskA, taskB],
        dayEndMin: 1380, // 23:00 sleep time
      );

      expect(result.exceedsDayEnd, isTrue);
    });
  });
}
