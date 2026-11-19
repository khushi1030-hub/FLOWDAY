import '../../../../core/time/day_window.dart';

/// Pure domain service calculating spatial coordinates and layout metrics for the daily schedule timeline.
class TimelineLayoutCalculator {
  const TimelineLayoutCalculator._();

  /// Timeline vertical zoom scale: 1.2 dp per minute (72 dp per hour).
  static const double pxPerMinute = 1.2;

  /// Width allocated for left-hand hour labels.
  static const double hourLabelWidth = 52.0;

  /// Calculates the vertical Y-offset in dp for a given [minute] from midnight within [dayWindow].
  static double minuteToY(int minute, DayWindow dayWindow) {
    if (dayWindow.isNormal || dayWindow.is24Hour) {
      final base = dayWindow.is24Hour ? 0 : dayWindow.startMin;
      return (minute - base) * pxPerMinute;
    } else {
      // Overnight window: [startMin, 1440) followed by [0, endMin]
      if (minute >= dayWindow.startMin) {
        return (minute - dayWindow.startMin) * pxPerMinute;
      } else {
        final eveningPortion = 1440 - dayWindow.startMin;
        return (eveningPortion + minute) * pxPerMinute;
      }
    }
  }

  /// Calculates height in dp for a duration in minutes.
  static double durationToHeight(int durationMinutes) {
    return durationMinutes * pxPerMinute;
  }

  /// Total height of the scrollable timeline canvas.
  static double totalCanvasHeight(DayWindow dayWindow) {
    return dayWindow.totalMinutes * pxPerMinute;
  }

  /// Returns sorted list of hour marker minutes (0, 60, 120, ...) that fall within [dayWindow].
  static List<int> getHourMarkers(DayWindow dayWindow) {
    final markers = <int>[];
    if (dayWindow.isNormal) {
      final startHour = dayWindow.startMin ~/ 60;
      final endHour = (dayWindow.endMin + 59) ~/ 60;
      for (int h = startHour; h <= endHour && h < 24; h++) {
        markers.add(h * 60);
      }
    } else if (dayWindow.is24Hour) {
      for (int h = 0; h < 24; h++) {
        markers.add(h * 60);
      }
    } else {
      // Overnight window: evening hours from startMin to 23:00, then morning hours from 00:00 to endMin
      final eveningStartHour = dayWindow.startMin ~/ 60;
      for (int h = eveningStartHour; h < 24; h++) {
        markers.add(h * 60);
      }
      final morningEndHour = (dayWindow.endMin + 59) ~/ 60;
      for (int h = 0; h <= morningEndHour; h++) {
        markers.add(h * 60);
      }
    }
    return markers;
  }
}
