import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flow_day/core/notifications/domain/foreground_alarm_manager.dart';
import 'package:flow_day/core/notifications/domain/notification_gateway.dart';
import 'package:flow_day/core/notifications/domain/notification_id_generator.dart';
import 'package:flow_day/core/time/app_clock.dart';
import 'package:flow_day/features/tasks/domain/entities/task.dart';
import 'notification_scheduler_test.dart';

void main() {
  group('ForegroundAlarmManager Tests (Requirement 6)', () {
    late FakeNotificationGateway gateway;
    late FakeTaskRepo taskRepo;
    late FakeClock clock;
    late List<String> triggeredForegroundTaskIds;
    late ForegroundAlarmManager manager;

    final baseTime = DateTime(2026, 5, 14, 10, 0); // 10:00 AM (minute 600)

    setUp(() {
      gateway = FakeNotificationGateway();
      taskRepo = FakeTaskRepo();
      clock = FakeClock(baseTime);
      triggeredForegroundTaskIds = [];

      manager = ForegroundAlarmManager(
        gateway: gateway,
        taskRepository: taskRepo,
        clock: clock,
        onForegroundAlarmTriggered: (taskId) {
          triggeredForegroundTaskIds.add(taskId);
        },
      );
    });

    test('In foreground: minute tick matching task endMin cancels platform notification and triggers in-app alarm', () async {
      await taskRepo.insertTask(Task(
        id: 't-fg',
        title: 'Foreground Task',
        dateKey: '2026-05-14',
        startMin: 540,
        endMin: 600, // Matches clock now (10:00 AM)
        status: 'pending',
        alarmEnabled: true,
        createdAt: baseTime.millisecondsSinceEpoch,
        updatedAt: baseTime.millisecondsSinceEpoch,
      ));

      final endAlarmId = NotificationIdGenerator.getNotificationId('t-fg', NotificationType.endAlarm);
      // Simulate scheduled platform notification
      await gateway.scheduleZonedNotification(
        id: endAlarmId,
        title: "Time's up! ⏰",
        body: 'Foreground Task is complete',
        scheduledDate: baseTime,
        channelId: 'flowday_alarms_soft_chime',
      );
      expect(gateway.scheduled.containsKey(endAlarmId), isTrue);

      manager.updateLifecycleState(AppLifecycleState.resumed); // In foreground
      await manager.checkMinuteTick();

      // Verified: platform notification was cancelled
      expect(gateway.scheduled.containsKey(endAlarmId), isFalse);
      // Verified: in-app alarm was triggered
      expect(triggeredForegroundTaskIds, contains('t-fg'));
    });

    test('In background: minute tick does NOT trigger in-app alarm and does NOT cancel notification', () async {
      await taskRepo.insertTask(Task(
        id: 't-bg',
        title: 'Background Task',
        dateKey: '2026-05-14',
        startMin: 540,
        endMin: 600,
        status: 'pending',
        alarmEnabled: true,
        createdAt: baseTime.millisecondsSinceEpoch,
        updatedAt: baseTime.millisecondsSinceEpoch,
      ));

      final endAlarmId = NotificationIdGenerator.getNotificationId('t-bg', NotificationType.endAlarm);
      await gateway.scheduleZonedNotification(
        id: endAlarmId,
        title: "Time's up! ⏰",
        body: 'Background Task',
        scheduledDate: baseTime,
        channelId: 'flowday_alarms_soft_chime',
      );

      manager.updateLifecycleState(AppLifecycleState.paused); // In background
      await manager.checkMinuteTick();

      // Platform notification remains untouched so the system notification fires
      expect(gateway.scheduled.containsKey(endAlarmId), isTrue);
      // In-app alarm was NOT triggered
      expect(triggeredForegroundTaskIds, isEmpty);
    });
  });
}
