import 'package:material_ui/material_ui.dart';
import '../../../../core/theme/flow_colors.dart';
import '../../../../core/theme/flow_radii.dart';
import '../../../../core/theme/flow_spacing.dart';
import '../../../../core/theme/flow_typography.dart';
import '../../../../core/utils/time_utils.dart';
import '../../../tasks/domain/entities/category.dart';
import '../../../tasks/domain/entities/task.dart';
import '../../../tasks/domain/entities/task_status.dart';

/// Timeline-styled task card tailored for Screen 08 (Daily Schedule).
///
/// Features:
/// - Distinct visual themes for Completed, In Progress (NOW), Upcoming, Delayed (Overdue), Fixed, and Break.
/// - Dismissible gestures: Swipe right to complete, swipe left to mark incomplete. Never deletes.
/// - Overdue card displays "Reschedule" button showing "Rescheduling isn't available yet" SnackBar.
/// - No drag handles or reorder gestures per Decision D16 / Phase 6 requirements.
class ScheduleTaskCard extends StatelessWidget {
  const ScheduleTaskCard({
    super.key,
    required this.task,
    required this.runtimeStatus,
    this.category,
    this.currentTimeMin,
    this.onTap,
    this.onComplete,
    this.onIncomplete,
  });

  final Task task;
  final TaskRuntimeStatus runtimeStatus;
  final Category? category;
  final int? currentTimeMin;
  final VoidCallback? onTap;
  final ValueChanged<Task>? onComplete;
  final ValueChanged<Task>? onIncomplete;

