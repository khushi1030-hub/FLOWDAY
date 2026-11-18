import '../../tasks/domain/entities/task.dart';
import '../../tasks/domain/entities/task_status.dart';

/// Schedule adherence status badge shown on Home progress card per Screen 07.
enum TrackStatus {
  onTrack('• On track'),
  behind('• Behind'),
  allDone('• Completed'),
  empty('• No tasks');

  const TrackStatus(this.displayName);
  final String displayName;
}

/// Type of task presented in the prominent Screen 07 NOW card.
enum NowTaskType {
  inProgress,
  nextUpcoming,
  earliestDelayed,
  none,
}

/// Immutable state model representing calculated metrics for the Home dashboard.
///
/// Counting rules (per Decision 3 & UI_SPEC Screen 07):
/// - total = all tasks scheduled for today
/// - done = tasks with status == 'completed'
/// - remaining = tasks that are not 'completed' and not 'skipped'
///   (includes 'pending', 'incomplete', 'postponed', and 'rescheduled')
/// - skipped tasks count in total, but do NOT count in done or remaining
/// - ring % = (done / total * 100).round(); returns 0 when total == 0
/// - focusMinutes = sum of planned durationMin for completed tasks (Phase 10 will connect to real focus sessions)
class HomeDashboardState {
  const HomeDashboardState({
    required this.dateKey,
    required this.formattedDate,
    required this.greeting,
    required this.userName,
    required this.totalCount,
    required this.doneCount,
    required this.remainingCount,
    required this.focusMinutes,
    required this.progressPercent,
    required this.progressRatio,
    required this.trackStatus,
    required this.nowTask,
    required this.nowTaskType,
    required this.tasks,
  });

  final String dateKey;
  final String formattedDate;
  final String greeting;
  final String userName;
  final int totalCount;
  final int doneCount;
  final int remainingCount;
  final int focusMinutes;
  final int progressPercent;
  final double progressRatio;
  final TrackStatus trackStatus;
  final Task? nowTask;
  final NowTaskType nowTaskType;
  final List<Task> tasks;

  /// Formatted focus time string, e.g. "1h 24m", "45m", or "0m".
  String get formattedFocusTime {
    if (focusMinutes <= 0) return '0m';
    final hours = focusMinutes ~/ 60;
    final mins = focusMinutes % 60;
    if (hours > 0 && mins > 0) {
      return '${hours}h ${mins}m';
    } else if (hours > 0) {
      return '${hours}h';
    } else {
      return '${mins}m';
    }
  }

  /// Evaluates and derives dashboard metrics from today's tasks and the current clock time.
  factory HomeDashboardState.compute({
    required String dateKey,
    required List<Task> tasks,
    required DateTime now,
    required String userName,
  }) {
    // 1. Counting logic per Decision 3
    final total = tasks.length;
    final done = tasks.where((t) => t.isCompleted).length;
    // Remaining = not completed and not skipped
    final remaining = tasks.where((t) => !t.isCompleted && t.status != 'skipped').length;

    // 2. Progress percentage
    final double ratio = total > 0 ? (done / total) : 0.0;
    final int percent = total > 0 ? (ratio * 100).round() : 0;

    // 3. Focus minutes: sum of planned duration of completed tasks
    // (Note per Decision 1: Phase 10 will connect this to real focus sessions)
    final focusMins = tasks
        .where((t) => t.isCompleted)
        .fold<int>(0, (sum, t) => sum + t.durationMin);

    // 4. "On track" badge derivation per Decision 4:
    // On track when no pending task is delayed. Otherwise show Behind.
    // If all actionable tasks are done (remaining == 0 and done > 0), status is allDone.
    final TrackStatus status;
    if (total == 0) {
      status = TrackStatus.empty;
    } else if (remaining == 0 && done > 0) {
      status = TrackStatus.allDone;
    } else {
      final hasDelayed = tasks.any((t) =>
          !t.isCompleted &&
          t.status != 'skipped' &&
          t.runtimeStatus(now) == TaskRuntimeStatus.delayed);
      status = hasDelayed ? TrackStatus.behind : TrackStatus.onTrack;
    }

    // 5. NOW card selection per Decision 5:
    // a. In-progress tasks: if multiple, earliest endMin wins
    final inProgress = tasks
        .where((t) => t.runtimeStatus(now) == TaskRuntimeStatus.inProgress)
        .toList();
    Task? selectedNowTask;
    NowTaskType selectedType = NowTaskType.none;

    if (inProgress.isNotEmpty) {
      inProgress.sort((a, b) {
        final cmp = a.endMin.compareTo(b.endMin);
        if (cmp != 0) return cmp;
        return a.startMin.compareTo(b.startMin);
      });
      selectedNowTask = inProgress.first;
      selectedType = NowTaskType.inProgress;
    } else {
      // b. Next upcoming task: earliest startMin wins
      final upcoming = tasks
          .where((t) => t.runtimeStatus(now) == TaskRuntimeStatus.upcoming)
          .toList();
      if (upcoming.isNotEmpty) {
        upcoming.sort((a, b) => a.startMin.compareTo(b.startMin));
        selectedNowTask = upcoming.first;
        selectedType = NowTaskType.nextUpcoming;
      } else {
        // c. Neither exists but unfinished tasks remain (all delayed)
        final delayedRemaining = tasks
            .where((t) =>
                !t.isCompleted &&
                t.status != 'skipped' &&
                t.runtimeStatus(now) == TaskRuntimeStatus.delayed)
            .toList();
        if (delayedRemaining.isNotEmpty) {
          delayedRemaining.sort((a, b) => a.startMin.compareTo(b.startMin));
          selectedNowTask = delayedRemaining.first;
          selectedType = NowTaskType.earliestDelayed;
        }
      }
    }

    // 6. Greeting determination (hour edges: morning 5-11, afternoon 12-16, evening 17-4)
    final greeting = computeGreeting(now.hour, userName.trim());

    // 7. Formatted date (e.g. "Tuesday, May 14")
    final formattedDate = formatHeaderDate(now);

    return HomeDashboardState(
      dateKey: dateKey,
      formattedDate: formattedDate,
      greeting: greeting,
      userName: userName.trim(),
      totalCount: total,
      doneCount: done,
      remainingCount: remaining,
      focusMinutes: focusMins,
      progressPercent: percent,
      progressRatio: ratio,
      trackStatus: status,
      nowTask: selectedNowTask,
      nowTaskType: selectedType,
      tasks: tasks,
    );
  }

  /// Computes the time-of-day greeting with name and emoji.
  static String computeGreeting(int hour, String name) {
    final cleanName = name.trim();
    final String timeOfDay;
    final String emoji;
    if (hour >= 5 && hour < 12) {
      timeOfDay = 'Good Morning';
      emoji = '☀️';
    } else if (hour >= 12 && hour < 17) {
      timeOfDay = 'Good Afternoon';
      emoji = '🌤️';
    } else {
      timeOfDay = 'Good Evening';
      emoji = '🌙';
    }

    if (cleanName.isNotEmpty) {
      return '$timeOfDay, $cleanName! $emoji';
    } else {
      return '$timeOfDay! $emoji';
    }
  }

  /// Formats date for top header per Screen 07 ("Tuesday, May 14").
  static String formatHeaderDate(DateTime dt) {
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    final weekday = weekdays[dt.weekday - 1];
    final month = months[dt.month - 1];
    return '$weekday, $month ${dt.day}';
  }
}
