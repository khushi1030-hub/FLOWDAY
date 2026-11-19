import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/database_providers.dart';
import '../../../../core/theme/flow_colors.dart';
import '../../../../core/theme/flow_radii.dart';
import '../../../../core/theme/flow_spacing.dart';
import '../../../../core/utils/time_utils.dart';

/// Static hint banner displayed when viewing Tomorrow's schedule.
///
/// Per Phase 6 requirements: static hint only; no confirmation logic (Phase 11).
/// Reads the user's configured nightly review reminder time from settings.
class TomorrowBanner extends ConsumerWidget {
  const TomorrowBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsStateProvider);
    final reviewMin = settingsAsync.value?.nightlyReviewMin ??
        AppConstants.defaultNightlyReviewMin;
    final formattedTime = TimeUtils.formatMinutesToTime(reviewMin);

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
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: FlowColors.warning,
          ),
          const SizedBox(width: FlowSpacing.space10),
          Expanded(
            child: Text(
              "Tomorrow's Schedule · Unconfirmed (Review at $formattedTime)",
              style: const TextStyle(
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
