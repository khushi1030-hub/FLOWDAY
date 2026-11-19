import 'package:material_ui/material_ui.dart';
import '../../../../core/theme/flow_colors.dart';
import '../../../../core/theme/flow_radii.dart';
import '../../../../core/theme/flow_spacing.dart';
import '../../../../core/theme/flow_typography.dart';
import '../../../../core/widgets/flow_progress_ring.dart';
import '../../domain/home_dashboard_state.dart';

/// Progress summary card matching Screen 07 with circular ring, status chip, and 3 stat tiles.
class DailyProgressCard extends StatelessWidget {
  const DailyProgressCard({
    super.key,
    required this.state,
  });

  final HomeDashboardState state;

  @override
  Widget build(BuildContext context) {
    // Dynamic status badge styling
    final Color badgeColor;
    final Color badgeBg;
    final Color badgeBorder;
    switch (state.trackStatus) {
      case TrackStatus.onTrack:
        badgeColor = FlowColors.success;
        badgeBg = const Color(0xFF0E2C22);
        badgeBorder = const Color(0xFF1B3D2F);
        break;
      case TrackStatus.behind:
        badgeColor = FlowColors.error;
        badgeBg = FlowColors.errorContainer;
        badgeBorder = FlowColors.errorBorder;
        break;
      case TrackStatus.allDone:
        badgeColor = FlowColors.success;
        badgeBg = const Color(0xFF0E2C22);
        badgeBorder = const Color(0xFF1B3D2F);
        break;
      case TrackStatus.empty:
        badgeColor = FlowColors.textSecondary;
        badgeBg = const Color(0xFF1D1B2B);
        badgeBorder = FlowColors.surfaceBorder;
        break;
    }

    // Dynamic subtitle
    final String subtitle;
    if (state.activeTotal == 0) {
      subtitle = 'Tap + below to start scheduling your day.';
    } else if (state.doneCount == state.activeTotal) {
      subtitle = "All tasks completed! You're flowing great today 🎉";
    } else if (state.trackStatus == TrackStatus.behind) {
      subtitle = "Take a breath. You can adjust and flow smoothly.";
    } else {
      subtitle = "You're flowing nicely — keep it gentle.";
    }

    return Container(
      decoration: BoxDecoration(
        color: FlowColors.surface,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1D1735),
            Color(0xFF161426),
          ],
        ),
        borderRadius: FlowRadii.cardRadius,
        border: Border.all(color: const Color(0xFF262142), width: 1.0),
      ),
      padding: const EdgeInsets.all(FlowSpacing.space18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Ring on left, Text & Badge on right
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 80dp Progress Ring
              FlowProgressRing(
                progress: state.progressRatio,
                size: 80,
                strokeWidth: 8,
                centerText: '${state.progressPercent}%',
                subtitle: 'today',
                color: const Color(0xFF8B7BF7),
                backgroundColor: const Color(0xFF232038),
              ),
              const SizedBox(width: FlowSpacing.space16),

              // Status, Title & Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: FlowSpacing.space10,
                        vertical: FlowSpacing.space4,
                      ),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: badgeBorder, width: 1.0),
                      ),
                      child: Text(
                        state.trackStatus.displayName,
                        style: FlowTypography.labelSmall.copyWith(
                          color: badgeColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(height: FlowSpacing.space8),

                    // Completed headline
                    Text(
                      state.activeTotal > 0
                          ? '${state.doneCount} of ${state.activeTotal} tasks\ncompleted'
                          : 'No tasks scheduled',
                      style: FlowTypography.headlineMedium.copyWith(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: FlowColors.textPrimary,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: FlowSpacing.space4),

                    // Motivational subtitle
                    Text(
                      subtitle,
                      style: FlowTypography.bodyMedium.copyWith(
                        fontSize: 12,
                        color: FlowColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: FlowSpacing.space18),

          // 3 Stat Tiles inside card
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  label: 'DONE',
                  value: '${state.doneCount}',
                  valueColor: FlowColors.success,
                ),
              ),
              const SizedBox(width: FlowSpacing.space8),
              Expanded(
                child: _StatTile(
                  label: 'REMAINING',
                  value: '${state.remainingCount}',
                  valueColor: FlowColors.textPrimary,
                ),
              ),
              const SizedBox(width: FlowSpacing.space8),
              Expanded(
                child: _StatTile(
                  label: 'FOCUS',
                  value: state.formattedFocusTime,
                  valueColor: FlowColors.primaryLight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: FlowSpacing.space8,
        vertical: FlowSpacing.space10,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1A2F),
        borderRadius: FlowRadii.tileRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              label,
              style: FlowTypography.labelSmall.copyWith(
                fontSize: 10,
                color: FlowColors.textMuted,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
              ),
            ),
          ),
          const SizedBox(height: FlowSpacing.space4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: FlowTypography.headlineMedium.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
