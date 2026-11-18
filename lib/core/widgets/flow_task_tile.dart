import 'package:material_ui/material_ui.dart';
import '../theme/flow_colors.dart';
import '../theme/flow_typography.dart';
import 'flow_chips.dart';

/// Reusable timeline Task Tile matching Screens 07, 08, 18, 21.
class FlowTaskTile extends StatelessWidget {
  const FlowTaskTile({
    super.key,
    required this.title,
    required this.timeRange,
    this.duration,
    this.category,
    this.categoryIcon = Icons.code,
    this.categoryColor = FlowColors.catStudy,
    this.priority,
    this.statusBadge,
    this.isCompleted = false,
    this.isCurrent = false,
    this.isBreak = false,
    this.isFixed = false,
    this.onTap,
  });

  final String title;
  final String timeRange;
  final String? duration;
  final String? category;
  final IconData categoryIcon;
  final Color categoryColor;
  final String? priority;
  final Widget? statusBadge;
  final bool isCompleted;
  final bool isCurrent;
  final bool isBreak;
  final bool isFixed;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    Color cardBg = FlowColors.surface;
    Color borderColor = FlowColors.surfaceBorder;

    if (isCompleted) {
      cardBg = const Color(0xFF14181F);
      borderColor = FlowColors.successBorder;
    } else if (isCurrent) {
      cardBg = const Color(0xFF1F1C36);
      borderColor = FlowColors.primary;
    } else if (isBreak) {
      cardBg = const Color(0xFF231C18);
      borderColor = FlowColors.warningBorder;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Row(
          children: [
            // Category / Kind Squircle Icon
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: categoryColor.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Icon(
                categoryIcon,
                size: 20,
                color: categoryColor,
              ),
            ),
            const SizedBox(width: 12),

            // Title & Subtitle details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: FlowTypography.titleMedium.copyWith(
                            color: isCompleted ? FlowColors.textSecondary : FlowColors.textPrimary,
                            decoration: isCompleted ? TextDecoration.lineThrough : null,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isFixed) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.lock_rounded, size: 14, color: FlowColors.textMuted),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        timeRange,
                        style: FlowTypography.bodyMedium.copyWith(
                          fontSize: 12,
                          color: FlowColors.textSecondary,
                        ),
                      ),
                      if (duration != null) ...[
                        Text(
                          ' · $duration',
                          style: FlowTypography.bodyMedium.copyWith(
                            fontSize: 12,
                            color: FlowColors.textMuted,
                          ),
                        ),
                      ],
                      if (category != null) ...[
                        Text(
                          ' · $category',
                          style: FlowTypography.bodyMedium.copyWith(
                            fontSize: 12,
                            color: FlowColors.textMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (priority != null) ...[
                    const SizedBox(height: 6),
                    FlowChip.priority(priority: priority!),
                  ],
                ],
              ),
            ),

            // Right Status Badge or Checkmark
            if (statusBadge != null) ...[
              const SizedBox(width: 8),
              statusBadge!,
            ] else if (isCompleted) ...[
              const SizedBox(width: 8),
              const Icon(Icons.check_circle_rounded, color: FlowColors.success, size: 22),
            ],
          ],
        ),
      ),
    );
  }
}
