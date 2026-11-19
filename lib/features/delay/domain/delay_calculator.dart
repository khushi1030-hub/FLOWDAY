import '../../tasks/domain/entities/task.dart';

/// Representation of how a single downstream task is affected by an extension.
enum DelayImpactType {
  shifted,
  breakShortened,
  overlapsFixed,
  fixed,
}

class DelayImpactItem {
  const DelayImpactItem({
    required this.task,
    required this.impactType,
    required this.originalStartMin,
    required this.originalEndMin,
    required this.newStartMin,
    required this.newEndMin,
    this.conflictingWithTask,
    this.message,
  });

  final Task task;
  final DelayImpactType impactType;
  final int originalStartMin;
  final int originalEndMin;
  final int newStartMin;
  final int newEndMin;
  final Task? conflictingWithTask;
  final String? message;
}

/// Result of evaluating an extra time extension on downstream tasks.
class DelayCalculationResult {
  const DelayCalculationResult({
    required this.newEndMin,
    required this.impactedItems,
    required this.hasFixedCollision,
    required this.exceedsDayEnd,
    this.firstConflictingTask,
  });

  final int newEndMin;
  final List<DelayImpactItem> impactedItems;
  final bool hasFixedCollision;
  final bool exceedsDayEnd;
  final Task? firstConflictingTask;

  /// Returns only flexible tasks that can be shifted cleanly in DB if applied directly.
  List<Task> get tasksToUpdate {
    return impactedItems
        .where((i) => i.impactType == DelayImpactType.shifted || i.impactType == DelayImpactType.breakShortened)
        .map((i) => i.task.copyWith(
              startMin: i.newStartMin,
              endMin: i.newEndMin,
              wasRescheduled: true,
            ))
        .toList();
  }
}

/// Free slot candidate for rescheduling later today or tomorrow.
class FreeSlotCandidate {
  const FreeSlotCandidate({
    required this.dateKey,
    required this.startMin,
    required this.endMin,
  });

  final String dateKey;
  final int startMin;
  final int endMin;

  int get durationMin => endMin - startMin;
}

/// Pure domain calculator for smart delay management and ripple impact preview.
///
/// Pure Dart (no Flutter, no DB, testable in isolation).
class DelayCalculator {
  const DelayCalculator();

  /// Calculates the downstream ripple effect of extending [delayedTask] by [extraMinutes].
  DelayCalculationResult calculateImpact({
    required Task delayedTask,
    required int extraMinutes,
    required List<Task> dayTasks,
    required int dayEndMin,
  }) {
    final newEndMin = delayedTask.endMin + extraMinutes;
    final impactedItems = <DelayImpactItem>[];
    bool hasFixedCollision = false;
    Task? firstConflictingTask;

    // Filter and sort active subsequent tasks on the same day
    final subsequentTasks = dayTasks
        .where((t) =>
            t.id != delayedTask.id &&
            t.dateKey == delayedTask.dateKey &&
            t.status != 'completed' &&
            t.status != 'skipped' &&
            t.startMin >= delayedTask.startMin)
        .toList()
      ..sort((a, b) => a.startMin.compareTo(b.startMin));

    // Find any fixed tasks on that day
    final fixedTasks = subsequentTasks.where((t) => t.isFixed).toList();

    int currentPushedEdge = newEndMin;

    for (int i = 0; i < subsequentTasks.length; i++) {
      final task = subsequentTasks[i];

      if (task.startMin >= currentPushedEdge && !hasFixedCollision) {
        // No overlap with this task or any following tasks
        break;
      }

      final taskDuration = task.endMin - task.startMin;
      final isFixed = task.isFixed;
      final isBreak = task.kind == 'break';

      if (isFixed) {
        // Fixed task: cannot be moved
        hasFixedCollision = true;
        firstConflictingTask ??= task;
        impactedItems.add(DelayImpactItem(
          task: task,
          impactType: DelayImpactType.fixed,
          originalStartMin: task.startMin,
          originalEndMin: task.endMin,
          newStartMin: task.startMin,
          newEndMin: task.endMin,
          message: 'Fixed',
        ));
        break;
      }

      // Check if shifting this task pushes it into a downstream fixed task
      final prospectiveStart = currentPushedEdge;
      int effectiveDuration = taskDuration;
      DelayImpactType impactType = DelayImpactType.shifted;
      String message = 'Shifted';

      if (isBreak) {
        // Preview of shortened break if it would relieve pressure, or standard shift
        if (taskDuration > 15) {
          effectiveDuration = 15;
          impactType = DelayImpactType.breakShortened;
          message = 'Shortened to 15m';
        } else {
          impactType = DelayImpactType.breakShortened;
          message = 'Break preserved';
        }
      }

      final prospectiveEnd = prospectiveStart + effectiveDuration;

      // Check if prospectiveEnd overlaps any fixed task
      Task? fixedOverlap;
      for (final fixed in fixedTasks) {
        if (prospectiveEnd > fixed.startMin && prospectiveStart < fixed.endMin) {
          fixedOverlap = fixed;
          break;
        }
      }

      if (fixedOverlap != null) {
        hasFixedCollision = true;
        firstConflictingTask ??= fixedOverlap;
        impactedItems.add(DelayImpactItem(
          task: task,
          impactType: DelayImpactType.overlapsFixed,
          originalStartMin: task.startMin,
          originalEndMin: task.endMin,
          newStartMin: prospectiveStart,
          newEndMin: prospectiveEnd,
          conflictingWithTask: fixedOverlap,
          message: 'Overlaps ${fixedOverlap.title}',
        ));

        // Also add the fixed task to the impact list to match Screen 15
        impactedItems.add(DelayImpactItem(
          task: fixedOverlap,
          impactType: DelayImpactType.fixed,
          originalStartMin: fixedOverlap.startMin,
          originalEndMin: fixedOverlap.endMin,
          newStartMin: fixedOverlap.startMin,
          newEndMin: fixedOverlap.endMin,
          message: 'Fixed',
        ));
        break;
      } else {
        impactedItems.add(DelayImpactItem(
          task: task,
          impactType: impactType,
          originalStartMin: task.startMin,
          originalEndMin: task.endMin,
          newStartMin: prospectiveStart,
          newEndMin: prospectiveEnd,
          message: message,
        ));
        currentPushedEdge = prospectiveEnd;
      }
    }

    final exceedsDayEnd = currentPushedEdge > dayEndMin;

    return DelayCalculationResult(
      newEndMin: newEndMin,
      impactedItems: impactedItems,
      hasFixedCollision: hasFixedCollision,
      exceedsDayEnd: exceedsDayEnd,
      firstConflictingTask: firstConflictingTask,
    );
  }

