import '../../../tasks/domain/entities/task.dart';

/// Activity dot categories displayed on the Screen 21 Calendar matrix.
enum CalendarDotType {
  completed,   // 🟢 Mint green
  upcoming,    // 🟣 Lavender / purple
  rescheduled, // 🟠 Amber / orange
  missed,      // 🔴 Coral / red
}

/// Evaluated summary metrics for a calendar day.
class CalendarDaySummary {
  const CalendarDaySummary({
    required this.dateKey,
    required this.completedCount,
    required this.rescheduledCount,
    required this.missedCount,
    required this.upcomingCount,
    required this.totalTasks,
    required this.dots,
  });

  final String dateKey;
  final int completedCount;
  final int rescheduledCount;
  final int missedCount;
  final int upcomingCount;
  final int totalTasks;
  final Set<CalendarDotType> dots;

  /// Pure computation of day summary from tasks and the reference "today" date key.
  ///
  /// Definitions per Project Decisions:
  /// - Completed: status == 'completed'
  /// - Rescheduled: status == 'rescheduled'
  /// - Missed: task on a past day (dateKey < todayKey) that is NOT completed and NOT skipped
  /// - Upcoming: task on today or future day that is pending/upcoming
  factory CalendarDaySummary.compute({
    required String dateKey,
    required List<Task> tasksForDay,
    required String todayKey,
  }) {
    final isPast = dateKey.compareTo(todayKey) < 0;
    int completed = 0;
    int rescheduled = 0;
    int missed = 0;
    int upcoming = 0;

    for (final task in tasksForDay) {
      if (task.status == 'skipped') continue;

      if (task.isCompleted) {
        completed++;
      } else if (task.status == 'rescheduled') {
        rescheduled++;
      } else if (isPast) {
        // Missed definition: task on a past day that is not completed and not skipped
        missed++;
      } else {
        upcoming++;
      }
    }

    final dots = <CalendarDotType>{};
    if (completed > 0) dots.add(CalendarDotType.completed);
    if (upcoming > 0) dots.add(CalendarDotType.upcoming);
    if (rescheduled > 0) dots.add(CalendarDotType.rescheduled);
    if (missed > 0) dots.add(CalendarDotType.missed);

    return CalendarDaySummary(
      dateKey: dateKey,
      completedCount: completed,
      rescheduledCount: rescheduled,
      missedCount: missed,
      upcomingCount: upcoming,
      totalTasks: tasksForDay.length,
      dots: dots,
    );
  }
}

/// Aggregated monthly metrics displayed on Screen 21 stat tiles.
class CalendarMonthSummary {
  const CalendarMonthSummary({
    required this.year,
    required this.month,
    required this.totalCompleted,
    required this.totalRescheduled,
    required this.totalMissed,
    required this.daySummaries,
  });

  final int year;
  final int month;
  final int totalCompleted;
  final int totalRescheduled;
  final int totalMissed;
  final Map<String, CalendarDaySummary> daySummaries;

  factory CalendarMonthSummary.compute({
    required int year,
    required int month,
    required List<Task> allMonthTasks,
    required String todayKey,
  }) {
    final grouped = <String, List<Task>>{};
    for (final task in allMonthTasks) {
      grouped.putIfAbsent(task.dateKey, () => []).add(task);
    }

    int sumCompleted = 0;
    int sumRescheduled = 0;
    int sumMissed = 0;
    final summaries = <String, CalendarDaySummary>{};

    grouped.forEach((dateKey, tasks) {
      final summary = CalendarDaySummary.compute(
        dateKey: dateKey,
        tasksForDay: tasks,
        todayKey: todayKey,
      );
      summaries[dateKey] = summary;
      sumCompleted += summary.completedCount;
      sumRescheduled += summary.rescheduledCount;
      sumMissed += summary.missedCount;
    });

    return CalendarMonthSummary(
      year: year,
      month: month,
      totalCompleted: sumCompleted,
      totalRescheduled: sumRescheduled,
      totalMissed: sumMissed,
      daySummaries: summaries,
    );
  }
}
