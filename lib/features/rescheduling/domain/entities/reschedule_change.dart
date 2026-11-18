/// Domain entity representing a single task shift within a reschedule batch.
class RescheduleChange {
  const RescheduleChange({
    this.id,
    required this.batchId,
    required this.taskId,
    required this.oldDateKey,
    required this.oldStartMin,
    required this.oldEndMin,
    required this.newDateKey,
    required this.newStartMin,
    required this.newEndMin,
  });

  final int? id;
  final String batchId;
  final String taskId;
  final String oldDateKey;
  final int oldStartMin;
  final int oldEndMin;
  final String newDateKey;
  final int newStartMin;
  final int newEndMin;

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'batch_id': batchId,
      'task_id': taskId,
      'old_date_key': oldDateKey,
      'old_start_min': oldStartMin,
      'old_end_min': oldEndMin,
      'new_date_key': newDateKey,
      'new_start_min': newStartMin,
      'new_end_min': newEndMin,
    };
  }

  factory RescheduleChange.fromMap(Map<String, dynamic> map) {
    return RescheduleChange(
      id: map['id'] as int?,
      batchId: map['batch_id'] as String,
      taskId: map['task_id'] as String,
      oldDateKey: map['old_date_key'] as String,
      oldStartMin: map['old_start_min'] as int,
      oldEndMin: map['old_end_min'] as int,
      newDateKey: map['new_date_key'] as String,
      newStartMin: map['new_start_min'] as int,
      newEndMin: map['new_end_min'] as int,
    );
  }
}
