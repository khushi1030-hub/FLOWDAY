import 'package:flow_day/features/tasks/domain/entities/task.dart';

/// Strategy applied by a rescheduling proposal.
enum ProposalStrategy {
  /// Plan A: Shift affected flexible tasks forward into available gaps.
  shiftFlexible,

  /// Plan B: Place high priority tasks first, move lower priority to later/evening.
  priorityFirst,

  /// Plan C: Postpone trigger task or carry lowest-priority task to tomorrow.
  postponeTomorrow,

  /// Plan D: Keep original schedule, flag trigger task as unfinished/skipped.
  keepOriginalSkip,

  /// Screen 19 Option 1: Move flexible tasks to open free gaps (Best Fit).
  moveConflictFlexible,

  /// Screen 19 Option 2: Reschedule tasks before/after conflicting fixed event.
  rescheduleConflict,

  /// Screen 19 Option 3: Shorten flexible task durations to fit (Decision D2).
  shortenConflictFlexible,

  /// Screen 19 Option 4: Move conflicting flexible tasks to another day.
  moveConflictToAnotherDay,

  /// Screen 19 Footer: Keep overlapping schedule flagged with has_conflict = 1 (Decision D3).
  keepOverlap,
}

/// Represents an individual task move within a proposal.
class TaskMove {
  const TaskMove({
    required this.taskId,
    required this.taskTitle,
    required this.oldDateKey,
    required this.oldStartMin,
    required this.oldEndMin,
    required this.newDateKey,
    required this.newStartMin,
    required this.newEndMin,
    this.reason,
    this.isShortened = false,
  });

  final String taskId;
  final String taskTitle;
  final String oldDateKey;
  final int oldStartMin;
  final int oldEndMin;
  final String newDateKey;
  final int newStartMin;
  final int newEndMin;
  final String? reason;
  final bool isShortened;

  int get oldDurationMin => oldEndMin - oldStartMin;
  int get newDurationMin => newEndMin - newStartMin;
  int get shiftMinutes => newStartMin - oldStartMin;
  bool get isDifferentDate => oldDateKey != newDateKey;
  bool get isShifted =>
      oldStartMin != newStartMin || oldEndMin != newEndMin || isDifferentDate || isShortened;

  TaskMove copyWith({
    String? taskId,
    String? taskTitle,
    String? oldDateKey,
    int? oldStartMin,
    int? oldEndMin,
    String? newDateKey,
    int? newStartMin,
    int? newEndMin,
    String? reason,
    bool? isShortened,
  }) {
    return TaskMove(
      taskId: taskId ?? this.taskId,
      taskTitle: taskTitle ?? this.taskTitle,
      oldDateKey: oldDateKey ?? this.oldDateKey,
      oldStartMin: oldStartMin ?? this.oldStartMin,
      oldEndMin: oldEndMin ?? this.oldEndMin,
      newDateKey: newDateKey ?? this.newDateKey,
      newStartMin: newStartMin ?? this.newStartMin,
      newEndMin: newEndMin ?? this.newEndMin,
      reason: reason ?? this.reason,
      isShortened: isShortened ?? this.isShortened,
    );
  }
}

/// Represents an item carried over to another day.
class CarryOverItem {
  const CarryOverItem({
    required this.taskId,
    required this.taskTitle,
    required this.targetDateKey,
    required this.startMin,
    required this.endMin,
  });

  final String taskId;
  final String taskTitle;
  final String targetDateKey;
  final int startMin;
  final int endMin;
}

/// Represents a concrete, selectable rescheduling proposal (Plan A, B, C, D).
class RescheduleProposal {
  const RescheduleProposal({
    required this.id,
    required this.strategy,
    required this.title,
    required this.subtitle,
    this.badgeText,
    this.isRecommended = false,
    required this.moves,
    this.carryOvers = const [],
    required this.resultingDayTasks,
    required this.impactSummary,
    this.isValid = true,
    this.invalidReason,
  });

  final String id; // 'A', 'B', 'C', 'D'
  final ProposalStrategy strategy;
  final String title;
  final String subtitle;
  final String? badgeText; // 'RECOMMENDED', 'BEST FIT'
  final bool isRecommended;
  final List<TaskMove> moves;
  final List<CarryOverItem> carryOvers;
  final List<Task> resultingDayTasks;
  final String impactSummary;
  final bool isValid;
  final String? invalidReason;

  bool get hasCarryOver => carryOvers.isNotEmpty;

  /// Returns true if this proposal has moves or carryovers to apply.
  bool get hasChanges => moves.any((m) => m.isShifted) || carryOvers.isNotEmpty;

  RescheduleProposal copyWith({
    String? id,
    ProposalStrategy? strategy,
    String? title,
    String? subtitle,
    String? badgeText,
    bool? isRecommended,
    List<TaskMove>? moves,
    List<CarryOverItem>? carryOvers,
    List<Task>? resultingDayTasks,
    String? impactSummary,
    bool? isValid,
    String? invalidReason,
  }) {
    return RescheduleProposal(
      id: id ?? this.id,
      strategy: strategy ?? this.strategy,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      badgeText: badgeText,
      isRecommended: isRecommended ?? this.isRecommended,
      moves: moves ?? this.moves,
      carryOvers: carryOvers ?? this.carryOvers,
      resultingDayTasks: resultingDayTasks ?? this.resultingDayTasks,
      impactSummary: impactSummary ?? this.impactSummary,
      isValid: isValid ?? this.isValid,
      invalidReason: invalidReason ?? this.invalidReason,
    );
  }

  /// Creates a fallback proposal when no valid schedule can be found.
  factory RescheduleProposal.noValidSchedule({
    required String id,
    required String reason,
    List<Task> existingTasks = const [],
  }) {
    return RescheduleProposal(
      id: id,
      strategy: ProposalStrategy.keepOriginalSkip,
      title: 'No Valid Schedule Found',
      subtitle: reason,
      badgeText: null,
      isRecommended: false,
      moves: const [],
      resultingDayTasks: existingTasks,
      impactSummary: reason,
      isValid: false,
      invalidReason: reason,
    );
  }
}
