/// Domain entity representing a deep focus session.
class FocusSession {
  const FocusSession({
    required this.id,
    this.taskId,
    required this.plannedSeconds,
    this.elapsedSeconds = 0,
    required this.state, // 'running' | 'paused' | 'completed' | 'abandoned'
    required this.startedAt,
    this.lastResumedAt,
    this.endedAt,
  });

  final String id;
  final String? taskId;
  final int plannedSeconds;
  final int elapsedSeconds;
  final String state;
  final int startedAt; // epoch milliseconds UTC
  final int? lastResumedAt; // epoch milliseconds UTC
  final int? endedAt; // epoch milliseconds UTC

  FocusSession copyWith({
    String? id,
    String? taskId,
    int? plannedSeconds,
    int? elapsedSeconds,
    String? state,
    int? startedAt,
    int? lastResumedAt,
    int? endedAt,
  }) {
    return FocusSession(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      plannedSeconds: plannedSeconds ?? this.plannedSeconds,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      state: state ?? this.state,
      startedAt: startedAt ?? this.startedAt,
      lastResumedAt: lastResumedAt ?? this.lastResumedAt,
      endedAt: endedAt ?? this.endedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'task_id': taskId,
      'planned_seconds': plannedSeconds,
      'elapsed_seconds': elapsedSeconds,
      'state': state,
      'started_at': startedAt,
      'last_resumed_at': lastResumedAt,
      'ended_at': endedAt,
    };
  }

  factory FocusSession.fromMap(Map<String, dynamic> map) {
    return FocusSession(
      id: map['id'] as String,
      taskId: map['task_id'] as String?,
      plannedSeconds: map['planned_seconds'] as int,
      elapsedSeconds: map['elapsed_seconds'] as int? ?? 0,
      state: map['state'] as String,
      startedAt: map['started_at'] as int,
      lastResumedAt: map['last_resumed_at'] as int?,
      endedAt: map['ended_at'] as int?,
    );
  }
}
