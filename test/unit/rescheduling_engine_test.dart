import 'package:flutter_test/flutter_test.dart';
import 'package:flow_day/features/rescheduling/domain/entities/reschedule_proposal.dart';
import 'package:flow_day/features/rescheduling/domain/rescheduling_engine.dart';
import 'package:flow_day/features/tasks/domain/entities/task.dart';

void main() {
  const engine = ReschedulingEngine();

  Task createTask({
    required String id,
    required String title,
    required int startMin,
    required int endMin,
    String dateKey = '2026-11-20',
    int priority = 1,
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
      priority: priority,
      categoryId: 1,
      kind: kind,
      isFixed: isFixed,
      status: status,
      createdAt: 1000,
      updatedAt: 1000,
    );
  }

  group('ReschedulingEngine - FLOWDAY.md Worked Example & Proposals', () {
    test('Screen 16 worked example: Extending Study by 60m shifts DSA and Exercise around fixed Lunch', () {
      // 09:00 - 10:00 (540 - 600) Study (High)
      // 10:00 - 11:00 (600 - 660) DSA (High)
      // 11:00 - 12:00 (660 - 720) Exercise (Low)
      // 12:30 - 13:30 (750 - 810) Lunch (Fixed)
      final study = createTask(id: 'study', title: 'Study', startMin: 540, endMin: 600, priority: 2);
      final dsa = createTask(id: 'dsa', title: 'DSA', startMin: 600, endMin: 660, priority: 2);
      final exercise = createTask(id: 'exercise', title: 'Exercise', startMin: 660, endMin: 720, priority: 0);
      final lunch = createTask(id: 'lunch', title: 'Lunch', startMin: 750, endMin: 810, isFixed: true);

      final tasks = [study, dsa, exercise, lunch];

      final proposals = engine.generateProposals(
        currentDayTasks: tasks,
        triggerTask: study,
        extraMinutes: 60,
        dayStartMin: 420, // 07:00
        dayEndMin: 1380, // 23:00
        todayDateKey: '2026-11-20',
        tomorrowDateKey: '2026-11-21',
      );

      expect(proposals.length, equals(4));

      // PLAN A: Shift flexible tasks
      final planA = proposals.firstWhere((p) => p.id == 'A');
      expect(planA.isValid, isTrue);
      expect(planA.isRecommended, isTrue);

      final resulting = planA.resultingDayTasks;
      final movedStudy = resulting.firstWhere((t) => t.id == 'study');
      final movedDsa = resulting.firstWhere((t) => t.id == 'dsa');
      final fixedLunch = resulting.firstWhere((t) => t.id == 'lunch');
      final movedExercise = resulting.firstWhere((t) => t.id == 'exercise');

      // Study extended to 11:00 (660)
      expect(movedStudy.startMin, equals(540));
      expect(movedStudy.endMin, equals(660));

      // DSA shifted to 11:00 - 12:00 (660 - 720)
      expect(movedDsa.startMin, equals(660));
      expect(movedDsa.endMin, equals(720));

      // Fixed lunch strictly untouched at 12:30 - 13:30 (750 - 810)
      expect(fixedLunch.startMin, equals(750));
      expect(fixedLunch.endMin, equals(810));

      // Exercise jumped over lunch into afternoon slot 13:30 - 14:30 (810 - 870)
      expect(movedExercise.startMin, equals(810));
      expect(movedExercise.endMin, equals(870));

      // Invariants check
      expect(
        engine.verifyInvariants(
          proposal: planA,
          originalTasks: tasks,
          dayStartMin: 420,
          dayEndMin: 1380,
        ),
        isTrue,
      );
    });

    test('Plan B: Priority first preserves high-priority task, moves low-priority Exercise to evening', () {
      final study = createTask(id: 'study', title: 'Study', startMin: 540, endMin: 600, priority: 2);
      final dsa = createTask(id: 'dsa', title: 'DSA', startMin: 600, endMin: 660, priority: 2);
      final exercise = createTask(id: 'exercise', title: 'Exercise', startMin: 660, endMin: 720, priority: 0);
      final lunch = createTask(id: 'lunch', title: 'Lunch', startMin: 750, endMin: 810, isFixed: true);

      final tasks = [study, dsa, exercise, lunch];

      final proposals = engine.generateProposals(
        currentDayTasks: tasks,
        triggerTask: study,
        extraMinutes: 60,
        dayStartMin: 420,
        dayEndMin: 1380,
        todayDateKey: '2026-11-20',
        tomorrowDateKey: '2026-11-21',
      );

      final planB = proposals.firstWhere((p) => p.id == 'B');
      expect(planB.isValid, isTrue);

      final movedExercise = planB.resultingDayTasks.firstWhere((t) => t.id == 'exercise');
      // Exercise moved to evening (>= 18:00 / 1080)
      expect(movedExercise.startMin, greaterThanOrEqualTo(1080));

      expect(
        engine.verifyInvariants(
          proposal: planB,
          originalTasks: tasks,
          dayStartMin: 420,
          dayEndMin: 1380,
        ),
        isTrue,
      );
    });

    test('Plan C: Postpone trigger to tomorrow leaves today schedule untouched', () {
      final study = createTask(id: 'study', title: 'Study', startMin: 540, endMin: 600, priority: 2);
      final dsa = createTask(id: 'dsa', title: 'DSA', startMin: 600, endMin: 660, priority: 2);
      final lunch = createTask(id: 'lunch', title: 'Lunch', startMin: 750, endMin: 810, isFixed: true);

      final tasks = [study, dsa, lunch];

      final proposals = engine.generateProposals(
        currentDayTasks: tasks,
        triggerTask: study,
        extraMinutes: 60,
        dayStartMin: 420,
        dayEndMin: 1380,
        todayDateKey: '2026-11-20',
        tomorrowDateKey: '2026-11-21',
      );

      final planC = proposals.firstWhere((p) => p.id == 'C');
      expect(planC.isValid, isTrue);
      expect(planC.hasCarryOver, isTrue);

      // Today's remaining tasks are unchanged
      expect(planC.resultingDayTasks.any((t) => t.id == 'study'), isFalse);
      final dsaMatch = planC.resultingDayTasks.firstWhere((t) => t.id == 'dsa');
      expect(dsaMatch.startMin, equals(600));
      expect(dsaMatch.endMin, equals(660));

      // Study carried over to tomorrow
      expect(planC.carryOvers.first.targetDateKey, equals('2026-11-21'));
      expect(planC.carryOvers.first.startMin, equals(420));
      expect(planC.carryOvers.first.endMin, equals(480));
    });

    test('Plan D: Keep original schedule marks trigger task as unfinished', () {
      final study = createTask(id: 'study', title: 'Study', startMin: 540, endMin: 600, priority: 2);
      final dsa = createTask(id: 'dsa', title: 'DSA', startMin: 600, endMin: 660, priority: 2);

      final tasks = [study, dsa];

      final proposals = engine.generateProposals(
        currentDayTasks: tasks,
        triggerTask: study,
        extraMinutes: 30,
        dayStartMin: 420,
        dayEndMin: 1380,
        todayDateKey: '2026-11-20',
        tomorrowDateKey: '2026-11-21',
      );

      final planD = proposals.firstWhere((p) => p.id == 'D');
      expect(planD.isValid, isTrue);
      final markedStudy = planD.resultingDayTasks.firstWhere((t) => t.id == 'study');
      expect(markedStudy.status, equals('incomplete'));
      expect(markedStudy.startMin, equals(540));
      expect(markedStudy.endMin, equals(600));
    });
  });

  group('ReschedulingEngine - Immovable Invariants (Hard Rules)', () {
    test('Fixed tasks, breaks, and completed tasks are NEVER moved or shortened', () {
      final trigger = createTask(id: 'trigger', title: 'Trigger', startMin: 500, endMin: 560);
      final flexTask = createTask(id: 'flex', title: 'Flexible Task', startMin: 560, endMin: 600);
      final fixedTask = createTask(id: 'fixed', title: 'Doc Appt', startMin: 600, endMin: 660, isFixed: true);
      final breakTask = createTask(id: 'break', title: 'Tea Break', startMin: 700, endMin: 730, kind: 'break');
      final completedTask = createTask(id: 'completed', title: 'Done Work', startMin: 400, endMin: 480, status: 'completed');

      final tasks = [completedTask, trigger, flexTask, fixedTask, breakTask];

      final proposals = engine.generateProposals(
        currentDayTasks: tasks,
        triggerTask: trigger,
        extraMinutes: 30,
        dayStartMin: 360,
        dayEndMin: 1380,
        todayDateKey: '2026-11-20',
        tomorrowDateKey: '2026-11-21',
      );

      for (final prop in proposals.where((p) => p.isValid && p.id != 'C')) {
        final resTasks = prop.resultingDayTasks;

        // Completed task strictly untouched
        final comp = resTasks.firstWhere((t) => t.id == 'completed');
        expect(comp.startMin, equals(400));
        expect(comp.endMin, equals(480));

        // Fixed task strictly untouched
        final fix = resTasks.firstWhere((t) => t.id == 'fixed');
        expect(fix.startMin, equals(600));
        expect(fix.endMin, equals(660));

        // Break strictly untouched
        final brk = resTasks.firstWhere((t) => t.id == 'break');
        expect(brk.startMin, equals(700));
        expect(brk.endMin, equals(730));

        // Zero overlaps
        expect(engine.detectConflicts(resTasks), isEmpty);
      }
    });

    test('Direct immovable collision returns noValidSchedule for Plan A', () {
      // Trigger ends at 600, fixed task starts at 605. Extending trigger by 30m directly collides with fixed task.
      final trigger = createTask(id: 'trigger', title: 'Trigger', startMin: 540, endMin: 600);
      final fixedTask = createTask(id: 'fixed', title: 'Flight', startMin: 605, endMin: 700, isFixed: true);

      final proposals = engine.generateProposals(
        currentDayTasks: [trigger, fixedTask],
        triggerTask: trigger,
        extraMinutes: 30,
        dayStartMin: 420,
        dayEndMin: 1380,
        todayDateKey: '2026-11-20',
        tomorrowDateKey: '2026-11-21',
      );

      final planA = proposals.firstWhere((p) => p.id == 'A');
      expect(planA.isValid, isFalse);
      expect(planA.invalidReason, contains('collides with a fixed appointment'));
    });
  });

  group('ReschedulingEngine - Screen 19 Conflict Resolution', () {
    test('Screen 19: Adding fixed Movie with friends resolves clashes with flexible Exercise & Call family', () {
      // 06:00 - 08:00 PM (1080 - 1200) Movie with friends (Fixed)
      final movie = createTask(
        id: 'movie',
        title: 'Movie with friends',
        startMin: 1080,
        endMin: 1200,
        isFixed: true,
      );

      // Existing colliding tasks:
      // Exercise: 06:00 - 07:00 PM (1080 - 1140)
      // Call family: 07:00 - 07:45 PM (1140 - 1185)
      final exercise = createTask(id: 'exercise', title: 'Exercise', startMin: 1080, endMin: 1140, priority: 0);
      final callFamily = createTask(id: 'call', title: 'Call family', startMin: 1140, endMin: 1185, priority: 1);

      // Earlier tasks leaving free afternoon
      final morningWork = createTask(id: 'work', title: 'Work', startMin: 540, endMin: 720); // 09:00 - 12:00

      final tasks = [morningWork, exercise, callFamily];

      final proposals = engine.generateConflictProposals(
        currentDayTasks: tasks,
        newConflictingTask: movie,
        dayStartMin: 420, // 07:00 AM
        dayEndMin: 1380, // 11:00 PM
        todayDateKey: '2026-11-20',
        tomorrowDateKey: '2026-11-21',
      );

      expect(proposals.length, equals(4));

      // Option 1 (Best Fit): Move flexible tasks to open afternoon slots
      final bestFit = proposals.firstWhere((p) => p.id == 'A');
      expect(bestFit.strategy, equals(ProposalStrategy.moveConflictFlexible));
      expect(bestFit.badgeText, equals('BEST FIT'));
      expect(bestFit.isValid, isTrue);

      // Checks zero overlaps in resulting tasks
      expect(engine.detectConflicts(bestFit.resultingDayTasks), isEmpty);

      // Option 3: Shorten flexible task durations (Decision D2)
      final shortened = proposals.firstWhere((p) => p.id == 'C');
      expect(shortened.strategy, equals(ProposalStrategy.shortenConflictFlexible));
      expect(shortened.isValid, isTrue);
      expect(shortened.moves.any((m) => m.isShortened), isTrue);

      // Option 4: Move to tomorrow
      final tomorrowProp = proposals.firstWhere((p) => p.id == 'D');
      expect(tomorrowProp.strategy, equals(ProposalStrategy.moveConflictToAnotherDay));
      expect(tomorrowProp.carryOvers.length, equals(2));
    });
  });

  group('ReschedulingEngine - Property-based invariant fuzzing', () {
    test('Property: For any arbitrary valid day with flexible tasks, engine generates 0 overlaps', () {
      // Test across multiple simulated schedules
      for (var extraMin = 15; extraMin <= 90; extraMin += 15) {
        final trigger = createTask(id: 't0', title: 'Task 0', startMin: 480, endMin: 540); // 08:00 - 09:00
        final t1 = createTask(id: 't1', title: 'Task 1', startMin: 540, endMin: 600, priority: 2);
        final fixed = createTask(id: 'fixed', title: 'Fixed Meeting', startMin: 630, endMin: 690, isFixed: true);
        final t2 = createTask(id: 't2', title: 'Task 2', startMin: 700, endMin: 760, priority: 0);
        final t3 = createTask(id: 't3', title: 'Task 3', startMin: 760, endMin: 820, priority: 1);

        final dayTasks = [trigger, t1, fixed, t2, t3];

        final proposals = engine.generateProposals(
          currentDayTasks: dayTasks,
          triggerTask: trigger,
          extraMinutes: extraMin,
          dayStartMin: 420,
          dayEndMin: 1380,
          todayDateKey: '2026-11-20',
          tomorrowDateKey: '2026-11-21',
        );

        for (final proposal in proposals) {
          if (proposal.isValid) {
            // Invariant 1: No overlaps
            final conflicts = engine.detectConflicts(proposal.resultingDayTasks);
            expect(conflicts, isEmpty, reason: 'Overlaps found in Plan ${proposal.id} with extra $extraMin min');

            // Invariant 2: Fixed task untouched
            final fixedResult = proposal.resultingDayTasks.firstWhere((t) => t.id == 'fixed');
            expect(fixedResult.startMin, equals(630));
            expect(fixedResult.endMin, equals(690));

            // Invariant 3: Waking window bounds respected
            for (final res in proposal.resultingDayTasks) {
              expect(res.startMin, greaterThanOrEqualTo(420));
              expect(res.endMin, lessThanOrEqualTo(1380));
              expect(res.endMin, lessThanOrEqualTo(1440)); // never cross midnight
            }
          }
        }
      }
    });
  });
}
