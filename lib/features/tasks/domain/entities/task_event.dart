/// Domain entity for task audit events (completion, incomplete, moved, etc.).
class TaskEvent {
  const TaskEvent({
    this.id,
    required this.taskId,
    required this.taskTitle,
    required this.dateKey,
    required this.eventType,
    this.plannedMinutes,
    this.actualMinutes,
    required this.occurredAt,
  });

  final int? id;
  final String taskId;
  final String taskTitle;
  final String dateKey;
  final String eventType; // completed | marked_incomplete | extended | moved | carried_forward | deleted | postponed | skipped
  final int? plannedMinutes;
  final int? actualMinutes;
  final int occurredAt; // epoch milliseconds UTC

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'task_id': taskId,
      'task_title': taskTitle,
      'date_key': dateKey,
      'event_type': eventType,
      'planned_minutes': plannedMinutes,
      'actual_minutes': actualMinutes,
      'occurred_at': occurredAt,
    };
  }

  factory TaskEvent.fromMap(Map<String, dynamic> map) {
    return TaskEvent(
      id: map['id'] as int?,
      taskId: map['task_id'] as String,
      taskTitle: map['task_title'] as String,
      dateKey: map['date_key'] as String,
      eventType: map['event_type'] as String,
      plannedMinutes: map['planned_minutes'] as int?,
      actualMinutes: map['actual_minutes'] as int?,
      occurredAt: map['occurred_at'] as int,
    );
  }
}
