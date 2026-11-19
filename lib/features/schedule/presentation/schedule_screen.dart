import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import '../../../../core/providers/database_providers.dart';
import '../../../../core/theme/flow_colors.dart';
import '../../../../core/theme/flow_radii.dart';
import '../../../../core/theme/flow_spacing.dart';
import '../../../../core/utils/time_utils.dart';
import '../../../../core/widgets/flow_empty_state.dart';
import '../../tasks/domain/entities/task.dart';
import '../../tasks/domain/entities/task_status.dart';
import '../domain/entities/free_time_gap.dart';
import 'providers/schedule_providers.dart';
import 'widgets/current_time_marker.dart';
import 'widgets/free_time_slot_widget.dart';
import 'widgets/schedule_filter_bar.dart';
import 'widgets/schedule_task_card.dart';
import 'widgets/tomorrow_banner.dart';
import 'widgets/week_day_strip.dart';

/// Item in the unified chronological timeline list.
sealed class TimelineItem {
  const TimelineItem({required this.startMin});
  final int startMin;
}

class TaskTimelineItem extends TimelineItem {
  TaskTimelineItem({required this.task, required this.runtimeStatus})
      : super(startMin: task.startMin);
  final Task task;
  final TaskRuntimeStatus runtimeStatus;
}

class FreeGapTimelineItem extends TimelineItem {
  FreeGapTimelineItem({required this.gap}) : super(startMin: gap.startMin);
  final FreeTimeGap gap;
}

class CurrentTimeTimelineItem extends TimelineItem {
  CurrentTimeTimelineItem({required int minute}) : super(startMin: minute);
}

