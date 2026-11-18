import 'package:flutter_test/flutter_test.dart';
import 'package:flow_day/features/tasks/domain/entities/task_status.dart';

void main() {
  group('TaskStatusResolver', () {
    final fixedNow = DateTime(2026, 11, 17, 10, 30); // 10:30 AM = 630 minutes
    const today = '2026-11-17';
    const yesterday = '2026-11-16';
    const tomorrow = '2026-11-18';

    test('Completed status always returns completed regardless of time', () {
      final status = TaskStatusResolver.resolve(
        status: 'completed',
        dateKey: today,
        startMin: 500,
        endMin: 600,
        now: fixedNow,
      );
      expect(status, TaskRuntimeStatus.completed);
    });

    test('Incomplete status returns incomplete', () {
      final status = TaskStatusResolver.resolve(
        status: 'incomplete',
        dateKey: today,
        startMin: 500,
        endMin: 600,
        now: fixedNow,
      );
      expect(status, TaskRuntimeStatus.incomplete);
    });

    test('Postponed status returns postponed', () {
      final status = TaskStatusResolver.resolve(
        status: 'postponed',
        dateKey: today,
        startMin: 500,
        endMin: 600,
        now: fixedNow,
      );
      expect(status, TaskRuntimeStatus.postponed);
    });

    test('Skipped status returns skipped', () {
      final status = TaskStatusResolver.resolve(
        status: 'skipped',
        dateKey: today,
        startMin: 500,
        endMin: 600,
        now: fixedNow,
      );
      expect(status, TaskRuntimeStatus.skipped);
    });

    test('Pending task on past day is resolved to delayed', () {
      final status = TaskStatusResolver.resolve(
        status: 'pending',
        dateKey: yesterday,
        startMin: 500,
        endMin: 600,
        now: fixedNow,
      );
      expect(status, TaskRuntimeStatus.delayed);
    });

    test('Pending task on future day is resolved to upcoming', () {
      final status = TaskStatusResolver.resolve(
        status: 'pending',
        dateKey: tomorrow,
        startMin: 500,
        endMin: 600,
        now: fixedNow,
      );
      expect(status, TaskRuntimeStatus.upcoming);
    });

    test('Pending task today before start time is upcoming', () {
      // Current time: 10:30 AM (630 min). Task: 11:00 AM (660 min) - 12:00 PM (720 min)
      final status = TaskStatusResolver.resolve(
        status: 'pending',
        dateKey: today,
        startMin: 660,
        endMin: 720,
        now: fixedNow,
      );
      expect(status, TaskRuntimeStatus.upcoming);
    });

    test('Pending task today between start and end time is inProgress', () {
      // Current time: 10:30 AM (630 min). Task: 10:00 AM (600 min) - 11:00 AM (660 min)
      final status = TaskStatusResolver.resolve(
        status: 'pending',
        dateKey: today,
        startMin: 600,
        endMin: 660,
        now: fixedNow,
      );
      expect(status, TaskRuntimeStatus.inProgress);
    });

    test('Pending task today after end time is delayed / overdue', () {
      // Current time: 10:30 AM (630 min). Task: 09:00 AM (540 min) - 10:00 AM (600 min)
      final status = TaskStatusResolver.resolve(
        status: 'pending',
        dateKey: today,
        startMin: 540,
        endMin: 600,
        now: fixedNow,
      );
      expect(status, TaskRuntimeStatus.delayed);
    });
  });
}
