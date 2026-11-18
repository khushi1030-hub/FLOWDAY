import 'package:material_ui/material_ui.dart';

/// Utilities for converting minute offsets (0-1439) into user-friendly time strings.
class TimeUtils {
  TimeUtils._();

  /// Converts TimeOfDay to minute offset from midnight (0..1439).
  static int timeOfDayToMinutes(TimeOfDay time) {
    return time.hour * 60 + time.minute;
  }

  /// Converts minute offset from midnight to TimeOfDay.
  static TimeOfDay minutesToTimeOfDay(int minutes) {
    final safe = minutes % 1440;
    return TimeOfDay(hour: safe ~/ 60, minute: safe % 60);
  }

  /// Converts minutes from midnight (e.g. 570) to 12-hour formatted time (e.g. "09:30 AM").
  static String formatMinutesToTime(int minutes) {
    final int safeMinutes = minutes % 1440;
    final int hour24 = safeMinutes ~/ 60;
    final int minute = safeMinutes % 60;

    final int hour12 = (hour24 == 0 || hour24 == 12) ? 12 : hour24 % 12;
    final String period = hour24 >= 12 ? 'PM' : 'AM';

    final String hourStr = hour12.toString().padLeft(2, '0');
    final String minuteStr = minute.toString().padLeft(2, '0');

    return '$hourStr:$minuteStr $period';
  }

  /// Formats a time range (e.g. 540 to 600 -> "09:00 - 10:00 AM").
  static String formatTimeRange(int startMin, int endMin) {
    return '${formatMinutesToTime(startMin)} – ${formatMinutesToTime(endMin)}';
  }

  /// Formats duration in minutes (e.g. 45 -> "45m", 90 -> "1h 30m").
  static String formatDuration(int minutes) {
    if (minutes < 60) {
      return '${minutes}m';
    }
    final int hours = minutes ~/ 60;
    final int remMin = minutes % 60;
    if (remMin == 0) {
      return '${hours}h';
    }
    return '${hours}h ${remMin}m';
  }

  /// Calculates total awake minutes in a 24-hour cycle, supporting past-midnight sleep.
  static int calculateAwakeMinutes(int wakeMin, int sleepMin) {
    return (sleepMin - wakeMin + 1440) % 1440;
  }

  /// Calculates total sleep minutes in a 24-hour cycle.
  static int calculateSleepMinutes(int wakeMin, int sleepMin) {
    final awake = calculateAwakeMinutes(wakeMin, sleepMin);
    return (1440 - awake) % 1440;
  }

  /// Validates daily rhythm (wake, sleep, and nightly review), supporting past-midnight sleep.
  /// Returns null if valid, or a friendly error message if invalid.
  static String? validateRhythm({
    required int wakeMin,
    required int sleepMin,
    required int nightlyMin,
  }) {
    if (wakeMin == sleepMin) {
      return 'Wake-up and sleeping times cannot be the same.';
    }
    final awake = calculateAwakeMinutes(wakeMin, sleepMin);
    final sleep = calculateSleepMinutes(wakeMin, sleepMin);

    if (awake < 180) {
      return 'Awake time must be at least 3 hours.';
    }
    if (sleep < 180) {
      return 'Sleep time must be at least 3 hours.';
    }

    // Relative to wake time (wake = minute 0)
    final relativeNightly = (nightlyMin - wakeMin + 1440) % 1440;
    if (relativeNightly <= 0 || relativeNightly >= awake) {
      return 'Nightly review reminder should be between wake-up and sleep time.';
    }
    return null;
  }
}
