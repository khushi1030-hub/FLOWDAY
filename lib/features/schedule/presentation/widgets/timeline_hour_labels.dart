import 'package:material_ui/material_ui.dart';
import '../../../../core/theme/flow_colors.dart';
import '../../../../core/time/day_window.dart';
import '../../domain/services/timeline_layout_calculator.dart';

/// Left-hand column rendering time hour markers (e.g. 07:00, 08:00) alongside horizontal divider guides.
class TimelineHourLabels extends StatelessWidget {
  const TimelineHourLabels({
    super.key,
    required this.dayWindow,
  });

  final DayWindow dayWindow;

  @override
  Widget build(BuildContext context) {
    final markers = TimelineLayoutCalculator.getHourMarkers(dayWindow);
    final totalHeight = TimelineLayoutCalculator.totalCanvasHeight(dayWindow);

    return SizedBox(
      height: totalHeight,
      width: TimelineLayoutCalculator.hourLabelWidth,
      child: Stack(
        children: markers.map((minute) {
          final topY = TimelineLayoutCalculator.minuteToY(minute, dayWindow);
          final hour = (minute ~/ 60) % 24;
          final timeStr = '${hour.toString().padLeft(2, '0')}:00';

          return Positioned(
            top: topY,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 20,
              child: Text(
                timeStr,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: FlowColors.textMuted,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
