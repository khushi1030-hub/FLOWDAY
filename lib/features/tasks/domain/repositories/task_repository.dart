import '../entities/task.dart';

/// Repository interface for task persistence and live stream updates.
abstract class TaskRepository {
  Future<Task?> getTaskById(String id);
  Future<List<Task>> getTasksForDate(String dateKey);
  Stream<List<Task>> watchTasksForDate(String dateKey);
  Future<List<Task>> getAllTasks();
  Future<void> insertTask(Task task);
  Future<void> updateTask(Task task);
  Future<void> deleteTask(String id);
  Future<void> markCompleted(String id, int completedAt);
  Future<void> markIncomplete(String id);
  Future<void> deleteAll();
}
