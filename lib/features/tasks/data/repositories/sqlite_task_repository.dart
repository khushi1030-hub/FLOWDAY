import 'dart:async';
import 'package:sqflite/sqflite.dart';
import '../../domain/entities/task.dart';
import '../../domain/repositories/task_repository.dart';

/// SQLite implementation of [TaskRepository] with reactive stream notifications.
class SqliteTaskRepository implements TaskRepository {
  SqliteTaskRepository(this._db);

  final Database _db;
  final _changeController = StreamController<String>.broadcast();

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
    // Yield immediate state
    yield await getTasksForDate(dateKey);

    // Yield upon every relevant database modification
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
    await _db.insert(
      'tasks',
      task.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _notifyDate(task.dateKey);
  }

  @override
  Future<void> updateTask(Task task) async {
    await _db.update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
    _notifyDate(task.dateKey);
  }

  @override
  Future<void> deleteTask(String id) async {
    final task = await getTaskById(id);
    await _db.delete('tasks', where: 'id = ?', whereArgs: [id]);
    if (task != null) {
      _notifyDate(task.dateKey);
    } else {
      _notifyDate('ALL');
    }
  }

  @override
  Future<void> markCompleted(String id, int completedAt) async {
    final task = await getTaskById(id);
    if (task == null) return;

    await _db.update(
      'tasks',
      {
        'status': 'completed',
        'completed_at': completedAt,
        'updated_at': completedAt,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    _notifyDate(task.dateKey);
  }

  @override
  Future<void> markIncomplete(String id) async {
    final task = await getTaskById(id);
    if (task == null) return;

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    await _db.update(
      'tasks',
      {
        'status': 'incomplete',
        'completed_at': null,
        'updated_at': nowMs,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
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
