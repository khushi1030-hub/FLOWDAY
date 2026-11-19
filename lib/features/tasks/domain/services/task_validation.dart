import '../../../../core/time/day_window.dart';

/// Result of task validation containing validity and a friendly user-facing error message.
class TaskValidationResult {
  const TaskValidationResult({
    required this.isValid,
    this.errorMessage,
  });

  final bool isValid;
  final String? errorMessage;

  static const valid = TaskValidationResult(isValid: true);
  factory TaskValidationResult.error(String message) => TaskValidationResult(isValid: false, errorMessage: message);
}

/// Pure domain validation service for task creation and editing.
class TaskValidator {
  const TaskValidator._();

  /// Validates a task's title, timing bounds, duration, day window, and midnight constraint.
  static TaskValidationResult validate({
    required String title,
    required int startMin,
    required int endMin,
    required int dayStartMin,
    required int dayEndMin,
  }) {
    if (title.trim().isEmpty) {
      return TaskValidationResult.error('Please enter a task title.');
    }
    if (endMin > 1440 || (endMin < startMin && startMin >= 720 && endMin <= 720)) {
      return TaskValidationResult.error("Tasks cannot cross midnight. Please split into tomorrow's schedule.");
    }
    if (endMin <= startMin) {
      return TaskValidationResult.error('End time must be after start time.');
    }

    final window = DayWindow(startMin: dayStartMin, endMin: dayEndMin);
    if (!window.isIntervalWithin(startMin, endMin)) {
      return TaskValidationResult.error('Task must be scheduled within your waking hours (${window.formattedRange}).');
    }
    return TaskValidationResult.valid;
  }
}

