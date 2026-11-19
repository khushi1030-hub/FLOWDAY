import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/providers/database_providers.dart';
import '../../../core/theme/flow_colors.dart';
import '../../../core/theme/flow_typography.dart';
import '../../../core/utils/time_utils.dart';
import '../../tasks/domain/entities/task.dart';
import '../../tasks/presentation/widgets/category_selector.dart';
import '../domain/delay_calculator.dart';
import 'widgets/extra_time_bottom_sheet.dart';

enum DelayResolutionChoice {
  addExtraTime,
  rescheduleToday,
  moveToTomorrow,
}

/// Screen 14: Unfinished / Adjust Schedule (`/delay/:taskId`).
///
/// A calm, guilt-free delay triage screen triggered by end-time alarm,
/// left-swipe on task card, or overdue status.
class UnfinishedAdjustScreen extends ConsumerStatefulWidget {
  const UnfinishedAdjustScreen({super.key, required this.taskId});

  final String taskId;

  @override
  ConsumerState<UnfinishedAdjustScreen> createState() => _UnfinishedAdjustScreenState();
}

class _UnfinishedAdjustScreenState extends ConsumerState<UnfinishedAdjustScreen> {
  int _selectedWorkLeftMinutes = 30; // Default 30m
  DelayResolutionChoice _selectedChoice = DelayResolutionChoice.addExtraTime;
  final _calculator = const DelayCalculator();

