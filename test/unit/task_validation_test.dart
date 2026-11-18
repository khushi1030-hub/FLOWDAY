import 'package:flutter_test/flutter_test.dart';
import 'package:flow_day/features/tasks/domain/services/task_validation.dart';

void main() {
  group('TaskValidator', () {
    const defaultWake = 420; // 07:00 AM
    const defaultSleep = 1380; // 11:00 PM

    test('validates correct task within day window', () {
      final result = TaskValidator.validate(
        title: 'Deep Work',
        startMin: 540, // 09:00 AM
        endMin: 600, // 10:00 AM
        dayStartMin: defaultWake,
        dayEndMin: defaultSleep,
      );

      expect(result.isValid, isTrue);
      expect(result.errorMessage, isNull);
    });

    test('rejects empty or whitespace title', () {
      final resultEmpty = TaskValidator.validate(
        title: '',
        startMin: 540,
        endMin: 600,
        dayStartMin: defaultWake,
        dayEndMin: defaultSleep,
      );
      expect(resultEmpty.isValid, isFalse);
      expect(resultEmpty.errorMessage, 'Please enter a task title.');

      final resultWhitespace = TaskValidator.validate(
        title: '   ',
        startMin: 540,
        endMin: 600,
        dayStartMin: defaultWake,
        dayEndMin: defaultSleep,
      );
      expect(resultWhitespace.isValid, isFalse);
      expect(resultWhitespace.errorMessage, 'Please enter a task title.');
    });

    test('rejects end time before or equal to start time', () {
      final resultEqual = TaskValidator.validate(
        title: 'Study',
        startMin: 600,
        endMin: 600,
        dayStartMin: defaultWake,
        dayEndMin: defaultSleep,
      );
      expect(resultEqual.isValid, isFalse);
      expect(resultEqual.errorMessage, 'End time must be after start time.');

      final resultBefore = TaskValidator.validate(
        title: 'Study',
        startMin: 600,
        endMin: 540,
        dayStartMin: defaultWake,
        dayEndMin: defaultSleep,
      );
      expect(resultBefore.isValid, isFalse);
      expect(resultBefore.errorMessage, 'End time must be after start time.');
    });

    test('accepts short task (any endMin > startMin)', () {
      final result = TaskValidator.validate(
        title: 'Quick check',
        startMin: 600,
        endMin: 602, // 2 minutes duration
        dayStartMin: defaultWake,
        dayEndMin: defaultSleep,
      );
      expect(result.isValid, isTrue);
    });

    test('rejects task crossing midnight (23:30-00:30)', () {
      // 23:30 (1410 min) to 00:30 next day (1470 min)
      final resultAbsolute = TaskValidator.validate(
        title: 'Late Night Coding',
        startMin: 1410, // 23:30
        endMin: 1470, // 00:30 next day
        dayStartMin: 0,
        dayEndMin: 1440,
      );
      expect(resultAbsolute.isValid, isFalse);
      expect(resultAbsolute.errorMessage, "Tasks cannot cross midnight. Please split into tomorrow's schedule.");

      // 23:30 (1410 min) to 00:30 as clock time (30 min)
      final resultClockTime = TaskValidator.validate(
        title: 'Late Night Coding',
        startMin: 1410, // 23:30
        endMin: 30, // 00:30
        dayStartMin: 0,
        dayEndMin: 1440,
      );
      expect(resultClockTime.isValid, isFalse);
      expect(resultClockTime.errorMessage, "Tasks cannot cross midnight. Please split into tomorrow's schedule.");
    });

    test('rejects task outside daytime waking hours', () {
      // Before wake time (06:00 < 07:00)
      final resultEarly = TaskValidator.validate(
        title: 'Early Workout',
        startMin: 360, // 06:00 AM
        endMin: 420, // 07:00 AM
        dayStartMin: defaultWake,
        dayEndMin: defaultSleep,
      );
      expect(resultEarly.isValid, isFalse);
      expect(resultEarly.errorMessage, contains('waking hours'));

      // After sleep time (23:30 > 23:00)
      final resultLate = TaskValidator.validate(
        title: 'Late Reading',
        startMin: 1350, // 22:30
        endMin: 1410, // 23:30
        dayStartMin: defaultWake,
        dayEndMin: defaultSleep,
      );
      expect(resultLate.isValid, isFalse);
      expect(resultLate.errorMessage, contains('waking hours'));
    });

    test('supports overnight rhythm with sleep past midnight', () {
      const wake = 420; // 07:00 AM
      const sleep = 30; // 00:30 AM (past midnight)

      // Task scheduled at 23:00 - 23:45 today should be valid
      final result = TaskValidator.validate(
        title: 'Late Wind-down',
        startMin: 1380, // 23:00
        endMin: 1425, // 23:45
        dayStartMin: wake,
        dayEndMin: sleep,
      );
      expect(result.isValid, isTrue);
    });

    test('supports 24-hour active window when wakeMin == sleepMin', () {
      const wake = 480; // 08:00 AM
      const sleep = 480; // 08:00 AM

      final result1 = TaskValidator.validate(
        title: 'Early Owl',
        startMin: 60, // 01:00 AM
        endMin: 120, // 02:00 AM
        dayStartMin: wake,
        dayEndMin: sleep,
      );
      expect(result1.isValid, isTrue);

      final result2 = TaskValidator.validate(
        title: 'Afternoon Flow',
        startMin: 800, // 13:20
        endMin: 900, // 15:00
        dayStartMin: wake,
        dayEndMin: sleep,
      );
      expect(result2.isValid, isTrue);
    });
  });
}
