import 'package:flutter_test/flutter_test.dart';
import 'package:flow_day/core/time/day_window.dart';

void main() {
  group('DayWindow Domain Tests', () {
    test('Normal daytime window: 07:00 to 23:00 (420 to 1380)', () {
      const window = DayWindow(startMin: 420, endMin: 1380);
      expect(window.isNormal, isTrue);
      expect(window.isOvernight, isFalse);
      expect(window.is24Hour, isFalse);
      expect(window.totalMinutes, 960); // 16 hours

      // Inside
      expect(window.isIntervalWithin(420, 480), isTrue);
      expect(window.isIntervalWithin(600, 700), isTrue);
      expect(window.isIntervalWithin(1300, 1380), isTrue);
      expect(window.isMinuteWithin(600), isTrue);

      // Outside
      expect(window.isIntervalWithin(400, 450), isFalse);
      expect(window.isIntervalWithin(1350, 1400), isFalse);
      expect(window.isMinuteWithin(300), isFalse);
      expect(window.formattedRange, '07:00 AM – 11:00 PM');
    });

    test('Overnight sleep window (sleep past midnight): 14:00 to 02:00 (840 to 120)', () {
      const window = DayWindow(startMin: 840, endMin: 120);
      expect(window.isNormal, isFalse);
      expect(window.isOvernight, isTrue);
      expect(window.is24Hour, isFalse);
      expect(window.totalMinutes, 720); // (1440 - 840) + 120 = 600 + 120 = 720 (12 hours)

      // Inside night portion
      expect(window.isIntervalWithin(900, 1000), isTrue);
      expect(window.isIntervalWithin(1300, 1440), isTrue);

      // Inside morning portion
      expect(window.isIntervalWithin(0, 60), isTrue);
      expect(window.isIntervalWithin(60, 120), isTrue);

      // Outside
      expect(window.isIntervalWithin(150, 300), isFalse);
      expect(window.isIntervalWithin(500, 600), isFalse);
      expect(window.isMinuteWithin(500), isFalse);
      expect(window.formattedRange, '02:00 PM – 02:00 AM');
    });

    test('24-hour active window: startMin == endMin', () {
      const window = DayWindow(startMin: 420, endMin: 420);
      expect(window.isNormal, isFalse);
      expect(window.isOvernight, isFalse);
      expect(window.is24Hour, isTrue);
      expect(window.totalMinutes, 1440);

      // All intervals valid
      expect(window.isIntervalWithin(0, 60), isTrue);
      expect(window.isIntervalWithin(700, 800), isTrue);
      expect(window.isIntervalWithin(1300, 1440), isTrue);
      expect(window.isMinuteWithin(200), isTrue);
    });
  });
}
