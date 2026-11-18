import 'task_status.dart';

/// Pure domain entity representing a planned task or break.
class Task {
  const Task({
    required this.id,
    required this.title,
    this.description,
    required this.dateKey,
    required this.startMin,
    required this.endMin,
    this.priority = 1,
    this.kind = 'task',
    this.isFixed = false,
    this.categoryId,
    this.status = 'pending',
    this.wasRescheduled = false,
    this.alarmEnabled = true,
    this.notes,
    this.iconKey,
    this.recurrence = 'never',
    this.recurrenceRule,
    this.seriesId,
    this.hasConflict = false,
    this.reminderOffsetMin,
    this.completedAt,
    this.carriedFromDateKey,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String? description;
  final String dateKey; // YYYY-MM-DD
  final int startMin; // 0..1439
  final int endMin; // 1..1440
  final int priority; // 0: low, 1: medium, 2: high
  final String kind; // 'task' | 'break'
  final bool isFixed;
  final int? categoryId;
  final String status; // 'pending' | 'completed' | 'incomplete' | 'rescheduled' | 'postponed' | 'skipped'
  final bool wasRescheduled;
  final bool alarmEnabled;
  final String? notes;
  final String? iconKey;
  final String recurrence; // 'never' | 'daily' | 'weekly' | 'custom'
  final String? recurrenceRule;
  final String? seriesId;
  final bool hasConflict;
  final int? reminderOffsetMin;
  final int? completedAt; // epoch milliseconds UTC
  final String? carriedFromDateKey;
  final int createdAt; // epoch milliseconds UTC
  final int updatedAt; // epoch milliseconds UTC

  /// Duration in minutes.
  int get durationMin => endMin - startMin;

  /// Convenience boolean whether this item is a break.
  bool get isBreak => kind == 'break';

  /// Whether task is marked completed.
  bool get isCompleted => status == 'completed';

  /// Calculates dynamic runtime status (Upcoming, In Progress, Delayed, etc.).
  TaskRuntimeStatus runtimeStatus(DateTime now) {
    return TaskStatusResolver.resolve(
      status: status,
      dateKey: dateKey,
      startMin: startMin,
      endMin: endMin,
      now: now,
    );
  }

  Task copyWith({
    String? id,
    String? title,
    String? description,
    String? dateKey,
    int? startMin,
    int? endMin,
    int? priority,
    String? kind,
    bool? isFixed,
    int? categoryId,
    String? status,
    bool? wasRescheduled,
    bool? alarmEnabled,
    String? notes,
    String? iconKey,
    String? recurrence,
    String? recurrenceRule,
    String? seriesId,
    bool? hasConflict,
    int? reminderOffsetMin,
    int? completedAt,
    String? carriedFromDateKey,
    int? createdAt,
    int? updatedAt,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dateKey: dateKey ?? this.dateKey,
      startMin: startMin ?? this.startMin,
      endMin: endMin ?? this.endMin,
      priority: priority ?? this.priority,
      kind: kind ?? this.kind,
      isFixed: isFixed ?? this.isFixed,
      categoryId: categoryId ?? this.categoryId,
      status: status ?? this.status,
      wasRescheduled: wasRescheduled ?? this.wasRescheduled,
      alarmEnabled: alarmEnabled ?? this.alarmEnabled,
      notes: notes ?? this.notes,
      iconKey: iconKey ?? this.iconKey,
      recurrence: recurrence ?? this.recurrence,
      recurrenceRule: recurrenceRule ?? this.recurrenceRule,
      seriesId: seriesId ?? this.seriesId,
      hasConflict: hasConflict ?? this.hasConflict,
      reminderOffsetMin: reminderOffsetMin ?? this.reminderOffsetMin,
      completedAt: completedAt ?? this.completedAt,
      carriedFromDateKey: carriedFromDateKey ?? this.carriedFromDateKey,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'date_key': dateKey,
      'start_min': startMin,
      'end_min': endMin,
      'priority': priority,
      'kind': kind,
      'is_fixed': isFixed ? 1 : 0,
      'category_id': categoryId,
      'status': status,
      'was_rescheduled': wasRescheduled ? 1 : 0,
      'alarm_enabled': alarmEnabled ? 1 : 0,
      'notes': notes,
      'icon_key': iconKey,
      'recurrence': recurrence,
      'recurrence_rule': recurrenceRule,
      'series_id': seriesId,
      'has_conflict': hasConflict ? 1 : 0,
      'reminder_offset_min': reminderOffsetMin,
      'completed_at': completedAt,
      'carried_from_date_key': carriedFromDateKey,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      dateKey: map['date_key'] as String,
      startMin: map['start_min'] as int,
      endMin: map['end_min'] as int,
      priority: map['priority'] as int? ?? 1,
      kind: map['kind'] as String? ?? 'task',
      isFixed: (map['is_fixed'] as int? ?? 0) == 1,
      categoryId: map['category_id'] as int?,
      status: map['status'] as String? ?? 'pending',
      wasRescheduled: (map['was_rescheduled'] as int? ?? 0) == 1,
      alarmEnabled: (map['alarm_enabled'] as int? ?? 1) == 1,
      notes: map['notes'] as String?,
      iconKey: map['icon_key'] as String?,
      recurrence: map['recurrence'] as String? ?? 'never',
      recurrenceRule: map['recurrence_rule'] as String?,
      seriesId: map['series_id'] as String?,
      hasConflict: (map['has_conflict'] as int? ?? 0) == 1,
      reminderOffsetMin: map['reminder_offset_min'] as int?,
      completedAt: map['completed_at'] as int?,
      carriedFromDateKey: map['carried_from_date_key'] as String?,
      createdAt: map['created_at'] as int,
      updatedAt: map['updated_at'] as int,
    );
  }
}
