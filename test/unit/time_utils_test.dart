import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flow_day/core/utils/time_utils.dart';

void main() {
  group('TimeUtils', () {
    test('formatMinutesToTime formats 12-hour AM/PM correctly', () {
      expect(TimeUtils.formatMinutesToTime(420), '07:00 AM');
      expect(TimeUtils.formatMinutesToTime(1380), '11:00 PM');
      expect(TimeUtils.formatMinutesToTime(1290), '09:30 PM');
      expect(TimeUtils.formatMinutesToTime(0), '12:00 AM');
      expect(TimeUtils.formatMinutesToTime(720), '12:00 PM');
      expect(TimeUtils.formatMinutesToTime(75), '01:15 AM');
      expect(TimeUtils.formatMinutesToTime(795), '01:15 PM');
    });

    test('timeOfDayToMinutes converts accurately', () {
      expect(TimeUtils.timeOfDayToMinutes(const TimeOfDay(hour: 7, minute: 0)), 420);
      expect(TimeUtils.timeOfDayToMinutes(const TimeOfDay(hour: 23, minute: 0)), 1380);
      expect(TimeUtils.timeOfDayToMinutes(const TimeOfDay(hour: 21, minute: 30)), 1290);
      expect(TimeUtils.timeOfDayToMinutes(const TimeOfDay(hour: 0, minute: 0)), 0);
    });

    test('minutesToTimeOfDay converts accurately', () {
      final t1 = TimeUtils.minutesToTimeOfDay(420);
      expect(t1.hour, 7);
      expect(t1.minute, 0);

      final t2 = TimeUtils.minutesToTimeOfDay(1290);
      expect(t2.hour, 21);
      expect(t2.minute, 30);
    });

    test('formatTimeRange formats bounds correctly', () {
      expect(TimeUtils.formatTimeRange(540, 600), '09:00 AM – 10:00 AM');
      expect(TimeUtils.formatTimeRange(1080, 1140), '06:00 PM – 07:00 PM');
    });

    test('formatDuration formats minutes and hours', () {
      expect(TimeUtils.formatDuration(15), '15m');
      expect(TimeUtils.formatDuration(60), '1h');
      expect(TimeUtils.formatDuration(90), '1h 30m');
      expect(TimeUtils.formatDuration(125), '2h 5m');
    });

    test('calculateAwakeMinutes and calculateSleepMinutes support overnight sleep', () {
      // Standard: 07:00 (420) to 23:00 (1380)
      expect(TimeUtils.calculateAwakeMinutes(420, 1380), 960); // 16h
      expect(TimeUtils.calculateSleepMinutes(420, 1380), 480); // 8h

      // Overnight: 07:00 (420) to 00:30 (30)
      expect(TimeUtils.calculateAwakeMinutes(420, 30), 1050); // 17.5h
      expect(TimeUtils.calculateSleepMinutes(420, 30), 390); // 6.5h

      // Late night: 09:00 (540) to 02:00 (120)
      expect(TimeUtils.calculateAwakeMinutes(540, 120), 1020); // 17h
      expect(TimeUtils.calculateSleepMinutes(540, 120), 420); // 7h
    });

    test('validateRhythm handles standard and past-midnight sleep schedules', () {
      // Valid standard day
      expect(
        TimeUtils.validateRhythm(wakeMin: 420, sleepMin: 1380, nightlyMin: 1290),
        isNull,
      );

      // Valid overnight sleep: wake 07:00 (420), sleep 00:30 (30), nightly 22:30 (1350)
      expect(
        TimeUtils.validateRhythm(wakeMin: 420, sleepMin: 30, nightlyMin: 1350),
        isNull,
      );

      // Valid overnight sleep: wake 07:00 (420), sleep 01:00 (60), nightly 21:30 (1290)
      expect(
        TimeUtils.validateRhythm(wakeMin: 420, sleepMin: 60, nightlyMin: 1290),
        isNull,
      );

      // Invalid: wake == sleep
      expect(
        TimeUtils.validateRhythm(wakeMin: 420, sleepMin: 420, nightlyMin: 1290),
        'Wake-up and sleeping times cannot be the same.',
      );

      // Invalid: awake duration too short (< 3h)
      expect(
        TimeUtils.validateRhythm(wakeMin: 420, sleepMin: 480, nightlyMin: 450),
        'Awake time must be at least 3 hours.',
      );

      // Invalid: nightly reminder during sleep window
      // Wake 07:00 (420), sleep 00:30 (30), nightly 02:00 (120 - user is asleep)
      expect(
        TimeUtils.validateRhythm(wakeMin: 420, sleepMin: 30, nightlyMin: 120),
        'Nightly review reminder should be between wake-up and sleep time.',
      );
    });
  });
}
