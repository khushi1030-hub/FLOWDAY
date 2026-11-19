import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/database_providers.dart';
import '../../../../core/time/day_window.dart';
import '../../../tasks/domain/entities/task.dart';
import '../../../tasks/domain/entities/task_status.dart';
import '../../domain/entities/free_time_gap.dart';
import '../../domain/entities/calendar_day_summary.dart';
import '../../domain/services/free_gap_calculator.dart';

/// Filter selection for the Schedule timeline.
enum ScheduleFilter {
  all,
  completed,
  pending,
  overdue,
}

/// Manages the currently selected schedule date and handles midnight rollover.
///
/// Per Phase 6 rules:
/// - If the user is currently viewing "today", a midnight rollover automatically updates
///   the selected date to the new "today".
/// - If the user is viewing another day (past or future), they remain on that day.
class SelectedScheduleDateNotifier extends Notifier<String> {
  String? _lastKnownToday;

  @override
  String build() {
    final clock = ref.watch(clockProvider);
    final currentToday = clock.currentDateKey;

    ref.listen<AsyncValue<DateTime>>(minuteTickProvider, (previous, next) {
      final newDate = next.value;
      if (newDate == null) return;
      final newTodayKey =
          '${newDate.year.toString().padLeft(4, '0')}-${newDate.month.toString().padLeft(2, '0')}-${newDate.day.toString().padLeft(2, '0')}';

      if (_lastKnownToday != null && newTodayKey != _lastKnownToday) {
        // Midnight rollover occurred
        if (state == _lastKnownToday) {
          state = newTodayKey;
        }
      }
      _lastKnownToday = newTodayKey;
    });

    _lastKnownToday ??= currentToday;
    return currentToday;
  }

  void selectDate(String dateKey) {
    state = dateKey;
  }
}

final selectedScheduleDateProvider =
    NotifierProvider<SelectedScheduleDateNotifier, String>(
  SelectedScheduleDateNotifier.new,
);

/// Active filter chip state manager.
class ScheduleFilterNotifier extends Notifier<ScheduleFilter> {
  @override
  ScheduleFilter build() => ScheduleFilter.all;

  void setFilter(ScheduleFilter filter) {
    state = filter;
  }
}

final scheduleFilterProvider =
    NotifierProvider<ScheduleFilterNotifier, ScheduleFilter>(
  ScheduleFilterNotifier.new,
);

/// Aggregated presentation state for the daily schedule timeline.
class ScheduleTimelineData {
  const ScheduleTimelineData({
    required this.selectedDateKey,
    required this.allDayTasks,
    required this.visibleTasks,
    required this.completedCount,
    required this.pendingCount,
    required this.overdueCount,
    required this.freeGaps,
    required this.dayWindow,
    required this.isToday,
    required this.currentTimeMin,
    required this.filter,
  });

  final String selectedDateKey;
  final List<Task> allDayTasks;
  final List<Task> visibleTasks;
  final int completedCount;
  final int pendingCount;
  final int overdueCount;
  final List<FreeTimeGap> freeGaps;
  final DayWindow dayWindow;
  final bool isToday;
  final int currentTimeMin;
  final ScheduleFilter filter;
}

