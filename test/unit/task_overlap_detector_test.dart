import 'package:flutter_test/flutter_test.dart';
import 'package:flow_day/features/tasks/domain/entities/task.dart';
import 'package:flow_day/features/tasks/domain/services/task_overlap_detector.dart';

void main() {
  group('TaskOverlapDetector', () {
    const today = '2026-11-19';

    final taskA = Task(
      id: 'task-a',
      title: 'Task A',
      dateKey: today,
      startMin: 540, // 09:00
      endMin: 600, // 10:00
      createdAt: 1000,
      updatedAt: 1000,
    );

    test('detects no overlap for adjacent non-overlapping tasks', () {
      final adjacentBefore = Task(
        id: 'task-before',
        title: 'Before',
        dateKey: today,
        startMin: 480, // 08:00
        endMin: 540, // 09:00
        createdAt: 1000,
        updatedAt: 1000,
      );

      final adjacentAfter = Task(
        id: 'task-after',
        title: 'After',
        dateKey: today,
        startMin: 600, // 10:00
        endMin: 660, // 11:00
        createdAt: 1000,
        updatedAt: 1000,
      );

      final overlaps = TaskOverlapDetector.findOverlaps(
        candidate: taskA,
        existingTasks: [adjacentBefore, adjacentAfter],
      );

      expect(overlaps, isEmpty);
    });

    test('detects partial overlap with existing task', () {
      final partialOverlap = Task(
        id: 'task-partial',
        title: 'Partial Overlap',
        dateKey: today,
        startMin: 570, // 09:30
        endMin: 630, // 10:30
        createdAt: 1000,
        updatedAt: 1000,
      );

      final overlaps = TaskOverlapDetector.findOverlaps(
        candidate: taskA,
        existingTasks: [partialOverlap],
      );

      expect(overlaps.length, 1);
      expect(overlaps.first.id, 'task-partial');
    });

    test('detects complete containment / engulfing overlap', () {
      final insideTask = Task(
        id: 'task-inside',
        title: 'Inside',
        dateKey: today,
        startMin: 550, // 09:10
        endMin: 590, // 09:50
        createdAt: 1000,
        updatedAt: 1000,
      );

      final overlaps = TaskOverlapDetector.findOverlaps(
        candidate: taskA,
        existingTasks: [insideTask],
      );

      expect(overlaps.length, 1);
      expect(overlaps.first.id, 'task-inside');
    });

    test('excludes candidate itself when editing', () {
      final editedTaskA = taskA.copyWith(title: 'Task A (Renamed)');

      final overlaps = TaskOverlapDetector.findOverlaps(
        candidate: editedTaskA,
        existingTasks: [taskA],
      );

      expect(overlaps, isEmpty);
    });

    test('excludes completed and skipped tasks from overlap clashes', () {
      final completedTask = taskA.copyWith(
        id: 'task-completed',
        status: 'completed',
      );

      final skippedTask = taskA.copyWith(
        id: 'task-skipped',
        status: 'skipped',
      );

      final overlaps = TaskOverlapDetector.findOverlaps(
        candidate: taskA,
        existingTasks: [completedTask, skippedTask],
      );

      expect(overlaps, isEmpty);
    });

    test('suggestNextSlotStart computes next slot start with break', () {
      final nextSlot = TaskOverlapDetector.suggestNextSlotStart(
        conflictingTask: taskA,
        durationMin: 45,
        breakMin: 15,
        dayEndMin: 1380, // 23:00
      );

      // taskA ends at 600 (10:00). Next start should be 600 + 15 = 615 (10:15 AM)
      expect(nextSlot, 615);
    });
  });
}
