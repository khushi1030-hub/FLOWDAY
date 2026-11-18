import '../entities/task.dart';

/// Pure domain service for detecting scheduling overlaps and conflicts.
class TaskOverlapDetector {
  const TaskOverlapDetector._();

  /// Finds all tasks on the same date that overlap with the candidate task.
  /// Ignores the candidate task itself (by ID), completed tasks, and skipped tasks.
  static List<Task> findOverlaps({
    required Task candidate,
    required List<Task> existingTasks,
  }) {
    return existingTasks.where((task) {
      // Exclude comparing against itself
      if (task.id == candidate.id) return false;

      // Completed or skipped tasks do not cause active scheduling clashes
      if (task.status == 'completed' || task.status == 'skipped') return false;

      // Overlap formula: max(startA, startB) < min(endA, endB)
      final maxStart = candidate.startMin > task.startMin ? candidate.startMin : task.startMin;
      final minEnd = candidate.endMin < task.endMin ? candidate.endMin : task.endMin;

      return maxStart < minEnd;
    }).toList();
  }

  /// Suggests the next available start minute after a conflicting task + break.
  static int suggestNextSlotStart({
    required Task conflictingTask,
    required int durationMin,
    required int breakMin,
    required int dayEndMin,
  }) {
    final proposedStart = conflictingTask.endMin + breakMin;
    final proposedEnd = proposedStart + durationMin;
    if (proposedEnd <= dayEndMin) {
      return proposedStart;
    }
    return conflictingTask.endMin;
  }
}
