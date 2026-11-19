import 'package:flutter_test/flutter_test.dart';
import 'package:flow_day/core/time/day_window.dart';
import 'package:flow_day/features/schedule/domain/services/timeline_layout_calculator.dart';

void main() {
  group('TimelineLayoutCalculator Tests', () {
    const normalWindow = DayWindow(startMin: 420, endMin: 1380); // 07:00 to 23:00 (960 min)

    test('pxPerMinute constant is exactly 1.2', () {
      expect(TimelineLayoutCalculator.pxPerMinute, 1.2);
    });

    test('Normal window: Y offsets match minute projections', () {
      // 07:00 (420) is top (0 dp)
      expect(TimelineLayoutCalculator.minuteToY(420, normalWindow), 0.0);
      // 08:00 (480) is 60 * 1.2 = 72.0 dp
      expect(TimelineLayoutCalculator.minuteToY(480, normalWindow), 72.0);
      // 09:30 (570) is 150 * 1.2 = 180.0 dp
      expect(TimelineLayoutCalculator.minuteToY(570, normalWindow), 180.0);
      // Duration height
      expect(TimelineLayoutCalculator.durationToHeight(60), 72.0);
      expect(TimelineLayoutCalculator.durationToHeight(30), 36.0);
      // Total canvas height
      expect(TimelineLayoutCalculator.totalCanvasHeight(normalWindow), 960 * 1.2);
    });

    test('Overnight window: continuous offset across midnight', () {
      // 20:00 (1200) to 04:00 (240) -> total 480 min
      const overnightWindow = DayWindow(startMin: 1200, endMin: 240);
      // 20:00 is top (0 dp)
      expect(TimelineLayoutCalculator.minuteToY(1200, overnightWindow), 0.0);
      // 23:00 (1380) is 180 * 1.2 = 216.0 dp
      expect(TimelineLayoutCalculator.minuteToY(1380, overnightWindow), 216.0);
      // 00:00 (0) is 240 * 1.2 = 288.0 dp
      expect(TimelineLayoutCalculator.minuteToY(0, overnightWindow), 288.0);
      // 02:00 (120) is 360 * 1.2 = 432.0 dp
      expect(TimelineLayoutCalculator.minuteToY(120, overnightWindow), 432.0);
    });

    test('Hour markers generated within window', () {
      final markers = TimelineLayoutCalculator.getHourMarkers(normalWindow);
      expect(markers.first, 420); // 7:00
      expect(markers.contains(480), isTrue); // 8:00
      expect(markers.last, 1380); // 23:00
    });
  });
}
