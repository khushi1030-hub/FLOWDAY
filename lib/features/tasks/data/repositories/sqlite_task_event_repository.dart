import 'package:sqflite/sqflite.dart';
import '../../domain/entities/task_event.dart';
import '../../domain/repositories/task_event_repository.dart';

/// SQLite implementation of [TaskEventRepository].
class SqliteTaskEventRepository implements TaskEventRepository {
  const SqliteTaskEventRepository(this._db);

  final Database _db;

  @override
  Future<void> logEvent(TaskEvent event) async {
    await _db.insert('task_events', event.toMap());
  }

  @override
  Future<List<TaskEvent>> getEventsForDate(String dateKey) async {
    final rows = await _db.query(
      'task_events',
      where: 'date_key = ?',
      whereArgs: [dateKey],
      orderBy: 'occurred_at ASC',
    );
    return rows.map(TaskEvent.fromMap).toList();
  }

  @override
  Future<List<TaskEvent>> getEventsForTask(String taskId) async {
    final rows = await _db.query(
      'task_events',
      where: 'task_id = ?',
      whereArgs: [taskId],
      orderBy: 'occurred_at ASC',
    );
    return rows.map(TaskEvent.fromMap).toList();
  }

  @override
  Future<List<TaskEvent>> getAllEvents() async {
    final rows = await _db.query('task_events', orderBy: 'occurred_at DESC');
    return rows.map(TaskEvent.fromMap).toList();
  }
}
