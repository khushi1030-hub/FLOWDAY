/// Stored task statuses persisted in SQLite.
enum TaskStoredStatus {
  pending('pending'),
  completed('completed'),
  incomplete('incomplete'),
  rescheduled('rescheduled'),
  postponed('postponed'),
  skipped('skipped');

  const TaskStoredStatus(this.value);
  final String value;

  static TaskStoredStatus fromString(String val) {
    return TaskStoredStatus.values.firstWhere(
      (e) => e.value == val,
      orElse: () => TaskStoredStatus.pending,
    );
  }
}

/// Runtime statuses derived at read time from stored status, task times, and clock.
enum TaskRuntimeStatus {
  upcoming('Upcoming'),
  inProgress('In Progress'),
  delayed('Delayed'), // Also referred to as Overdue / Missed
  completed('Completed'),
  incomplete('Incomplete'),
  rescheduled('Rescheduled'),
  postponed('Postponed'),
  skipped('Skipped');

  const TaskRuntimeStatus(this.displayName);
  final String displayName;
}

/// Pure function to resolve dynamic task runtime status without DB or Flutter dependencies.
class TaskStatusResolver {
  const TaskStatusResolver._();

  /// Resolves the runtime status given stored status, schedule day, time bounds, and the current time.
  static TaskRuntimeStatus resolve({
    required String status,
    required String dateKey,
    required int startMin,
    required int endMin,
    required DateTime now,
  }) {
    final stored = TaskStoredStatus.fromString(status);

    // Stored final statuses take precedence
    switch (stored) {
      case TaskStoredStatus.completed:
        return TaskRuntimeStatus.completed;
      case TaskStoredStatus.incomplete:
        return TaskRuntimeStatus.incomplete;
      case TaskStoredStatus.postponed:
        return TaskRuntimeStatus.postponed;
      case TaskStoredStatus.skipped:
        return TaskRuntimeStatus.skipped;
      case TaskStoredStatus.rescheduled:
        return TaskRuntimeStatus.rescheduled;
      case TaskStoredStatus.pending:
        break;
    }

    // Dynamic resolution for pending tasks
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    final nowDateKey = '$y-$m-$d';

    if (dateKey.compareTo(nowDateKey) < 0) {
      // Past day and still pending -> Delayed / Overdue
      return TaskRuntimeStatus.delayed;
    } else if (dateKey.compareTo(nowDateKey) > 0) {
      // Future day -> Upcoming
      return TaskRuntimeStatus.upcoming;
    } else {
      // Today: inspect current time minutes
      final currentMinutes = now.hour * 60 + now.minute;
      if (currentMinutes < startMin) {
        return TaskRuntimeStatus.upcoming;
      } else if (currentMinutes < endMin) {
        return TaskRuntimeStatus.inProgress;
      } else {
        return TaskRuntimeStatus.delayed;
      }
    }
  }
}