  @override
  Widget build(BuildContext context) {
    final isDone = runtimeStatus == TaskRuntimeStatus.completed || task.status == 'completed';
    final isInProgress = runtimeStatus == TaskRuntimeStatus.inProgress;
    final isDelayed = runtimeStatus == TaskRuntimeStatus.delayed;
    final isBreak = task.isBreak || task.title.toLowerCase() == 'break';

    // Background and border styling
    final Color cardBg;
    final Color borderColor;
    if (isInProgress) {
      cardBg = FlowColors.primary;
      borderColor = FlowColors.primaryLight;
    } else if (isDelayed) {
      cardBg = const Color(0xFF2B161B);
      borderColor = const Color(0xFF4A2027);
    } else if (isDone) {
      cardBg = const Color(0xFF14181F);
      borderColor = const Color(0xFF1B2D26);
    } else if (isBreak) {
      cardBg = const Color(0xFF2A1D1A);
      borderColor = const Color(0xFF4A2F22);
    } else if (task.isFixed) {
      cardBg = const Color(0xFF181A22);
      borderColor = const Color(0xFF282B38);
    } else {
      cardBg = FlowColors.surface;
      borderColor = FlowColors.surfaceBorder;
    }

    final textColor = isInProgress ? Colors.white : (isDone ? FlowColors.textMuted : FlowColors.textPrimary);
    final subtextColor = isInProgress ? Colors.white.withValues(alpha: 0.85) : FlowColors.textSecondary;

    // Progress for in-progress task
    double progress = 0.0;
    int elapsedMin = 0;
    int remainingMin = 0;
    if (isInProgress && currentTimeMin != null) {
      elapsedMin = (currentTimeMin! - task.startMin).clamp(0, task.durationMin);
      remainingMin = (task.endMin - currentTimeMin!).clamp(0, task.durationMin);
      progress = task.durationMin > 0 ? (elapsedMin / task.durationMin).clamp(0.0, 1.0) : 0.0;
    }

    return Dismissible(
      key: Key('schedule_swipe_${task.id}'),
      direction: DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          onComplete?.call(task);
        } else if (direction == DismissDirection.endToStart) {
          onIncomplete?.call(task);
        }
        return false; // Swipe must NEVER delete
      },
      background: Container(
        decoration: BoxDecoration(
          color: FlowColors.successContainer,
          borderRadius: BorderRadius.circular(FlowRadii.squircle),
          border: Border.all(color: FlowColors.successBorder, width: 1.5),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: FlowSpacing.space20),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_rounded, color: FlowColors.success, size: 24),
            SizedBox(width: FlowSpacing.space8),
            Text(
              'Complete',
              style: TextStyle(
                color: FlowColors.success,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
      secondaryBackground: Container(
        decoration: BoxDecoration(
          color: FlowColors.warningContainer,
          borderRadius: BorderRadius.circular(FlowRadii.squircle),
          border: Border.all(color: FlowColors.warningBorder, width: 1.5),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: FlowSpacing.space20),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Incomplete',
              style: TextStyle(
                color: FlowColors.warning,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            SizedBox(width: FlowSpacing.space8),
            Icon(Icons.replay_rounded, color: FlowColors.warning, size: 24),
          ],
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(FlowRadii.squircle),
          child: Container(
            padding: const EdgeInsets.all(FlowSpacing.space14),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(FlowRadii.squircle),
              border: Border.all(color: borderColor, width: 1.0),
              boxShadow: isInProgress
                  ? [
                      BoxShadow(
                        color: FlowColors.primary.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top row: NOW badge or Delayed warning or Completion check
                Row(
                  children: [
                    if (isInProgress) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: FlowSpacing.space8,
                          vertical: FlowSpacing.space2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(FlowRadii.pill),
                        ),
                        child: const Text(
                          '• NOW',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: FlowSpacing.space8),
                    ] else if (isDelayed) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: FlowSpacing.space6,
                          vertical: FlowSpacing.space2,
                        ),
                        decoration: BoxDecoration(
                          color: FlowColors.error.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(FlowRadii.pill),
                        ),
                        child: const Text(
                          '⚠ Overdue',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: FlowColors.error,
                          ),
                        ),
                      ),
                      const SizedBox(width: FlowSpacing.space8),
                    ] else if (isDone) ...[
                      const Icon(
                        Icons.check_circle_rounded,
                        size: 16,
                        color: FlowColors.success,
                      ),
                      const SizedBox(width: FlowSpacing.space6),
                    ],

                    Expanded(
                      child: Text(
                        task.title,
                        style: FlowTypography.titleMedium.copyWith(
                          color: textColor,
                          fontWeight: FontWeight.w700,
                          decoration: isDone ? TextDecoration.lineThrough : null,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    if (task.isFixed) ...[
                      const SizedBox(width: FlowSpacing.space4),
                      Icon(
                        Icons.lock_rounded,
                        size: 14,
                        color: isInProgress ? Colors.white70 : FlowColors.textMuted,
                      ),
                    ],
                    if (isBreak) ...[
                      const SizedBox(width: FlowSpacing.space4),
                      Icon(
                        Icons.coffee_rounded,
                        size: 14,
                        color: isInProgress ? Colors.white70 : FlowColors.warning,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: FlowSpacing.space6),

                // Subtitle Row: Time range · Duration · Category
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${TimeUtils.formatMinutesToTime(task.startMin)} – ${TimeUtils.formatMinutesToTime(task.endMin)} · ${task.durationMin}m'
                        '${category != null ? ' · ${category!.name}' : ''}',
                        style: TextStyle(
                          fontSize: 12,
                          color: subtextColor,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isDelayed) ...[
                      const SizedBox(width: FlowSpacing.space8),
                      // Coral Reschedule pill button
                      GestureDetector(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Rescheduling isn't available yet"),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: FlowSpacing.space10,
                            vertical: FlowSpacing.space4,
                          ),
                          decoration: BoxDecoration(
                            color: FlowColors.error,
                            borderRadius: BorderRadius.circular(FlowRadii.pill),
                          ),
                          child: const Text(
                            'Reschedule',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),

                // In-progress linear progress bar
                if (isInProgress) ...[
                  const SizedBox(height: FlowSpacing.space8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${elapsedMin}m in',
                        style: const TextStyle(fontSize: 10, color: Colors.white70),
                      ),
                      Text(
                        '${remainingMin}m left',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: FlowSpacing.space4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 4,
                      backgroundColor: Colors.white.withValues(alpha: 0.25),
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
