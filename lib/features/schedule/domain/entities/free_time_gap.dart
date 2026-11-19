import '../../../../core/utils/time_utils.dart';

/// Represents an available, unscheduled free time interval on the daily timeline.
class FreeTimeGap {
  const FreeTimeGap({
    required this.startMin,
    required this.endMin,
  }) : assert(endMin > startMin);

  final int startMin;
  final int endMin;

  int get durationMin => endMin - startMin;

  /// Formatted range, e.g. "01:30 - 02:30 PM".
  String get formattedRange => TimeUtils.formatTimeRange(startMin, endMin);
}
