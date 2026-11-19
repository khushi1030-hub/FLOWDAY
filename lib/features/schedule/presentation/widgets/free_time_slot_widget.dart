import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import '../../../../core/theme/flow_colors.dart';
import '../../../../core/theme/flow_radii.dart';
import '../../../../core/theme/flow_spacing.dart';
import '../../../../core/utils/time_utils.dart';
import '../../domain/entities/free_time_gap.dart';

/// Dashed outline free-time insertion slot matching Screen 08.
///
/// Tapping navigates to `/task/new?date=...&start=...&end=...` with prefilled time bounds.
class FreeTimeSlotWidget extends StatelessWidget {
  const FreeTimeSlotWidget({
    super.key,
    required this.gap,
    required this.dateKey,
    required this.height,
  });

  final FreeTimeGap gap;
  final String dateKey;
  final double height;

  @override
  Widget build(BuildContext context) {
    final startTime = TimeUtils.formatMinutesToTime(gap.startMin);
    final endTime = TimeUtils.formatMinutesToTime(gap.endMin);

    return InkWell(
      onTap: () {
        context.push('/task/new?date=$dateKey&start=${gap.startMin}&end=${gap.endMin}');
      },
      borderRadius: BorderRadius.circular(FlowRadii.squircle),
      child: Container(
        height: height.clamp(36.0, 300.0),
        padding: const EdgeInsets.symmetric(
          horizontal: FlowSpacing.space12,
          vertical: FlowSpacing.space4,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF141224).withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(FlowRadii.squircle),
          border: Border.all(
            color: const Color(0xFF2A2640),
            width: 1,
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.add_circle_outline_rounded,
              size: 16,
              color: FlowColors.primaryLight,
            ),
            const SizedBox(width: FlowSpacing.space8),
            Expanded(
              child: Text(
                '+ Free · $startTime – $endTime (${gap.durationMin}m)',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: FlowColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
