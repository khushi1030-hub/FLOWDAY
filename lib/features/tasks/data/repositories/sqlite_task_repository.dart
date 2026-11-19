import 'dart:async';
import 'package:sqflite/sqflite.dart';
import '../../../../core/time/app_clock.dart';
import '../../domain/entities/task.dart';
import '../../domain/entities/task_event.dart';
import '../../domain/repositories/task_repository.dart';

/// SQLite implementation of [TaskRepository] with reactive stream notifications and event logging.
class SqliteTaskRepository implements TaskRepository {
  SqliteTaskRepository(this._db, [AppClock? clock]) : _clock = clock ?? const SystemClock();

  final Database _db;
  final AppClock _clock;
  final _changeController = StreamController<String>.broadcast();

  /// Hook for Phase 7 notification scheduler to cancel reminders/alarms on task deletion.
  Future<void> Function(String taskId)? onTaskDeleted;

  void _notifyDate(String dateKey) {
    if (!_changeController.isClosed) {
      _changeController.add(dateKey);
    }
  }

  /// Public hook to notify task streams on external schedule updates (e.g. rescheduling batches).
  void notifyDate(String dateKey) => _notifyDate(dateKey);
  void notifyAll() => _notifyDate('ALL');

  @override
  Future<Task?> getTaskById(String id) async {
    final rows = await _db.query(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Task.fromMap(rows.first);
  }

  @override
  Future<List<Task>> getTasksForDate(String dateKey) async {
    final rows = await _db.query(
      'tasks',
      where: 'date_key = ?',
      whereArgs: [dateKey],
      orderBy: 'start_min ASC, priority DESC',
    );
    return rows.map(Task.fromMap).toList();
  }

  @override
  Stream<List<Task>> watchTasksForDate(String dateKey) async* {
    yield await getTasksForDate(dateKey);
    await for (final changedDate in _changeController.stream) {
      if (changedDate == dateKey || changedDate == 'ALL') {
        yield await getTasksForDate(dateKey);
      }
    }
  }

  @override
  Stream<List<Task>> watchAllTasks() async* {
    yield await getAllTasks();
    await for (final _ in _changeController.stream) {
      yield await getAllTasks();
    }
  }

  @override
  Future<List<Task>> getAllTasks() async {
    final rows = await _db.query('tasks', orderBy: 'date_key ASC, start_min ASC');
    return rows.map(Task.fromMap).toList();
  }

  @override
  Future<void> insertTask(Task task) async {
    final nowMs = _clock.now().millisecondsSinceEpoch;
    await _db.transaction((txn) async {
      await txn.insert(
        'tasks',
        task.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      final event = TaskEvent(
        taskId: task.id,
        taskTitle: task.title,
        dateKey: task.dateKey,
        eventType: 'created',
        plannedMinutes: task.durationMin,
        actualMinutes: 0,
        occurredAt: nowMs,
      );
      await txn.insert('task_events', event.toMap());
    });
    _notifyDate(task.dateKey);
  }

  @override
  Future<void> updateTask(Task task) async {
    final nowMs = _clock.now().millisecondsSinceEpoch;
    await _db.transaction((txn) async {
      final taskMap = Map<String, dynamic>.from(task.toMap());
      taskMap['updated_at'] = nowMs;
      await txn.update(
        'tasks',
        taskMap,
        where: 'id = ?',
        whereArgs: [task.id],
      );
      final event = TaskEvent(
        taskId: task.id,
        taskTitle: task.title,
        dateKey: task.dateKey,
        eventType: 'edited',
        plannedMinutes: task.durationMin,
        actualMinutes: 0,
        occurredAt: nowMs,
      );
      await txn.insert('task_events', event.toMap());
    });
    _notifyDate(task.dateKey);
  }

  @override
  Future<void> deleteTask(String id) async {
    final task = await getTaskById(id);
    if (task == null) return;

    final nowMs = _clock.now().millisecondsSinceEpoch;
    await _db.transaction((txn) async {
      await txn.delete('tasks', where: 'id = ?', whereArgs: [id]);
      final event = TaskEvent(
        taskId: task.id,
        taskTitle: task.title,
        dateKey: task.dateKey,
        eventType: 'deleted',
        plannedMinutes: task.durationMin,
        actualMinutes: 0,
        occurredAt: nowMs,
      );
      await txn.insert('task_events', event.toMap());
    });
    // Trigger future reminders cancellation hook (for Phase 7)
    await onTaskDeleted?.call(id);
    _notifyDate(task.dateKey);
  }

  @override
  Future<void> markCompleted(String id, int completedAt) async {
    final task = await getTaskById(id);
    if (task == null) return;

    await _db.transaction((txn) async {
      await txn.update(
        'tasks',
        {
          'status': 'completed',
          'completed_at': completedAt,
          'updated_at': completedAt,
        },
        where: 'id = ?',
        whereArgs: [id],
      );

      // Remove any existing completed event for this task so exactly one remains
      await txn.delete(
        'task_events',
        where: 'task_id = ? AND event_type = ?',
        whereArgs: [id, 'completed'],
      );

      final event = TaskEvent(
        taskId: task.id,
        taskTitle: task.title,
        dateKey: task.dateKey,
        eventType: 'completed',
        plannedMinutes: task.durationMin,
        actualMinutes: task.durationMin,
        occurredAt: completedAt,
      );
      await txn.insert('task_events', event.toMap());
    });

    _notifyDate(task.dateKey);
  }

  @override
  Future<void> markIncomplete(String id) async {
    final task = await getTaskById(id);
    if (task == null) return;

    final nowMs = _clock.now().millisecondsSinceEpoch;
    await _db.transaction((txn) async {
      await txn.update(
        'tasks',
        {
          'status': 'incomplete',
          'completed_at': null,
          'updated_at': nowMs,
        },
        where: 'id = ?',
        whereArgs: [id],
      );

      // Un-completing via swipe left clears any stale 'completed' history row
      await txn.delete(
        'task_events',
        where: 'task_id = ? AND event_type = ?',
        whereArgs: [id, 'completed'],
      );

      final event = TaskEvent(
        taskId: task.id,
        taskTitle: task.title,
        dateKey: task.dateKey,
        eventType: 'marked_incomplete',
        plannedMinutes: task.durationMin,
        actualMinutes: 0,
        occurredAt: nowMs,
      );
      await txn.insert('task_events', event.toMap());
    });

    _notifyDate(task.dateKey);
  }

  @override
  Future<void> applyDelayShift({
    required Task extendedTask,
    required List<Task> shiftedTasks,
  }) async {
    final nowMs = _clock.now().millisecondsSinceEpoch;
    await _db.transaction((txn) async {
      // 1. Update extended task
      final updatedExtended = extendedTask.copyWith(
        wasRescheduled: true,
        updatedAt: nowMs,
      );
      await txn.update(
        'tasks',
        updatedExtended.toMap(),
        where: 'id = ?',
        whereArgs: [updatedExtended.id],
      );
      final event1 = TaskEvent(
        taskId: updatedExtended.id,
        taskTitle: updatedExtended.title,
        dateKey: updatedExtended.dateKey,
        eventType: 'rescheduled',
        plannedMinutes: updatedExtended.durationMin,
        actualMinutes: 0,
        occurredAt: nowMs,
      );
      await txn.insert('task_events', event1.toMap());

      // 2. Update all shifted downstream tasks
      for (final shifted in shiftedTasks) {
        final updatedShifted = shifted.copyWith(
          wasRescheduled: true,
          updatedAt: nowMs,
        );
        await txn.update(
          'tasks',
          updatedShifted.toMap(),
          where: 'id = ?',
          whereArgs: [updatedShifted.id],
        );
        final event = TaskEvent(
          taskId: updatedShifted.id,
          taskTitle: updatedShifted.title,
          dateKey: updatedShifted.dateKey,
          eventType: 'rescheduled',
          plannedMinutes: updatedShifted.durationMin,
          actualMinutes: 0,
          occurredAt: nowMs,
        );
        await txn.insert('task_events', event.toMap());
      }
    });

    _notifyDate(extendedTask.dateKey);
  }

  @override
  Future<void> rescheduleTask(
    Task task, {
    required String newDateKey,
    required int newStartMin,
    required int newEndMin,
    String? carriedFromDateKey,
  }) async {
    final nowMs = _clock.now().millisecondsSinceEpoch;
    final isDifferentDate = task.dateKey != newDateKey;

    await _db.transaction((txn) async {
      final updated = task.copyWith(
        dateKey: newDateKey,
        startMin: newStartMin,
        endMin: newEndMin,
        status: 'rescheduled',
        wasRescheduled: true,
        carriedFromDateKey: carriedFromDateKey,
        updatedAt: nowMs,
      );

      await txn.update(
        'tasks',
        updated.toMap(),
        where: 'id = ?',
        whereArgs: [updated.id],
      );

      final event = TaskEvent(
        taskId: updated.id,
        taskTitle: updated.title,
        dateKey: newDateKey,
        eventType: isDifferentDate ? 'postponed' : 'rescheduled',
        plannedMinutes: updated.durationMin,
        actualMinutes: 0,
        occurredAt: nowMs,
      );
      await txn.insert('task_events', event.toMap());
    });

    _notifyDate(task.dateKey);
    if (isDifferentDate) {
      _notifyDate(newDateKey);
    }
  }

  @override
  Future<void> deleteAll() async {
    await _db.delete('tasks');
    _notifyDate('ALL');
  }

  void dispose() {
    _changeController.close();
  }
}
