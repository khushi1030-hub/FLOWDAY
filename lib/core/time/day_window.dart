import '../utils/time_utils.dart';

/// Shared domain representation of a user's daily waking window.
///
/// Canonical definition:
/// - startMin < endMin: Normal daytime window (e.g. 07:00 to 23:00)
/// - startMin > endMin: Overnight waking window crossing midnight (e.g. 14:00 to 04:00)
/// - startMin == endMin: 24-hour active window (no sleep bounds)
class DayWindow {
  const DayWindow({
    required this.startMin,
    required this.endMin,
  });

  final int startMin;
  final int endMin;

  /// Returns true if the window spans the entire 24 hours.
  bool get is24Hour => startMin == endMin;

  /// Returns true if wake time is earlier than sleep time within the same calendar day.
  bool get isNormal => startMin < endMin;

  /// Returns true if sleep time is past midnight (startMin > endMin).
  bool get isOvernight => startMin > endMin;

  /// Checks if [targetStartMin, targetEndMin] is fully contained within the waking window.
  bool isIntervalWithin(int targetStartMin, int targetEndMin) {
    if (is24Hour) return true;
    if (isNormal) {
      return targetStartMin >= startMin && targetEndMin <= endMin;
    }
    // Overnight: waking hours span [startMin, 1440) and [0, endMin]
    return (targetStartMin >= startMin && targetEndMin <= 1440) ||
        (targetStartMin >= 0 && targetEndMin <= endMin);
  }

  /// Checks if a single minute [min] is within the waking hours.
  bool isMinuteWithin(int min) {
    if (is24Hour) return true;
    if (isNormal) {
      return min >= startMin && min <= endMin;
    }
    return (min >= startMin && min < 1440) || (min >= 0 && min <= endMin);
  }

  /// Total active/awake minutes in the day window.
  int get totalMinutes {
    if (is24Hour) return 1440;
    if (isNormal) return endMin - startMin;
    return (1440 - startMin) + endMin;
  }

  /// Formatted string representing the window, e.g. "07:00 AM – 11:00 PM".
  String get formattedRange {
    final startStr = TimeUtils.formatMinutesToTime(startMin);
    final endStr = TimeUtils.formatMinutesToTime(endMin);
    return '$startStr – $endStr';
  }
}
