import '../entities/task_event.dart';

/// Repository interface for task audit and completion history events.
abstract class TaskEventRepository {
  Future<void> logEvent(TaskEvent event);
  Future<List<TaskEvent>> getEventsForDate(String dateKey);
  Future<List<TaskEvent>> getEventsForTask(String taskId);
  Future<List<TaskEvent>> getAllEvents();
}
