import 'reschedule_change.dart';

/// Domain entity representing a transactionally applied rescheduling operation.
class RescheduleBatch {
  const RescheduleBatch({
    required this.id,
    required this.reason, // 'delay' | 'extra_time' | 'conflict' | 'carryover'
    this.triggerTaskId,
    this.proposalLabel,
    required this.createdAt,
    this.undoneAt,
    this.changes = const [],
  });

  final String id;
  final String reason;
  final String? triggerTaskId;
  final String? proposalLabel;
  final int createdAt; // epoch milliseconds UTC
  final int? undoneAt; // epoch milliseconds UTC, non-null once undone
  final List<RescheduleChange> changes;

  bool get isUndone => undoneAt != null;

  RescheduleBatch copyWith({
    String? id,
    String? reason,
    String? triggerTaskId,
    String? proposalLabel,
    int? createdAt,
    int? undoneAt,
    List<RescheduleChange>? changes,
  }) {
    return RescheduleBatch(
      id: id ?? this.id,
      reason: reason ?? this.reason,
      triggerTaskId: triggerTaskId ?? this.triggerTaskId,
      proposalLabel: proposalLabel ?? this.proposalLabel,
      createdAt: createdAt ?? this.createdAt,
      undoneAt: undoneAt ?? this.undoneAt,
      changes: changes ?? this.changes,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'reason': reason,
      'trigger_task_id': triggerTaskId,
      'proposal_label': proposalLabel,
      'created_at': createdAt,
      'undone_at': undoneAt,
    };
  }

  factory RescheduleBatch.fromMap(Map<String, dynamic> map, [List<RescheduleChange> changes = const []]) {
    return RescheduleBatch(
      id: map['id'] as String,
      reason: map['reason'] as String,
      triggerTaskId: map['trigger_task_id'] as String?,
      proposalLabel: map['proposal_label'] as String?,
      createdAt: map['created_at'] as int,
      undoneAt: map['undone_at'] as int?,
      changes: changes,
    );
  }
}
