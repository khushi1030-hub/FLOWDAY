import 'dart:async';
import 'package:flutter/widgets.dart';
import '../../../core/time/app_clock.dart';
import '../../../features/tasks/domain/repositories/task_repository.dart';
import 'notification_gateway.dart';
import 'notification_id_generator.dart';

/// Coordinates foreground vs background alarm presentation.
///
/// Ensures only one owner presents the alarm:
/// - In foreground: cancels platform notification and triggers in-app navigation + audio.
/// - In background/closed: platform notification fires. Never both!
class ForegroundAlarmManager {
  ForegroundAlarmManager({
    required this.gateway,
    required this.taskRepository,
    required this.clock,
    required this.onForegroundAlarmTriggered,
  });

  final NotificationGateway gateway;
  final TaskRepository taskRepository;
  final AppClock clock;
  final void Function(String taskId) onForegroundAlarmTriggered;

  final Set<String> _triggeredTaskIds = {};
  AppLifecycleState _lifecycleState = AppLifecycleState.resumed;

  bool get isForeground => _lifecycleState == AppLifecycleState.resumed;

  void updateLifecycleState(AppLifecycleState state) {
    _lifecycleState = state;
  }

  /// Checks whether an alarm should fire in the foreground at the current minute.
  Future<void> checkMinuteTick() async {
    if (!isForeground) return;

    final now = clock.now();
    final todayKey = clock.currentDateKey;
    final currentMin = now.hour * 60 + now.minute;

    final tasks = await taskRepository.getTasksForDate(todayKey);

    for (final task in tasks) {
      if (task.kind == 'break') continue;
      if (!task.alarmEnabled) continue;
      if (task.status != 'pending' && task.status != 'rescheduled') continue;

      if (task.endMin == currentMin && !_triggeredTaskIds.contains(task.id)) {
        _triggeredTaskIds.add(task.id);

        // Cancel the scheduled native notification so user does not get both
        final endAlarmId = NotificationIdGenerator.getNotificationId(
          task.id,
          NotificationType.endAlarm,
        );
        await gateway.cancel(endAlarmId);

        // Trigger foreground in-app alarm screen
        onForegroundAlarmTriggered(task.id);
      }
    }
  }

  void resetTriggeredState() {
    _triggeredTaskIds.clear();
  }
}
