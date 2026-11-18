import 'package:sqflite/sqflite.dart';
import '../../domain/entities/focus_session.dart';
import '../../domain/repositories/focus_session_repository.dart';

/// SQLite implementation of [FocusSessionRepository].
class SqliteFocusSessionRepository implements FocusSessionRepository {
  const SqliteFocusSessionRepository(this._db);

  final Database _db;

  @override
  Future<void> insertSession(FocusSession session) async {
    await _db.insert(
      'focus_sessions',
      session.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> updateSession(FocusSession session) async {
    await _db.update(
      'focus_sessions',
      session.toMap(),
      where: 'id = ?',
      whereArgs: [session.id],
    );
  }

  @override
  Future<FocusSession?> getSessionById(String id) async {
    final rows = await _db.query(
      'focus_sessions',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return FocusSession.fromMap(rows.first);
  }

  @override
  Future<FocusSession?> getActiveSession() async {
    final rows = await _db.query(
      'focus_sessions',
      where: "state IN ('running', 'paused')",
      orderBy: 'started_at DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return FocusSession.fromMap(rows.first);
  }

  @override
  Future<List<FocusSession>> getSessionsForTask(String taskId) async {
    final rows = await _db.query(
      'focus_sessions',
      where: 'task_id = ?',
      whereArgs: [taskId],
      orderBy: 'started_at ASC',
    );
    return rows.map(FocusSession.fromMap).toList();
  }

  @override
  Future<List<FocusSession>> getAllSessions() async {
    final rows = await _db.query('focus_sessions', orderBy: 'started_at DESC');
    return rows.map(FocusSession.fromMap).toList();
  }
}
