import 'package:flutter_test/flutter_test.dart';
import 'package:flow_day/core/time/app_clock.dart';
import 'package:flow_day/features/home/domain/home_dashboard_state.dart';
import 'package:flow_day/features/tasks/domain/entities/task.dart';

void main() {
  group('HomeDashboardState Unit Tests', () {
    const today = '2026-11-19';

    Task createTask({
      required String id,
      required String title,
      required int startMin,
      required int endMin,
      String status = 'pending',
    }) {
      return Task(
        id: id,
        title: title,
        dateKey: today,
        startMin: startMin,
        endMin: endMin,
        status: status,
        createdAt: 1000,
        updatedAt: 1000,
      );
    }

    test('Greeting boundaries: morning, afternoon, evening at hour edges via FakeClock', () {
      // Morning: 05:00 to 11:59
      expect(HomeDashboardState.computeGreeting(5, 'Khushi'), 'Good Morning, Khushi! ☀️');
      expect(HomeDashboardState.computeGreeting(11, 'Khushi'), 'Good Morning, Khushi! ☀️');

      // Afternoon: 12:00 to 16:59
      expect(HomeDashboardState.computeGreeting(12, 'Khushi'), 'Good Afternoon, Khushi! 🌤️');
      expect(HomeDashboardState.computeGreeting(16, 'Khushi'), 'Good Afternoon, Khushi! 🌤️');

      // Evening: 17:00 to 04:59
      expect(HomeDashboardState.computeGreeting(17, 'Khushi'), 'Good Evening, Khushi! 🌙');
      expect(HomeDashboardState.computeGreeting(23, 'Khushi'), 'Good Evening, Khushi! 🌙');
      expect(HomeDashboardState.computeGreeting(0, 'Khushi'), 'Good Evening, Khushi! 🌙');
      expect(HomeDashboardState.computeGreeting(4, 'Khushi'), 'Good Evening, Khushi! 🌙');

      // Empty name fallback
      expect(HomeDashboardState.computeGreeting(9, ''), 'Good Morning! ☀️');
      expect(HomeDashboardState.computeGreeting(14, '   '), 'Good Afternoon! 🌤️');
    });

    test('Counting rules: total, done, remaining, ring percentage, and focus minutes', () {
      // 0 tasks: ring % is 0, no division by zero
      final emptyState = HomeDashboardState.compute(
        dateKey: today,
        tasks: [],
        now: DateTime(2026, 11, 19, 10, 0),
        userName: 'Alex',
      );
      expect(emptyState.totalCount, 0);
      expect(emptyState.doneCount, 0);
      expect(emptyState.remainingCount, 0);
      expect(emptyState.progressPercent, 0);
      expect(emptyState.progressRatio, 0.0);
      expect(emptyState.trackStatus, TrackStatus.empty);

      // Tasks with mixed statuses:
      // - 1 completed (60 min)
      // - 1 pending (45 min)
      // - 1 incomplete (30 min)
      // - 1 postponed (30 min)
      // - 1 rescheduled (45 min)
      // - 1 skipped (30 min)
      final mixedTasks = [
        createTask(id: '1', title: 'Task 1', startMin: 480, endMin: 540, status: 'completed'),
        createTask(id: '2', title: 'Task 2', startMin: 540, endMin: 585, status: 'pending'),
        createTask(id: '3', title: 'Task 3', startMin: 600, endMin: 630, status: 'incomplete'),
        createTask(id: '4', title: 'Task 4', startMin: 630, endMin: 660, status: 'postponed'),
        createTask(id: '5', title: 'Task 5', startMin: 660, endMin: 705, status: 'rescheduled'),
        createTask(id: '6', title: 'Task 6', startMin: 720, endMin: 750, status: 'skipped'),
      ];

      final mixedState = HomeDashboardState.compute(
        dateKey: today,
        tasks: mixedTasks,
        now: DateTime(2026, 11, 19, 8, 0),
        userName: 'Alex',
      );

      // Total = 6, ActiveTotal = 5 (6 - 1 skipped)
      expect(mixedState.totalCount, 6);
      expect(mixedState.activeTotal, 5);
      // Done = 1
      expect(mixedState.doneCount, 1);
      // Remaining = 4 (pending, incomplete, postponed, rescheduled; skipped is NOT remaining)
      expect(mixedState.remainingCount, 4);
      // Ring %: 1/5 = 20%
      expect(mixedState.progressPercent, 20);
      // Focus minutes: only completed tasks -> 60 min -> "1h"
      expect(mixedState.focusMinutes, 60);
      expect(mixedState.formattedFocusTime, '1h');
    });

    test('Ring percentage: exactly 1 of 3 (33%) and all done (100%)', () {
      final threeTasks = [
        createTask(id: '1', title: 'Task 1', startMin: 500, endMin: 560, status: 'completed'),
        createTask(id: '2', title: 'Task 2', startMin: 600, endMin: 660, status: 'pending'),
        createTask(id: '3', title: 'Task 3', startMin: 700, endMin: 760, status: 'pending'),
      ];

      final oneOfThree = HomeDashboardState.compute(
        dateKey: today,
        tasks: threeTasks,
        now: DateTime(2026, 11, 19, 8, 0),
        userName: 'Alex',
      );
      expect(oneOfThree.progressPercent, 33);
      expect(oneOfThree.doneCount, 1);
      expect(oneOfThree.totalCount, 3);

      final allDoneTasks = [
        createTask(id: '1', title: 'Task 1', startMin: 500, endMin: 560, status: 'completed'),
        createTask(id: '2', title: 'Task 2', startMin: 600, endMin: 660, status: 'completed'),
      ];
      final allDoneState = HomeDashboardState.compute(
        dateKey: today,
        tasks: allDoneTasks,
        now: DateTime(2026, 11, 19, 12, 0),
        userName: 'Alex',
      );
      expect(allDoneState.progressPercent, 100);
      expect(allDoneState.progressRatio, 1.0);
      expect(allDoneState.trackStatus, TrackStatus.allDone);
    });

    test('On track badge: On track when no pending task is delayed; Behind when any task is delayed', () {
      final now = DateTime(2026, 11, 19, 10, 30); // 10:30 AM = 630 min

      // Task 1: 09:00 - 10:00 (540 - 600 min). Still pending at 10:30 -> DELAYED
      final behindTasks = [
        createTask(id: '1', title: 'Delayed Task', startMin: 540, endMin: 600, status: 'pending'),
        createTask(id: '2', title: 'Upcoming Task', startMin: 660, endMin: 720, status: 'pending'),
      ];
      final behindState = HomeDashboardState.compute(
        dateKey: today,
        tasks: behindTasks,
        now: now,
        userName: 'User',
      );
      expect(behindState.trackStatus, TrackStatus.behind);

      // If delayed task was marked completed -> now ON TRACK
      final onTrackTasks = [
        createTask(id: '1', title: 'Finished Task', startMin: 540, endMin: 600, status: 'completed'),
        createTask(id: '2', title: 'Upcoming Task', startMin: 660, endMin: 720, status: 'pending'),
      ];
      final onTrackState = HomeDashboardState.compute(
        dateKey: today,
        tasks: onTrackTasks,
        now: now,
        userName: 'User',
      );
      expect(onTrackState.trackStatus, TrackStatus.onTrack);
    });

    test('NOW card selection: earliest endMin wins when multiple tasks are in progress', () {
      final now = DateTime(2026, 11, 19, 10, 15); // 10:15 AM = 615 min

      // Both tasks are in progress (600 <= 615 < 660 and 590 <= 615 < 645)
      // Task A ends at 11:00 (660 min)
      // Task B ends at 10:45 (645 min) -> EARLIER endMin!
      final taskA = createTask(id: 'a', title: 'Task A', startMin: 600, endMin: 660);
      final taskB = createTask(id: 'b', title: 'Task B', startMin: 590, endMin: 645);

      final state = HomeDashboardState.compute(
        dateKey: today,
        tasks: [taskA, taskB],
        now: now,
        userName: 'User',
      );

      expect(state.nowTask, isNotNull);
      expect(state.nowTask!.id, 'b', reason: 'Task with earliest endMin must be chosen');
      expect(state.nowTaskType, NowTaskType.inProgress);
    });

    test('NOW card selection: next upcoming task when none is in progress', () {
      final now = DateTime(2026, 11, 19, 9, 30); // 09:30 AM = 570 min

      // Both tasks are upcoming:
      // Task A starts at 10:00 (600 min) -> EARLIEST startMin!
      // Task B starts at 11:30 (690 min)
      final taskA = createTask(id: 'a', title: 'Task A', startMin: 600, endMin: 660);
      final taskB = createTask(id: 'b', title: 'Task B', startMin: 690, endMin: 750);

      final state = HomeDashboardState.compute(
        dateKey: today,
        tasks: [taskB, taskA],
        now: now,
        userName: 'User',
      );

      expect(state.nowTask, isNotNull);
      expect(state.nowTask!.id, 'a');
      expect(state.nowTaskType, NowTaskType.nextUpcoming);
    });

    test('NOW card selection: earliest delayed task with delayed style when only delayed remain', () {
      final now = DateTime(2026, 11, 19, 14, 0); // 14:00 = 840 min

      // Both tasks ended in morning and are still pending:
      // Task A: 09:00 - 10:00 (540 - 600) -> EARLIEST delayed start!
      // Task B: 11:00 - 12:00 (660 - 720)
      final taskA = createTask(id: 'a', title: 'Morning Task', startMin: 540, endMin: 600);
      final taskB = createTask(id: 'b', title: 'Noon Task', startMin: 660, endMin: 720);

      final state = HomeDashboardState.compute(
        dateKey: today,
        tasks: [taskB, taskA],
        now: now,
        userName: 'User',
      );

      expect(state.nowTask, isNotNull);
      expect(state.nowTask!.id, 'a');
      expect(state.nowTaskType, NowTaskType.earliestDelayed);
    });

    test('FakeClock tickStream emits updates deterministically', () async {
      final clock = FakeClock(DateTime(2026, 11, 19, 10, 0));
      final emitted = <DateTime>[];

      final sub = clock.tickStream.listen(emitted.add);

      // Advance clock by 1 minute
      clock.advance(const Duration(minutes: 1));
      // Set to specific time
      clock.setNow(DateTime(2026, 11, 19, 10, 5));

      await Future.delayed(const Duration(milliseconds: 20));
      expect(emitted.length, 3);
      expect(emitted[0], DateTime(2026, 11, 19, 10, 0));
      expect(emitted[1], DateTime(2026, 11, 19, 10, 1));
      expect(emitted[2], DateTime(2026, 11, 19, 10, 5));

      await sub.cancel();
      clock.dispose();
    });

    test('Skipped tasks counting: 1 completed, 1 skipped -> remaining=0, activeTotal=1, 100%, TrackStatus.allDone', () {
      final tasksWithSkipped = [
        createTask(id: '1', title: 'Finished Task', startMin: 500, endMin: 560, status: 'completed'),
        createTask(id: '2', title: 'Skipped Task', startMin: 600, endMin: 660, status: 'skipped'),
      ];

      final state = HomeDashboardState.compute(
        dateKey: today,
        tasks: tasksWithSkipped,
        now: DateTime(2026, 11, 19, 12, 0),
        userName: 'Alex',
      );

      // Total = 2, ActiveTotal = 1 (2 - 1 skipped), Done = 1, Remaining = 0
      expect(state.totalCount, 2);
      expect(state.activeTotal, 1);
      expect(state.doneCount, 1);
      expect(state.remainingCount, 0);
      expect(state.progressPercent, 100);
      // Since all active tasks are completed, status is allDone ('• Completed')
      expect(state.trackStatus, TrackStatus.allDone);
    });

    test('All-skipped tasks: evaluated as TrackStatus.empty ("• No tasks") with 0% ring', () {
      final allSkippedTasks = [
        createTask(id: '1', title: 'Skipped 1', startMin: 500, endMin: 560, status: 'skipped'),
        createTask(id: '2', title: 'Skipped 2', startMin: 600, endMin: 660, status: 'skipped'),
      ];

      final state = HomeDashboardState.compute(
        dateKey: today,
        tasks: allSkippedTasks,
        now: DateTime(2026, 11, 19, 12, 0),
        userName: 'Alex',
      );

      expect(state.totalCount, 2);
      expect(state.activeTotal, 0);
      expect(state.doneCount, 0);
      expect(state.remainingCount, 0);
      expect(state.progressPercent, 0);
      // All-skipped rule: evaluates to TrackStatus.empty ("• No tasks")
      expect(state.trackStatus, TrackStatus.empty);
    });

    test('SystemClock.tickStream produces stream and cancels cleanly when unlistened', () async {
      const clock = SystemClock();
      final stream = clock.tickStream;
      final sub = stream.listen((_) {});

      // Cancel immediately to verify onCancel cleanly tears down timer without error
      await sub.cancel();
      expect(true, isTrue);
    });

    test('Midnight rollover: date and greeting roll over deterministically', () {
      // 23:59 on Nov 19
      final beforeMidnight = DateTime(2026, 11, 19, 23, 59);
      final stateBefore = HomeDashboardState.compute(
        dateKey: '2026-11-19',
        tasks: [],
        now: beforeMidnight,
        userName: 'Alex',
      );
      expect(stateBefore.formattedDate, 'Thursday, November 19');
      expect(stateBefore.greeting, 'Good Evening, Alex! 🌙');

      // 00:01 on Nov 20
      final afterMidnight = DateTime(2026, 11, 20, 0, 1);
      final stateAfter = HomeDashboardState.compute(
        dateKey: '2026-11-20',
        tasks: [],
        now: afterMidnight,
        userName: 'Alex',
      );
      expect(stateAfter.formattedDate, 'Friday, November 20');
      expect(stateAfter.greeting, 'Good Evening, Alex! 🌙');

      // 06:00 on Nov 20
      final morningAfter = DateTime(2026, 11, 20, 6, 0);
      final stateMorning = HomeDashboardState.compute(
        dateKey: '2026-11-20',
        tasks: [],
        now: morningAfter,
        userName: 'Alex',
      );
      expect(stateMorning.formattedDate, 'Friday, November 20');
      expect(stateMorning.greeting, 'Good Morning, Alex! ☀️');
    });
  });
}
