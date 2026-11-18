import '../../../../core/utils/time_utils.dart';

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

    final bool isWithinWindow;
    if (dayStartMin == dayEndMin) {
      // 24-hour active window: entire day is valid
      isWithinWindow = true;
    } else if (dayStartMin < dayEndMin) {
      // Standard daytime window: [dayStartMin, dayEndMin]
      isWithinWindow = startMin >= dayStartMin && endMin <= dayEndMin;
    } else {
      // Overnight sleep rhythm (sleep past midnight: dayEndMin < dayStartMin)
      // Waking window spans [dayStartMin, 1440) and [0, dayEndMin]
      isWithinWindow = (startMin >= dayStartMin && endMin <= 1440) ||
          (startMin >= 0 && endMin <= dayEndMin);
    }

    if (!isWithinWindow) {
      final startStr = TimeUtils.formatMinutesToTime(dayStartMin);
      final endStr = TimeUtils.formatMinutesToTime(dayEndMin);
      return TaskValidationResult.error('Task must be scheduled within your waking hours ($startStr – $endStr).');
    }
    return TaskValidationResult.valid;
  }
}

