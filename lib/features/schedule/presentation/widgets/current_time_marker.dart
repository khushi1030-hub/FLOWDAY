import 'package:material_ui/material_ui.dart';
import '../../../../core/theme/flow_radii.dart';
import '../../../../core/theme/flow_spacing.dart';
import '../../../../core/time/day_window.dart';
import '../../domain/services/timeline_layout_calculator.dart';

/// Current-time indicator marker cutting across the schedule timeline.
///
/// Matches Screen 08:
/// - Pink/coral pill with formatted current time (e.g. "09:24").
/// - Horizontal indicator line extending across the cards canvas.
class CurrentTimeMarker extends StatelessWidget {
  const CurrentTimeMarker({
    super.key,
    required this.currentTimeMin,
    required this.dayWindow,
  });

  final int currentTimeMin;
  final DayWindow dayWindow;

  @override
  Widget build(BuildContext context) {
    if (!dayWindow.isMinuteWithin(currentTimeMin)) {
      return const SizedBox.shrink();
    }

    final topY = TimelineLayoutCalculator.minuteToY(currentTimeMin, dayWindow);
    final hours = (currentTimeMin ~/ 60) % 24;
    final mins = currentTimeMin % 60;
    final timeStr =
        '${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}';

    const markerColor = Color(0xFFF43F5E); // Pink/coral indicator

    return Positioned(
      top: topY - 10, // Center the 20dp pill vertically on the minute line
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: FlowSpacing.space6,
                vertical: FlowSpacing.space2,
              ),
              decoration: BoxDecoration(
                color: markerColor,
                borderRadius: BorderRadius.circular(FlowRadii.pill),
                boxShadow: [
                  BoxShadow(
                    color: markerColor.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                timeStr,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: FlowSpacing.space4),
            Expanded(
              child: Container(
                height: 2,
                decoration: BoxDecoration(
                  color: markerColor.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