  String _formatDateForTomorrow(DateTime dt) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${weekdays[dt.weekday - 1]}, ${months[dt.month - 1]} ${dt.day}';
  }

  Future<void> _handleContinue({
    required Task task,
    required List<Task> dayTasks,
    required FreeSlotCandidate? slotToday,
    required FreeSlotCandidate slotTomorrow,
  }) async {
    final taskRepo = ref.read(taskRepositoryProvider);

    switch (_selectedChoice) {
      case DelayResolutionChoice.addExtraTime:
        await ExtraTimeBottomSheet.show(
          context,
          task: task,
          dayTasks: dayTasks,
          initialMinutes: _selectedWorkLeftMinutes,
        );
        break;

      case DelayResolutionChoice.rescheduleToday:
        if (slotToday == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'No free gap fits ${task.title} today. Try moving to tomorrow.',
                style: FlowTypography.bodyMedium.copyWith(color: FlowColors.textPrimary),
              ),
              backgroundColor: FlowColors.surface,
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }

        await taskRepo.rescheduleTask(
          task,
          newDateKey: slotToday.dateKey,
          newStartMin: slotToday.startMin,
          newEndMin: slotToday.endMin,
        );

        if (!mounted) return;
        try {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/home');
          }
        } catch (_) {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Rescheduled ${task.title} to ${TimeUtils.formatTimeRange(slotToday.startMin, slotToday.endMin)}',
              style: FlowTypography.bodyMedium.copyWith(color: FlowColors.textPrimary),
            ),
            backgroundColor: FlowColors.surface,
            behavior: SnackBarBehavior.floating,
          ),
        );
        break;

      case DelayResolutionChoice.moveToTomorrow:
        await taskRepo.rescheduleTask(
          task,
          newDateKey: slotTomorrow.dateKey,
          newStartMin: slotTomorrow.startMin,
          newEndMin: slotTomorrow.endMin,
          carriedFromDateKey: task.dateKey,
        );

        if (!mounted) return;
        try {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/home');
          }
        } catch (_) {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Moved ${task.title} to tomorrow at ${TimeUtils.formatMinutesToTime(slotTomorrow.startMin)}',
              style: FlowTypography.bodyMedium.copyWith(color: FlowColors.textPrimary),
            ),
            backgroundColor: FlowColors.surface,
            behavior: SnackBarBehavior.floating,
          ),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final clock = ref.watch(clockProvider);
    final now = clock.now();
    final currentMin = now.hour * 60 + now.minute;
    const sleepMin = 1380; // 23:00 default
    const wakeMin = 420; // 07:00 default

    final tomorrow = now.add(const Duration(days: 1));
    final tomorrowDateKey =
        '${tomorrow.year}-${tomorrow.month.toString().padLeft(2, '0')}-${tomorrow.day.toString().padLeft(2, '0')}';

    final taskRepo = ref.watch(taskRepositoryProvider);

    return Scaffold(
      backgroundColor: FlowColors.background,
      body: FutureBuilder<Task?>(
        future: taskRepo.getTaskById(widget.taskId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: FlowColors.primary),
            );
          }

          final task = snapshot.data;
          if (task == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Task not found', style: FlowTypography.headlineMedium),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => context.canPop() ? context.pop() : context.go('/home'),
                    child: const Text('Back to Home'),
                  ),
                ],
              ),
            );
          }

          final dayTasksAsync = ref.watch(tasksForDayProvider(task.dateKey));
          final tomorrowTasksAsync = ref.watch(tasksForDayProvider(tomorrowDateKey));

          final dayTasks = dayTasksAsync.value ?? [task];
          final tomorrowTasks = tomorrowTasksAsync.value ?? [];

          // Find candidate slots
          final slotToday = _calculator.findFirstFreeSlotToday(
            task: task,
            dayTasks: dayTasks,
            currentMin: currentMin,
            dayEndMin: sleepMin,
          );

          final slotTomorrow = _calculator.findFirstFreeSlotTomorrow(
            task: task,
            tomorrowDateKey: tomorrowDateKey,
            tomorrowTasks: tomorrowTasks,
            wakeMin: wakeMin,
            sleepMin: sleepMin,
          );

          final catOption = defaultCategoryOptions.firstWhere(
            (c) => c.id == task.categoryId,
            orElse: () => defaultCategoryOptions.first,
          );

          final priorityLabel = task.priority >= 3
              ? 'High priority'
              : (task.priority == 2 ? 'Medium priority' : 'Low priority');

          return SafeArea(
            child: Column(
              children: [
                // 1. Top Navigation Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      InkWell(
                        onTap: () => context.canPop() ? context.pop() : context.go('/home'),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: FlowColors.surface,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_back_rounded,
                            size: 20,
                            color: FlowColors.textPrimary,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () => context.canPop() ? context.pop() : context.go('/home'),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: FlowColors.surface,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            size: 20,
                            color: FlowColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Scrollable Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 2. Hero Section: Glowing Coral Squircle & Hourglass
                        Center(
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: FlowColors.errorContainer,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: FlowColors.error,
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: FlowColors.error.withValues(alpha: 0.25),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.hourglass_top_rounded,
                              size: 30,
                              color: FlowColors.error,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 3. Header Text
                        Text(
                          "No worries!\nLet's adjust your schedule.",
                          textAlign: TextAlign.center,
                          style: FlowTypography.headlineLarge.copyWith(
                            fontWeight: FontWeight.w700,
                            color: FlowColors.textPrimary,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // 4. Task Status Card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: FlowColors.surface,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: FlowColors.surfaceBorder),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Top row: Category icon, Title + Subtitle, Unfinished badge
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: catOption.color.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(catOption.icon, size: 20, color: catOption.color),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          task.title,
                                          style: FlowTypography.titleMedium.copyWith(
                                            color: FlowColors.textPrimary,
                                            fontWeight: FontWeight.w700,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${catOption.name} · $priorityLabel',
                                          style: FlowTypography.bodySmall.copyWith(color: FlowColors.textSecondary),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: FlowColors.errorContainer,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'Unfinished',
                                      style: FlowTypography.labelSmall.copyWith(
                                        color: FlowColors.error,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Two columns: ALLOCATED vs CURRENT TIME
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'ALLOCATED',
                                          style: FlowTypography.labelSmall.copyWith(
                                            color: FlowColors.textMuted,
                                            letterSpacing: 0.6,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          TimeUtils.formatTimeRange(task.startMin, task.endMin),
                                          style: FlowTypography.bodyLarge.copyWith(
                                            color: FlowColors.textPrimary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'CURRENT TIME',
                                          style: FlowTypography.labelSmall.copyWith(
                                            color: FlowColors.textMuted,
                                            letterSpacing: 0.6,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          TimeUtils.formatMinutesToTime(currentMin),
                                          style: FlowTypography.bodyLarge.copyWith(
                                            color: FlowColors.textPrimary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              const Divider(color: FlowColors.surfaceBorder, height: 1),
                              const SizedBox(height: 14),

                              // Sub-question: How much work is left?
                              Text(
                                'How much work is left?',
                                style: FlowTypography.bodySmall.copyWith(
                                  color: FlowColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 10),

                              // Pill selector: 15m, 30m (selected), 45m, 1h+
                              Row(
                                children: [
                                  _WorkLeftPill(
                                    label: '15m',
                                    minutes: 15,
                                    isSelected: _selectedWorkLeftMinutes == 15,
                                    onTap: () => setState(() => _selectedWorkLeftMinutes = 15),
                                  ),
                                  const SizedBox(width: 8),
                                  _WorkLeftPill(
                                    label: '30m',
                                    minutes: 30,
                                    isSelected: _selectedWorkLeftMinutes == 30,
                                    onTap: () => setState(() => _selectedWorkLeftMinutes = 30),
                                  ),
                                  const SizedBox(width: 8),
                                  _WorkLeftPill(
                                    label: '45m',
                                    minutes: 45,
                                    isSelected: _selectedWorkLeftMinutes == 45,
                                    onTap: () => setState(() => _selectedWorkLeftMinutes = 45),
                                  ),
                                  const SizedBox(width: 8),
                                  _WorkLeftPill(
                                    label: '1h+',
                                    minutes: 60,
                                    isSelected: _selectedWorkLeftMinutes == 60,
                                    onTap: () => setState(() => _selectedWorkLeftMinutes = 60),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 22),

                        // 5. Section "CHOOSE WHAT WORKS"
                        Text(
                          'CHOOSE WHAT WORKS',
                          style: FlowTypography.labelSmall.copyWith(
                            color: FlowColors.textMuted,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Option 1: Add Extra Time
                        _ResolutionOptionTile(
                          iconWidget: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: FlowColors.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.add_rounded, color: FlowColors.textPrimary, size: 22),
                          ),
                          title: 'Add Extra Time',
                          subtitle: 'Keep going now · see impact on next tasks',
                          isSelected: _selectedChoice == DelayResolutionChoice.addExtraTime,
                          onTap: () {
                            setState(() => _selectedChoice = DelayResolutionChoice.addExtraTime);
                            ExtraTimeBottomSheet.show(
                              context,
                              task: task,
                              dayTasks: dayTasks,
                              initialMinutes: _selectedWorkLeftMinutes,
                            );
                          },
                        ),
                        const SizedBox(height: 10),

                        // Option 2: Reschedule Later Today
                        _ResolutionOptionTile(
                          iconWidget: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: FlowColors.warningContainer,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.update_rounded, color: FlowColors.warning, size: 22),
                          ),
                          title: 'Reschedule Later Today',
                          subtitle: slotToday != null
                              ? 'Free slot found · ${TimeUtils.formatTimeRange(slotToday.startMin, slotToday.endMin)}'
                              : 'No free slot today · try tomorrow',
                          isSelected: _selectedChoice == DelayResolutionChoice.rescheduleToday,
                          onTap: () {
                            setState(() => _selectedChoice = DelayResolutionChoice.rescheduleToday);
                          },
                        ),
                        const SizedBox(height: 10),

                        // Option 3: Move to Tomorrow
                        _ResolutionOptionTile(
                          iconWidget: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: FlowColors.primaryContainer,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.nightlight_round, color: FlowColors.primaryLight, size: 20),
                          ),
                          title: 'Move to Tomorrow',
                          subtitle:
                              '${_formatDateForTomorrow(tomorrow)} · ${TimeUtils.formatMinutesToTime(slotTomorrow.startMin)} (first slot)',
                          isSelected: _selectedChoice == DelayResolutionChoice.moveToTomorrow,
                          onTap: () {
                            setState(() => _selectedChoice = DelayResolutionChoice.moveToTomorrow);
                          },
                        ),
                        const SizedBox(height: 20),

                        // 6. Guilt-Free Encouragement Card
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: FlowColors.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: FlowColors.surfaceBorder),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.favorite_rounded,
                                color: FlowColors.error,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  "One unfinished task doesn't have to ruin your entire day. Progress counts, too.",
                                  style: FlowTypography.bodySmall.copyWith(
                                    color: FlowColors.textSecondary,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),

                // 7. Bottom White Pill Button "Continue"
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () => _handleContinue(
                        task: task,
                        dayTasks: dayTasks,
                        slotToday: slotToday,
                        slotTomorrow: slotTomorrow,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FlowColors.textPrimary,
                        foregroundColor: FlowColors.background,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26),
                        ),
                      ),
                      child: Text(
                        'Continue',
                        style: FlowTypography.bodyLarge.copyWith(
                          color: FlowColors.background,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _WorkLeftPill extends StatelessWidget {
  const _WorkLeftPill({
    required this.label,
    required this.minutes,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final int minutes;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? FlowColors.textPrimary : FlowColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? FlowColors.textPrimary : FlowColors.surfaceBorder,
            ),
          ),
          child: Text(
            label,
            style: FlowTypography.bodyMedium.copyWith(
              color: isSelected ? FlowColors.background : FlowColors.textPrimary,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _ResolutionOptionTile extends StatelessWidget {
  const _ResolutionOptionTile({
    required this.iconWidget,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  final Widget iconWidget;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: FlowColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? FlowColors.primary : FlowColors.surfaceBorder,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            iconWidget,
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: FlowTypography.titleMedium.copyWith(
                      color: FlowColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: FlowTypography.bodySmall.copyWith(
                      color: FlowColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              color: FlowColors.textSecondary,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
