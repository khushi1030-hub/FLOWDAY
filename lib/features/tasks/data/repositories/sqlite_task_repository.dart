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
      await txn.update(
        'tasks',
        task.toMap(),
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
  Future<void> deleteAll() async {
    await _db.delete('tasks');
    _notifyDate('ALL');
  }

  void dispose() {
    _changeController.close();
  }
}