/// Screen 08: Daily Schedule Screen.
///
/// Deliverables:
/// - Timeline, time labels, task cards (completed/current/upcoming/delayed/rescheduled/fixed styles).
/// - Current-time line (Clock-based, per-minute tick) and midnight rollover.
/// - Free-time gaps with quick-add navigation.
/// - Day switcher (Today, Tomorrow, Calendar) and WeekDayStrip.
/// - Offline-first, reactive updates shared with Home dashboard.
class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  @override
  Widget build(BuildContext context) {
    final timelineAsync = ref.watch(scheduleTimelineDataProvider);
    final selectedDateKey = ref.watch(selectedScheduleDateProvider);
    final clock = ref.watch(clockProvider);
    final todayKey = clock.currentDateKey;

    final parts = selectedDateKey.split('-');
    final selectedDate = DateTime(
      int.tryParse(parts[0]) ?? 2026,
      int.tryParse(parts[1]) ?? 1,
      int.tryParse(parts[2]) ?? 1,
    );

    // Month and Year string for top bar (e.g. "May 2024")
    final monthYearStr = DateFormat('MMMM yyyy').format(selectedDate);

    // Tomorrow's dateKey
    final tomorrowDate = clock.now().add(const Duration(days: 1));
    final tomorrowKey =
        '${tomorrowDate.year.toString().padLeft(4, '0')}-${tomorrowDate.month.toString().padLeft(2, '0')}-${tomorrowDate.day.toString().padLeft(2, '0')}';
    final isTomorrow = selectedDateKey == tomorrowKey;

    return Scaffold(
      backgroundColor: FlowColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar: Month/Year header, Title, and Calendar button
            Padding(
              padding: const EdgeInsets.fromLTRB(
                FlowSpacing.space16,
                FlowSpacing.space12,
                FlowSpacing.space16,
                FlowSpacing.space4,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          monthYearStr,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: FlowColors.textSecondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: FlowSpacing.space2),
                        const Text(
                          'Schedule',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: FlowColors.textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Calendar button (navigates to Screen 21 Calendar)
                  IconButton(
                    icon: const Icon(Icons.calendar_month_rounded, color: FlowColors.primaryLight),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFF1D1B2B),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(FlowRadii.squircle),
                        side: const BorderSide(color: FlowColors.surfaceBorder, width: 1),
                      ),
                    ),
                    onPressed: () {
                      context.push('/schedule/calendar');
                    },
                  ),
                ],
              ),
            ),

            // Tab Bar: Segmented control: "Today", "Tomorrow", "Calendar"
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: FlowSpacing.space16,
                vertical: FlowSpacing.space6,
              ),
              child: Container(
                padding: const EdgeInsets.all(FlowSpacing.space4),
                decoration: BoxDecoration(
                  color: const Color(0xFF161424),
                  borderRadius: BorderRadius.circular(FlowRadii.squircle),
                  border: Border.all(color: FlowColors.surfaceBorder, width: 1),
                ),
                child: Row(
                  children: [
                    _buildSegmentButton(
                      title: 'Today',
                      isSelected: selectedDateKey == todayKey,
                      onTap: () {
                        ref.read(selectedScheduleDateProvider.notifier).selectDate(todayKey);
                      },
                    ),
                    _buildSegmentButton(
                      title: 'Tomorrow',
                      isSelected: isTomorrow,
                      onTap: () {
                        ref.read(selectedScheduleDateProvider.notifier).selectDate(tomorrowKey);
                      },
                    ),
                    _buildSegmentButton(
                      title: 'Calendar',
                      isSelected: false,
                      onTap: () {
                        context.push('/schedule/calendar');
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Week Day Strip
            const WeekDayStrip(),

            // Timeline Content
            Expanded(
              child: timelineAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: FlowColors.primary),
                ),
                error: (error, _) => Center(
                  child: Text(
                    'Failed to load schedule: $error',
                    style: const TextStyle(color: FlowColors.error),
                  ),
                ),
                data: (data) {
                  return Column(
                    children: [
                      // Filter bar
                      ScheduleFilterBar(
                        completedCount: data.completedCount,
                        pendingCount: data.pendingCount,
                        overdueCount: data.overdueCount,
                        activeFilter: data.filter,
                      ),

                      // Static Tomorrow banner hint
                      if (isTomorrow) const TomorrowBanner(),

                      // Scrollable Timeline
                      Expanded(
                        child: _buildTimelineList(context, data),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.push('/task/new?date=$selectedDateKey');
        },
        backgroundColor: FlowColors.primary,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(FlowRadii.squircle),
        ),
        child: const Icon(Icons.add_rounded, size: 28, color: Colors.white),
      ),
    );
  }

  Widget _buildSegmentButton({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: FlowSpacing.space8, horizontal: 2),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(FlowRadii.squircle - 4),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? const Color(0xFF0B0B14) : FlowColors.textSecondary,
              ),
              maxLines: 1,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineList(BuildContext context, ScheduleTimelineData data) {
    if (data.visibleTasks.isEmpty && data.freeGaps.isEmpty) {
      return FlowEmptyState(
        title: 'No tasks scheduled',
        description: 'You have no tasks scheduled for this day. Tap + to add one!',
        buttonLabel: '+ Add Task',
        onButtonPressed: () {
          context.push('/task/new?date=${data.selectedDateKey}');
        },
      );
    }

    // Build unified chronological timeline items
    final items = <TimelineItem>[];

    for (final task in data.visibleTasks) {
      final runtimeStatus = TaskStatusResolver.resolve(
        status: task.status,
        dateKey: data.selectedDateKey,
        startMin: task.startMin,
        endMin: task.endMin,
        now: ref.read(clockProvider).now(),
      );
      items.add(TaskTimelineItem(task: task, runtimeStatus: runtimeStatus));
    }

    // Include free-time gaps only when no filter is restricting visible tasks
    if (data.filter == ScheduleFilter.all) {
      for (final gap in data.freeGaps) {
        items.add(FreeGapTimelineItem(gap: gap));
      }
    }

    // Include current-time line if viewing today
    if (data.isToday && data.dayWindow.isMinuteWithin(data.currentTimeMin)) {
      items.add(CurrentTimeTimelineItem(minute: data.currentTimeMin));
    }

    // Sort items chronologically
    items.sort((a, b) => a.startMin.compareTo(b.startMin));

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        FlowSpacing.space16,
        FlowSpacing.space8,
        FlowSpacing.space16,
        80.0,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];

        if (item is CurrentTimeTimelineItem) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: FlowSpacing.space8),
            child: SizedBox(
              height: 24,
              child: Stack(
                children: [
                  CurrentTimeMarker(
                    currentTimeMin: data.currentTimeMin,
                    dayWindow: data.dayWindow,
                  ),
                ],
              ),
            ),
          );
        }

        final timeStr = TimeUtils.formatMinutesToTime(item.startMin);

        return Padding(
          padding: const EdgeInsets.only(bottom: FlowSpacing.space10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left time node & label
              SizedBox(
                width: 62,
                child: Padding(
                  padding: const EdgeInsets.only(top: FlowSpacing.space12),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: item is TaskTimelineItem && item.task.isCompleted
                              ? FlowColors.success
                              : FlowColors.primaryLight,
                        ),
                      ),
                      const SizedBox(width: FlowSpacing.space6),
                      Expanded(
                        child: Text(
                          timeStr,
                          style: const TextStyle(
                            fontSize: 11,
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
              ),

              // Right: Card content
              Expanded(
                child: switch (item) {
                  TaskTimelineItem(:final task, :final runtimeStatus) => ScheduleTaskCard(
                      task: task,
                      runtimeStatus: runtimeStatus,
                      currentTimeMin: data.currentTimeMin,
                      onTap: () {
                        context.push('/task/${task.id}/edit');
                      },
                      onComplete: (t) async {
                        final nowMs = ref.read(clockProvider).now().millisecondsSinceEpoch;
                        await ref.read(taskRepositoryProvider).markCompleted(t.id, nowMs);
                      },
                      onIncomplete: (t) async {
                        await ref.read(taskRepositoryProvider).markIncomplete(t.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Adjust schedule coming soon (Phase 8)'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                    ),
                  FreeGapTimelineItem(:final gap) => FreeTimeSlotWidget(
                      gap: gap,
                      dateKey: data.selectedDateKey,
                      height: 48,
                    ),
                  CurrentTimeTimelineItem() => const SizedBox.shrink(),
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
