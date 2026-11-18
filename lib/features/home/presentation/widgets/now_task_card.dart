import 'package:material_ui/material_ui.dart';
import '../../../../core/theme/flow_colors.dart';
import '../../../../core/theme/flow_radii.dart';
import '../../../../core/theme/flow_spacing.dart';
import '../../../../core/theme/flow_typography.dart';
import '../../../../core/utils/time_utils.dart';
import '../../../tasks/domain/entities/task.dart';
import '../../../tasks/presentation/widgets/category_selector.dart';
import '../../domain/home_dashboard_state.dart';

/// Screen 07 NOW card with white surface, live progress bar, focus action, and mark done.
class NowTaskCard extends StatelessWidget {
  const NowTaskCard({
    super.key,
    required this.task,
    required this.nowType,
    required this.currentMinutes,
    required this.onFocusTap,
    required this.onMarkDoneTap,
  });

  final Task task;
  final NowTaskType nowType;
  final int currentMinutes;
  final VoidCallback onFocusTap;
  final VoidCallback onMarkDoneTap;

  @override
  Widget build(BuildContext context) {
    final cat = defaultCategoryOptions.firstWhere(
      (c) => c.id == task.categoryId,
      orElse: () => defaultCategoryOptions.first,
    );

    // Header badge
    final String tagLabel;
    final Color tagColor;
    switch (nowType) {
      case NowTaskType.inProgress:
        tagLabel = '• NOW';
        tagColor = const Color(0xFF6366F1);
        break;
      case NowTaskType.nextUpcoming:
        tagLabel = '• NEXT UP';
        tagColor = FlowColors.success;
        break;
      case NowTaskType.earliestDelayed:
        tagLabel = '• ATTENTION';
        tagColor = FlowColors.error;
        break;
      case NowTaskType.none:
        tagLabel = '';
        tagColor = FlowColors.textMuted;
        break;
    }

    // Priority styling
    final String priorityLabel;
    final Color priorityBg;
    final Color priorityText;
    switch (task.priority) {
      case 2:
        priorityLabel = 'High';
        priorityBg = const Color(0xFFFEE2E2);
        priorityText = FlowColors.error;
        break;
      case 1:
        priorityLabel = 'Medium';
        priorityBg = const Color(0xFFFEF3C7);
        priorityText = const Color(0xFFD97706);
        break;
      default:
        priorityLabel = 'Low';
        priorityBg = const Color(0xFFDBEAFE);
        priorityText = const Color(0xFF2563EB);
        break;
    }

    // Progress calculations for inProgress
    final isInProgress = nowType == NowTaskType.inProgress;
    final int duration = task.durationMin > 0 ? task.durationMin : 1;
    final int elapsed = (currentMinutes - task.startMin).clamp(0, duration);
    final int remaining = (task.endMin - currentMinutes).clamp(0, duration);
    final double progressRatio = (elapsed / duration).clamp(0.0, 1.0);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: FlowRadii.cardRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(FlowSpacing.space18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Tag badge on left, Priority on right
          Row(
            children: [
              Text(
                tagLabel,
                style: FlowTypography.labelSmall.copyWith(
                  color: tagColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  letterSpacing: 0.8,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: FlowSpacing.space8,
                  vertical: FlowSpacing.space4,
                ),
                decoration: BoxDecoration(
                  color: priorityBg,
                  borderRadius: BorderRadius.circular(FlowRadii.badge),
                ),
                child: Text(
                  priorityLabel,
                  style: TextStyle(
                    color: priorityText,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: FlowSpacing.space12),

          // Title Row: Dark squircle icon + Title + Metadata
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFF181628),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Icon(cat.icon, color: cat.color, size: 20),
              ),
              const SizedBox(width: FlowSpacing.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: const TextStyle(
                        color: Color(0xFF0B0B14),
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: FlowSpacing.space2),
                    Text(
                      '${TimeUtils.formatTimeRange(task.startMin, task.endMin)} · ${task.durationMin}m · ${cat.name}',
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Progress Row (Live elapsed / remaining bar)
          if (isInProgress) ...[
            const SizedBox(height: FlowSpacing.space16),
            Row(
              children: [
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '$elapsed min in',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF4B5563),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: FlowSpacing.space8),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      '$remaining min left',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0B0B14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: FlowSpacing.space6),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: SizedBox(
                height: 6,
                child: LinearProgressIndicator(
                  value: progressRatio,
                  backgroundColor: const Color(0xFFE5E7EB),
                  valueColor: const AlwaysStoppedAnimation<Color>(FlowColors.primary),
                ),
              ),
            ),
          ],
          const SizedBox(height: FlowSpacing.space16),

          // Actions Row: "Focus mode" & "Mark done"
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: ElevatedButton.icon(
                    onPressed: onFocusTap,
                    icon: const Icon(Icons.headphones_rounded, size: 16, color: Colors.white),
                    label: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Focus mode',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0B0B14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(21),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: FlowSpacing.space8),
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: ElevatedButton.icon(
                    onPressed: onMarkDoneTap,
                    icon: const Icon(Icons.check_rounded, size: 18, color: Color(0xFF1F2937)),
                    label: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Mark done',
                        style: TextStyle(
                          color: Color(0xFF1F2937),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF3F4F6),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(21),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
