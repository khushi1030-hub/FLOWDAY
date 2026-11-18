import '../entities/focus_session.dart';

/// Repository interface for focus sessions.
abstract class FocusSessionRepository {
  Future<void> insertSession(FocusSession session);
  Future<void> updateSession(FocusSession session);
  Future<FocusSession?> getSessionById(String id);
  Future<FocusSession?> getActiveSession();
  Future<List<FocusSession>> getSessionsForTask(String taskId);
  Future<List<FocusSession>> getAllSessions();
}