/// Timeline data provider reacting to selected date, tasks, settings, clock tick, and active filter.
final scheduleTimelineDataProvider = Provider.autoDispose<AsyncValue<ScheduleTimelineData>>((ref) {
  final selectedDate = ref.watch(selectedScheduleDateProvider);
  final clock = ref.watch(clockProvider);
  final tickAsync = ref.watch(minuteTickProvider);
  final now = tickAsync.value ?? clock.now();
  final todayKey = clock.currentDateKey;
  final isToday = selectedDate == todayKey;
  final currentTimeMin = now.hour * 60 + now.minute;

  final settingsAsync = ref.watch(settingsStateProvider);
  final tasksAsync = ref.watch(tasksForDayProvider(selectedDate));
  final filter = ref.watch(scheduleFilterProvider);

  if (tasksAsync.hasError) {
    return AsyncError(tasksAsync.error!, tasksAsync.stackTrace ?? StackTrace.current);
  }
  if (settingsAsync.hasError) {
    return AsyncError(settingsAsync.error!, settingsAsync.stackTrace ?? StackTrace.current);
  }

  if ((tasksAsync.isLoading && !tasksAsync.hasValue) ||
      (settingsAsync.isLoading && !settingsAsync.hasValue)) {
    return const AsyncLoading();
  }

  final allTasks = tasksAsync.value ?? [];
  final settings = settingsAsync.value;
  final wakeMin = settings?.wakeMin ?? 420; // 07:00 default
  final sleepMin = settings?.sleepMin ?? 1380; // 23:00 default
  final dayWindow = DayWindow(startMin: wakeMin, endMin: sleepMin);

  // Compute status counts using pure TaskStatusResolver
  int completedCount = 0;
  int pendingCount = 0;
  int overdueCount = 0;

  for (final task in allTasks) {
    if (task.status == 'skipped') continue;
    final runtimeStatus = TaskStatusResolver.resolve(
      status: task.status,
      dateKey: selectedDate,
      startMin: task.startMin,
      endMin: task.endMin,
      now: now,
    );
    if (runtimeStatus == TaskRuntimeStatus.completed) {
      completedCount++;
    } else if (runtimeStatus == TaskRuntimeStatus.delayed) {
      overdueCount++;
    } else if (runtimeStatus == TaskRuntimeStatus.upcoming ||
        runtimeStatus == TaskRuntimeStatus.inProgress) {
      pendingCount++;
    }
  }

  // Calculate free gaps for the entire day (from non-skipped tasks)
  final gaps = FreeGapCalculator.calculateGaps(
    tasks: allTasks,
    dayWindow: dayWindow,
  );

  // Filter visible tasks according to filter chip
  final visibleTasks = allTasks.where((task) {
    if (filter == ScheduleFilter.all) return true;
    final runtimeStatus = TaskStatusResolver.resolve(
      status: task.status,
      dateKey: selectedDate,
      startMin: task.startMin,
      endMin: task.endMin,
      now: now,
    );
    switch (filter) {
      case ScheduleFilter.completed:
        return runtimeStatus == TaskRuntimeStatus.completed;
      case ScheduleFilter.pending:
        return runtimeStatus == TaskRuntimeStatus.upcoming ||
            runtimeStatus == TaskRuntimeStatus.inProgress;
      case ScheduleFilter.overdue:
        return runtimeStatus == TaskRuntimeStatus.delayed;
      case ScheduleFilter.all:
        return true;
    }
  }).toList();

  return AsyncData(ScheduleTimelineData(
    selectedDateKey: selectedDate,
    allDayTasks: allTasks,
    visibleTasks: visibleTasks,
    completedCount: completedCount,
    pendingCount: pendingCount,
    overdueCount: overdueCount,
    freeGaps: gaps,
    dayWindow: dayWindow,
    isToday: isToday,
    currentTimeMin: currentTimeMin,
    filter: filter,
  ));
});

/// Month currently navigated to on Screen 21 (Calendar). Defaults to first of current month.
class CalendarMonthNotifier extends Notifier<DateTime> {
  @override
  DateTime build() {
    final clock = ref.watch(clockProvider);
    final now = clock.now();
    return DateTime(now.year, now.month, 1);
  }

  void setMonth(DateTime month) {
    state = DateTime(month.year, month.month, 1);
  }

  void previousMonth() {
    state = DateTime(state.year, state.month - 1, 1);
  }

  void nextMonth() {
    state = DateTime(state.year, state.month + 1, 1);
  }
}

final calendarMonthProvider =
    NotifierProvider<CalendarMonthNotifier, DateTime>(CalendarMonthNotifier.new);

/// Selected date on Screen 21 (Calendar). Defaults to today's dateKey.
class CalendarSelectedDateNotifier extends Notifier<String> {
  @override
  String build() {
    final clock = ref.watch(clockProvider);
    return clock.currentDateKey;
  }

  void selectDate(String dateKey) {
    state = dateKey;
  }
}

final calendarSelectedDateProvider =
    NotifierProvider<CalendarSelectedDateNotifier, String>(
  CalendarSelectedDateNotifier.new,
);

/// Monthly aggregated summary for Screen 21 stat tiles and dot matrix.
final calendarMonthSummaryProvider = Provider.autoDispose<AsyncValue<CalendarMonthSummary>>((ref) {
  final currentMonth = ref.watch(calendarMonthProvider);
  final clock = ref.watch(clockProvider);
  final todayKey = clock.currentDateKey;
  final allTasksAsync = ref.watch(allTasksProvider);

  if (allTasksAsync.hasError) {
    return AsyncError(allTasksAsync.error!, allTasksAsync.stackTrace ?? StackTrace.current);
  }
  if (allTasksAsync.isLoading && !allTasksAsync.hasValue) {
    return const AsyncLoading();
  }

  final allTasks = allTasksAsync.value ?? [];
  final prefix =
      '${currentMonth.year.toString().padLeft(4, '0')}-${currentMonth.month.toString().padLeft(2, '0')}-';
  final monthTasks = allTasks.where((t) => t.dateKey.startsWith(prefix)).toList();

  final summary = CalendarMonthSummary.compute(
    year: currentMonth.year,
    month: currentMonth.month,
    allMonthTasks: monthTasks,
    todayKey: todayKey,
  );

  return AsyncData(summary);
});
