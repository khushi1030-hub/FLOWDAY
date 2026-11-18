import 'package:material_ui/material_ui.dart';
import '../../../../core/theme/flow_colors.dart';
import '../../../../core/theme/flow_typography.dart';
import '../../../../core/utils/time_utils.dart';
import '../../../../core/widgets/flow_chips.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/task.dart';
import '../../domain/entities/task_status.dart';

/// Swipeable Task Card for lists (Home, Schedule, and Task Management).
///
/// Rules:
/// - Swipe right (startToEnd) = complete
/// - Swipe left (endToStart) = mark incomplete / adjust
/// - Swipe must NEVER delete (confirmDismiss returns false).
class SwipeableTaskCard extends StatelessWidget {
  const SwipeableTaskCard({
    super.key,
    required this.task,
    this.category,
    this.runtimeStatus,
    this.onTap,
    this.onComplete,
    this.onIncomplete,
  });

  final Task task;
  final Category? category;
  final TaskRuntimeStatus? runtimeStatus;
  final VoidCallback? onTap;
  final ValueChanged<Task>? onComplete;
  final ValueChanged<Task>? onIncomplete;

  @override
  Widget build(BuildContext context) {
    final isDone = task.status == 'completed';
    final isInProgress = runtimeStatus == TaskRuntimeStatus.inProgress;
    final isDelayed = runtimeStatus == TaskRuntimeStatus.delayed;

    // Card border and background color based on status
    final Color cardBg;
    final Color borderColor;
    if (isDone) {
      cardBg = FlowColors.surfaceDark;
      borderColor = FlowColors.successBorder;
    } else if (task.hasConflict) {
      cardBg = FlowColors.surface;
      borderColor = FlowColors.error;
    } else if (isInProgress) {
      cardBg = FlowColors.surfaceElevated;
      borderColor = FlowColors.primary;
    } else {
      cardBg = FlowColors.surface;
      borderColor = FlowColors.surfaceBorder;
    }

    final categoryColor = category != null
        ? Color(category!.color)
        : FlowColors.primaryLight;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Dismissible(
        key: Key('swipe_task_${task.id}'),
        direction: DismissDirection.horizontal,
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.startToEnd) {
            onComplete?.call(task);
          } else if (direction == DismissDirection.endToStart) {
            onIncomplete?.call(task);
          }
          // Never delete the task on swipe!
          return false;
        },
        // Right swipe background: Complete
        background: Container(
          decoration: BoxDecoration(
            color: FlowColors.successContainer,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: FlowColors.successBorder, width: 1.5),
          ),
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle_rounded, color: FlowColors.success, size: 24),
              SizedBox(width: 8),
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
        // Left swipe background: Mark Incomplete / Adjust
        secondaryBackground: Container(
          decoration: BoxDecoration(
            color: FlowColors.warningContainer,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: FlowColors.warningBorder, width: 1.5),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.symmetric(horizontal: 20),
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
              SizedBox(width: 8),
              Icon(Icons.replay_rounded, color: FlowColors.warning, size: 24),
            ],
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor, width: 1),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left: Completion toggle button
                  GestureDetector(
                    onTap: () {
                      if (isDone) {
                        onIncomplete?.call(task);
                      } else {
                        onComplete?.call(task);
                      }
                    },
                    child: Container(
                      width: 28,
                      height: 28,
                      margin: const EdgeInsets.only(right: 12, top: 2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDone ? FlowColors.success : Colors.transparent,
                        border: Border.all(
                          color: isDone ? FlowColors.success : FlowColors.textMuted,
                          width: 2,
                        ),
                      ),
                      child: isDone
                          ? const Icon(Icons.check, size: 18, color: Colors.white)
                          : null,
                    ),
                  ),

                  // Center: Title & metadata
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title row with Fixed icon and Conflict badge
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                task.title,
                                style: FlowTypography.titleMedium.copyWith(
                                  color: isDone
                                      ? FlowColors.textMuted
                                      : FlowColors.textPrimary,
                                  decoration: isDone
                                      ? TextDecoration.lineThrough
                                      : TextDecoration.none,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (task.isFixed) ...[
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.lock_rounded,
                                size: 14,
                                color: FlowColors.textMuted,
                              ),
                            ],
                            if (task.hasConflict) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: FlowColors.errorContainer,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: FlowColors.errorBorder,
                                    width: 1,
                                  ),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.warning_amber_rounded,
                                      size: 12,
                                      color: FlowColors.error,
                                    ),
                                    SizedBox(width: 3),
                                    Text(
                                      'Overlap',
                                      style: TextStyle(
                                        color: FlowColors.error,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),

                        // Time range & Duration
                        Row(
                          children: [
                            const Icon(
                              Icons.schedule_rounded,
                              size: 13,
                              color: FlowColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${TimeUtils.formatMinutesToTime(task.startMin)} - ${TimeUtils.formatMinutesToTime(task.endMin)}',
                              style: FlowTypography.bodyMedium,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '· ${TimeUtils.formatDuration(task.durationMin)}',
                              style: FlowTypography.bodyMedium.copyWith(
                                color: FlowColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Tags: Category, Priority, and Status
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            // Category tag
                            if (category != null)
                              FlowChip(
                                label: category!.name,
                                textColor: categoryColor,
                                borderColor: categoryColor.withValues(alpha: 0.4),
                                backgroundColor: categoryColor.withValues(alpha: 0.15),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              ),

                            // Priority tag
                            if (task.priority == 2)
                              FlowChip.priority(priority: 'High', isSelected: true)
                            else if (task.priority == 1)
                              FlowChip.priority(priority: 'Medium', isSelected: true)
                            else
                              FlowChip.priority(priority: 'Low', isSelected: true),

                            // Runtime status badge (if not pending)
                            if (isDone)
                              FlowChip.status(
                                label: 'Done',
                                color: FlowColors.success,
                              )
                            else if (isInProgress)
                              FlowChip.status(
                                label: 'In progress',
                                color: FlowColors.primaryLight,
                              )
                            else if (isDelayed)
                              FlowChip.status(
                                label: 'Delayed',
                                color: FlowColors.error,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Right: Chevron for tap edit
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: FlowColors.textMuted,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
