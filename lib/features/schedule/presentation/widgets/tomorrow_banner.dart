import 'package:material_ui/material_ui.dart';
import '../../../../core/theme/flow_colors.dart';
import '../../../../core/theme/flow_radii.dart';
import '../../../../core/theme/flow_spacing.dart';

/// Static hint banner displayed when viewing Tomorrow's schedule.
///
/// Per Phase 6 requirements: static hint only; no confirmation logic (Phase 11).
class TomorrowBanner extends StatelessWidget {
  const TomorrowBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: FlowSpacing.space16,
        vertical: FlowSpacing.space8,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: FlowSpacing.space14,
        vertical: FlowSpacing.space10,
      ),
      decoration: BoxDecoration(
        color: FlowColors.warningContainer,
        borderRadius: BorderRadius.circular(FlowRadii.squircle),
        border: Border.all(color: FlowColors.warningBorder, width: 1),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: FlowColors.warning,
          ),
          SizedBox(width: FlowSpacing.space10),
          Expanded(
            child: Text(
              "Tomorrow's Schedule · Unconfirmed (Review at 09:30 PM)",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: FlowColors.warning,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