  /// Finds the earliest free slot later today after [currentMin] fitting the task.
  FreeSlotCandidate? findFirstFreeSlotToday({
    required Task task,
    required List<Task> dayTasks,
    required int currentMin,
    required int dayEndMin,
    int minDuration = 15,
  }) {
    final taskDuration = task.endMin - task.startMin;
    final searchStart = task.endMin > currentMin ? task.endMin : currentMin;

    // Filter active tasks today that occur at or after searchStart
    final activeTasks = dayTasks
        .where((t) =>
            t.id != task.id &&
            t.status != 'completed' &&
            t.status != 'skipped' &&
            t.endMin > searchStart)
        .toList()
      ..sort((a, b) => a.startMin.compareTo(b.startMin));

    int cursor = searchStart;

    for (final other in activeTasks) {
      if (other.startMin > cursor) {
        final gap = other.startMin - cursor;
        if (gap >= taskDuration && gap >= minDuration) {
          return FreeSlotCandidate(
            dateKey: task.dateKey,
            startMin: cursor,
            endMin: cursor + taskDuration,
          );
        }
      }
      if (other.endMin > cursor) {
        cursor = other.endMin;
      }
    }

    // Check remaining free time until dayEndMin
    if (dayEndMin - cursor >= taskDuration && (dayEndMin - cursor) >= minDuration) {
      return FreeSlotCandidate(
        dateKey: task.dateKey,
        startMin: cursor,
        endMin: cursor + taskDuration,
      );
    }

    return null;
  }

  /// Finds the first available slot tomorrow starting at wake time.
  FreeSlotCandidate findFirstFreeSlotTomorrow({
    required Task task,
    required String tomorrowDateKey,
    required List<Task> tomorrowTasks,
    required int wakeMin,
    required int sleepMin,
  }) {
    final taskDuration = task.endMin - task.startMin;

    final activeTasks = tomorrowTasks
        .where((t) =>
            t.status != 'completed' &&
            t.status != 'skipped' &&
            t.endMin > wakeMin)
        .toList()
      ..sort((a, b) => a.startMin.compareTo(b.startMin));

    int cursor = wakeMin;

    for (final other in activeTasks) {
      if (other.startMin > cursor) {
        final gap = other.startMin - cursor;
        if (gap >= taskDuration) {
          return FreeSlotCandidate(
            dateKey: tomorrowDateKey,
            startMin: cursor,
            endMin: cursor + taskDuration,
          );
        }
      }
      if (other.endMin > cursor) {
        cursor = other.endMin;
      }
    }

    return FreeSlotCandidate(
      dateKey: tomorrowDateKey,
      startMin: cursor,
      endMin: cursor + taskDuration,
    );
  }
}
