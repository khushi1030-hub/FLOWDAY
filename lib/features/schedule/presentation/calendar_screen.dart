import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import '../../../../core/providers/database_providers.dart';
import '../../../../core/theme/flow_colors.dart';
import '../../../../core/theme/flow_radii.dart';
import '../../../../core/theme/flow_spacing.dart';
import '../../../../core/theme/flow_typography.dart';
import '../../../../core/utils/time_utils.dart';
import '../../tasks/domain/entities/task.dart';
import '../../tasks/domain/entities/task_status.dart';
import '../domain/entities/calendar_day_summary.dart';
import 'providers/schedule_providers.dart';

/// Screen 21: Calendar View Screen.
///
/// Deliverables:
/// - Month Matrix Card with month navigation (<, >), weekday headers (Sun..Sat), date cells.
/// - Activity dots (🟢 Completed, 🟣 Upcoming, 🟠 Rescheduled, 🔴 Missed) and legend.
/// - 3 Monthly stat tiles (Completed, Rescheduled, Missed).
/// - Selected Day section with "Open day ->" action.
/// - Month only segmented control (Week toggle hidden per Requirement 8).
class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMonth = ref.watch(calendarMonthProvider);
    final selectedDateKey = ref.watch(calendarSelectedDateProvider);
    final monthSummaryAsync = ref.watch(calendarMonthSummaryProvider);
    final selectedDayTasksAsync = ref.watch(tasksForDayProvider(selectedDateKey));
    final clock = ref.watch(clockProvider);
    final todayKey = clock.currentDateKey;

    final monthTitle = DateFormat('MMMM yyyy').format(currentMonth);

    // Format selected date header
    final selectedParts = selectedDateKey.split('-');
    final selectedDateTime = DateTime(
      int.tryParse(selectedParts[0]) ?? 2026,
      int.tryParse(selectedParts[1]) ?? 1,
      int.tryParse(selectedParts[2]) ?? 1,
    );
    final isSelectedToday = selectedDateKey == todayKey;
    final relativePrefix = isSelectedToday ? 'Today · ' : '';
    final selectedHeaderStr = '$relativePrefix${DateFormat('EEE, MMM d').format(selectedDateTime)}';

    return Scaffold(
      backgroundColor: FlowColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            FlowSpacing.space16,
            FlowSpacing.space12,
            FlowSpacing.space16,
            FlowSpacing.space32,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar: Back button, Title "Calendar", Month pill
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFF1D1B2B),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(FlowRadii.squircle),
                        side: const BorderSide(color: FlowColors.surfaceBorder, width: 1),
                      ),
                    ),
                    onPressed: () => context.pop(),
                  ),
                  const SizedBox(width: FlowSpacing.space12),
                  const Expanded(
                    child: Text(
                      'Calendar',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: FlowColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: FlowSpacing.space8),
                  // Month-only pill (Week toggle hidden per Requirement 8)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: FlowSpacing.space14,
                      vertical: FlowSpacing.space6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(FlowRadii.pill),
                    ),
                    child: const Text(
                      'Month',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0B0B14),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: FlowSpacing.space16),

              // Month Matrix Card
              Container(
                padding: const EdgeInsets.all(FlowSpacing.space16),
                decoration: BoxDecoration(
                  color: const Color(0xFF161426),
                  borderRadius: BorderRadius.circular(FlowRadii.card),
                  border: Border.all(color: FlowColors.surfaceBorder, width: 1),
                ),
                child: Column(
                  children: [
                    // Header: Prev Month, Title, Next Month
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left_rounded, color: Colors.white),
                          onPressed: () {
                            ref.read(calendarMonthProvider.notifier).previousMonth();
                          },
                        ),
                        Expanded(
                          child: Center(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                monthTitle,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right_rounded, color: Colors.white),
                          onPressed: () {
                            ref.read(calendarMonthProvider.notifier).nextMonth();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: FlowSpacing.space10),

                    // Weekday headers: Sun..Sat
                    const Row(
                      children: [
                        _WeekdayHeader(label: 'Sun'),
                        _WeekdayHeader(label: 'Mon'),
                        _WeekdayHeader(label: 'Tue'),
                        _WeekdayHeader(label: 'Wed'),
                        _WeekdayHeader(label: 'Thu'),
                        _WeekdayHeader(label: 'Fri'),
                        _WeekdayHeader(label: 'Sat'),
                      ],
                    ),
                    const SizedBox(height: FlowSpacing.space8),
                    const Divider(color: Color(0xFF262244), height: 1),
                    const SizedBox(height: FlowSpacing.space8),

                    // Calendar Grid
                    monthSummaryAsync.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: CircularProgressIndicator(color: FlowColors.primary)),
                      ),
                      error: (err, _) => Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text('Error: $err', style: const TextStyle(color: FlowColors.error)),
                      ),
                      data: (monthSummary) => _buildMonthGrid(
                        context: context,
                        ref: ref,
                        month: currentMonth,
                        selectedDateKey: selectedDateKey,
                        monthSummary: monthSummary,
                      ),
                    ),

                    const SizedBox(height: FlowSpacing.space12),
                    const Divider(color: Color(0xFF262244), height: 1),
                    const SizedBox(height: FlowSpacing.space10),

                    // Dot Legend
                    const Wrap(
                      spacing: 10,
                      runSpacing: 4,
                      alignment: WrapAlignment.center,
                      children: [
                        _DotLegendItem(color: FlowColors.success, label: 'Completed'),
                        _DotLegendItem(color: FlowColors.catStudy, label: 'Upcoming'),
                        _DotLegendItem(color: FlowColors.warning, label: 'Rescheduled'),
                        _DotLegendItem(color: FlowColors.error, label: 'Missed'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: FlowSpacing.space16),

              // 3 Monthly Stat Tiles
              monthSummaryAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
                data: (summary) => Row(
                  children: [
                    Expanded(
                      child: _buildStatTile(
                        count: summary.totalCompleted.toString(),
                        label: 'Completed',
                        color: FlowColors.success,
                      ),
                    ),
                    const SizedBox(width: FlowSpacing.space10),
                    Expanded(
                      child: _buildStatTile(
                        count: summary.totalRescheduled.toString(),
                        label: 'Rescheduled',
                        color: FlowColors.warning,
                      ),
                    ),
                    const SizedBox(width: FlowSpacing.space10),
                    Expanded(
                      child: _buildStatTile(
                        count: summary.totalMissed.toString(),
                        label: 'Missed',
                        color: FlowColors.error,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: FlowSpacing.space20),

              // Selected Day Section Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      selectedHeaderStr,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: FlowSpacing.space8),
                  GestureDetector(
                    onTap: () {
                      ref.read(selectedScheduleDateProvider.notifier).selectDate(selectedDateKey);
                      context.pop();
                    },
                    child: const Text(
                      'Open day ->',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: FlowColors.primaryLight,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: FlowSpacing.space12),

              // Selected Day Task List
              selectedDayTasksAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(color: FlowColors.primary),
                  ),
                ),
                error: (err, _) => Text('Error loading tasks: $err', style: const TextStyle(color: FlowColors.error)),
                data: (tasks) {
                  if (tasks.isEmpty) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(FlowSpacing.space20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF161424),
                        borderRadius: BorderRadius.circular(FlowRadii.squircle),
                        border: Border.all(color: FlowColors.surfaceBorder, width: 1),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'No tasks scheduled for this day',
                        style: TextStyle(
                          fontSize: 13,
                          color: FlowColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: tasks.map((task) {
                      return _buildAgendaTaskCard(context, ref, task, selectedDateKey);
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMonthGrid({
    required BuildContext context,
    required WidgetRef ref,
    required DateTime month,
    required String selectedDateKey,
    required CalendarMonthSummary monthSummary,
  }) {
    final firstDayOfMonth = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    // Weekday: Sun=0 (in our layout), Mon=1, ..., Sat=6
    final firstWeekday = firstDayOfMonth.weekday % 7;

    final totalCells = ((firstWeekday + daysInMonth + 6) ~/ 7) * 7;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: totalCells,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 0.8,
      ),
      itemBuilder: (context, index) {
        final dayNumber = index - firstWeekday + 1;
        if (dayNumber < 1 || dayNumber > daysInMonth) {
          return const SizedBox.shrink();
        }

        final cellDateKey =
            '${month.year.toString().padLeft(4, '0')}-${month.month.toString().padLeft(2, '0')}-${dayNumber.toString().padLeft(2, '0')}';
        final isSelected = cellDateKey == selectedDateKey;
        final daySummary = monthSummary.daySummaries[cellDateKey];

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            ref.read(calendarSelectedDateProvider.notifier).selectDate(cellDateKey);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: isSelected ? FlowColors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(FlowRadii.squircle - 4),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: FlowColors.primary.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    dayNumber.toString(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected ? Colors.white : FlowColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                // Activity dots
                if (daySummary != null && daySummary.dots.isNotEmpty)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: daySummary.dots.take(3).map((dotType) {
                      final dotColor = switch (dotType) {
                        CalendarDotType.completed => FlowColors.success,
                        CalendarDotType.upcoming => isSelected ? Colors.white : FlowColors.catStudy,
                        CalendarDotType.rescheduled => FlowColors.warning,
                        CalendarDotType.missed => FlowColors.error,
                      };
                      return Container(
                        width: 4,
                        height: 4,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(
                          color: dotColor,
                          shape: BoxShape.circle,
                        ),
                      );
                    }).toList(),
                  )
                else
                  const SizedBox(height: 4),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatTile({
    required String count,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(FlowSpacing.space12),
      decoration: BoxDecoration(
        color: const Color(0xFF161424),
        borderRadius: BorderRadius.circular(FlowRadii.tile),
        border: Border.all(color: FlowColors.surfaceBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            count,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: FlowSpacing.space2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: FlowColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgendaTaskCard(
    BuildContext context,
    WidgetRef ref,
    Task task,
    String dateKey,
  ) {
    final now = ref.read(clockProvider).now();
    final runtimeStatus = TaskStatusResolver.resolve(
      status: task.status,
      dateKey: dateKey,
      startMin: task.startMin,
      endMin: task.endMin,
      now: now,
    );

    final statusLabel = switch (runtimeStatus) {
      TaskRuntimeStatus.completed => 'Completed',
      TaskRuntimeStatus.inProgress => 'In progress',
      TaskRuntimeStatus.delayed => 'Missed',
      TaskRuntimeStatus.rescheduled => 'Rescheduled',
      TaskRuntimeStatus.upcoming => 'Upcoming',
      TaskRuntimeStatus.incomplete => 'Incomplete',
      TaskRuntimeStatus.postponed => 'Postponed',
      TaskRuntimeStatus.skipped => 'Skipped',
    };

    final statusColor = switch (runtimeStatus) {
      TaskRuntimeStatus.completed => FlowColors.success,
      TaskRuntimeStatus.inProgress => FlowColors.primaryLight,
      TaskRuntimeStatus.delayed => FlowColors.error,
      TaskRuntimeStatus.rescheduled => FlowColors.warning,
      TaskRuntimeStatus.upcoming => FlowColors.info,
      TaskRuntimeStatus.incomplete => FlowColors.error,
      TaskRuntimeStatus.postponed => FlowColors.warning,
      TaskRuntimeStatus.skipped => FlowColors.textMuted,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: FlowSpacing.space8),
      padding: const EdgeInsets.all(FlowSpacing.space12),
      decoration: BoxDecoration(
        color: const Color(0xFF161424),
        borderRadius: BorderRadius.circular(FlowRadii.squircle),
        border: Border.all(color: FlowColors.surfaceBorder, width: 1),
      ),
      child: Row(
        children: [
          // Time
          Text(
            TimeUtils.formatMinutesToTime(task.startMin),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: FlowColors.textSecondary,
            ),
          ),
          const SizedBox(width: FlowSpacing.space12),
          // Title
          Expanded(
            child: Text(
              task.title,
              style: FlowTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: task.isCompleted ? FlowColors.textMuted : Colors.white,
                decoration: task.isCompleted ? TextDecoration.lineThrough : null,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: FlowSpacing.space8),
          // Status chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(FlowRadii.pill),
              border: Border.all(color: statusColor.withValues(alpha: 0.4), width: 1),
            ),
            child: Text(
              statusLabel,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekdayHeader extends StatelessWidget {
  const _WeekdayHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: FlowColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}

class _DotLegendItem extends StatelessWidget {
  const _DotLegendItem({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: FlowColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
