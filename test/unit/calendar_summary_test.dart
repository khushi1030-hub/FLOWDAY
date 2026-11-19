import 'package:flutter_test/flutter_test.dart';
import 'package:flow_day/features/schedule/domain/entities/calendar_day_summary.dart';
import 'package:flow_day/features/tasks/domain/entities/task.dart';

void main() {
  group('Calendar Summary Tests (Phase 6 Exit Checks)', () {
    const today = '2026-11-19';

    Task makeTask({
      required String id,
      required String dateKey,
      String status = 'pending',
    }) {
      return Task(
        id: id,
        title: 'Task $id',
        dateKey: dateKey,
        startMin: 600,
        endMin: 660,
        status: status,
        createdAt: 1000,
        updatedAt: 1000,
      );
    }

    test('Missed task definition: task on a past day that is not completed and not skipped', () {
      const pastDate = '2026-11-18'; // Yesterday

      final pastTasks = [
        makeTask(id: '1', dateKey: pastDate, status: 'completed'), // Completed
        makeTask(id: '2', dateKey: pastDate, status: 'pending'),   // MISSED!
        makeTask(id: '3', dateKey: pastDate, status: 'incomplete'),// MISSED!
        makeTask(id: '4', dateKey: pastDate, status: 'skipped'),   // Skipped -> NOT missed
        makeTask(id: '5', dateKey: pastDate, status: 'rescheduled'), // Rescheduled
      ];

      final summary = CalendarDaySummary.compute(
        dateKey: pastDate,
        tasksForDay: pastTasks,
        todayKey: today,
      );

      // Completed: 1
      expect(summary.completedCount, 1);
      // Rescheduled: 1
      expect(summary.rescheduledCount, 1);
      // Missed: 2 (pending and incomplete on past day)
      expect(summary.missedCount, 2);
      // Upcoming: 0 (it is in the past)
      expect(summary.upcomingCount, 0);

      // Dots present: completed, missed, rescheduled
      expect(summary.dots.contains(CalendarDotType.completed), isTrue);
      expect(summary.dots.contains(CalendarDotType.missed), isTrue);
      expect(summary.dots.contains(CalendarDotType.rescheduled), isTrue);
      expect(summary.dots.contains(CalendarDotType.upcoming), isFalse);
    });

    test('Today and future tasks are not counted as missed', () {
      final todayTasks = [
        makeTask(id: '1', dateKey: today, status: 'pending'),
        makeTask(id: '2', dateKey: today, status: 'completed'),
      ];

      final summary = CalendarDaySummary.compute(
        dateKey: today,
        tasksForDay: todayTasks,
        todayKey: today,
      );

      expect(summary.missedCount, 0);
      expect(summary.upcomingCount, 1);
      expect(summary.completedCount, 1);
      expect(summary.dots.contains(CalendarDotType.upcoming), isTrue);
      expect(summary.dots.contains(CalendarDotType.missed), isFalse);
    });

    test('Month aggregate metrics sum correctly', () {
      final allTasks = [
        makeTask(id: '1', dateKey: '2026-11-10', status: 'completed'),
        makeTask(id: '2', dateKey: '2026-11-10', status: 'completed'),
        makeTask(id: '3', dateKey: '2026-11-11', status: 'rescheduled'),
        makeTask(id: '4', dateKey: '2026-11-12', status: 'pending'), // Past -> Missed
        makeTask(id: '5', dateKey: '2026-11-19', status: 'pending'), // Today -> Upcoming
      ];

      final monthSummary = CalendarMonthSummary.compute(
        year: 2026,
        month: 11,
        allMonthTasks: allTasks,
        todayKey: today,
      );

      expect(monthSummary.totalCompleted, 2);
      expect(monthSummary.totalRescheduled, 1);
      expect(monthSummary.totalMissed, 1);
    });
  });
}
