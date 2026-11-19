import '../../../../core/time/day_window.dart';
import '../../../tasks/domain/entities/task.dart';
import '../entities/free_time_gap.dart';

/// Pure domain service calculating free-time intervals between scheduled tasks.
///
/// Per Decision D16:
/// - Minimum gap threshold is 15 minutes.
/// - Intervals smaller than 15 minutes are considered natural transition buffers and excluded.
class FreeGapCalculator {
  const FreeGapCalculator._();

  static const int defaultMinGapMinutes = 15;

  /// Calculates all free gaps within the specified [dayWindow] that meet or exceed [minGapMinutes].
  static List<FreeTimeGap> calculateGaps({
    required List<Task> tasks,
    required DayWindow dayWindow,
    int minGapMinutes = defaultMinGapMinutes,
  }) {
    // Only active, scheduled tasks occupy timeline slots. Skipped tasks do not block time.
    final activeTasks = tasks
        .where((t) => t.status != 'skipped')
        .toList()
      ..sort((a, b) => a.startMin.compareTo(b.startMin));

    if (dayWindow.isNormal) {
      return _calculateNormalGaps(activeTasks, dayWindow.startMin, dayWindow.endMin, minGapMinutes);
    } else if (dayWindow.is24Hour) {
      return _calculateNormalGaps(activeTasks, 0, 1440, minGapMinutes);
    } else {
      // Overnight rhythm: two continuous segments: [startMin, 1440) and [0, endMin]
      final eveningGaps = _calculateNormalGaps(
        activeTasks.where((t) => t.startMin >= dayWindow.startMin).toList(),
        dayWindow.startMin,
        1440,
        minGapMinutes,
      );
      final morningGaps = _calculateNormalGaps(
        activeTasks.where((t) => t.endMin <= dayWindow.endMin).toList(),
        0,
        dayWindow.endMin,
        minGapMinutes,
      );
      return [...eveningGaps, ...morningGaps];
    }
  }

  static List<FreeTimeGap> _calculateNormalGaps(
    List<Task> sortedTasks,
    int boundaryStart,
    int boundaryEnd,
    int minGapMinutes,
  ) {
    final gaps = <FreeTimeGap>[];
    int currentCursor = boundaryStart;

    for (final task in sortedTasks) {
      final taskStart = task.startMin.clamp(boundaryStart, boundaryEnd);
      final taskEnd = task.endMin.clamp(boundaryStart, boundaryEnd);

      if (taskStart > currentCursor) {
        final gapDuration = taskStart - currentCursor;
        if (gapDuration >= minGapMinutes) {
          gaps.add(FreeTimeGap(startMin: currentCursor, endMin: taskStart));
        }
      }
      if (taskEnd > currentCursor) {
        currentCursor = taskEnd;
      }
    }

    if (boundaryEnd > currentCursor) {
      final finalGapDuration = boundaryEnd - currentCursor;
      if (finalGapDuration >= minGapMinutes) {
        gaps.add(FreeTimeGap(startMin: currentCursor, endMin: boundaryEnd));
      }
    }

    return gaps;
  }
}
