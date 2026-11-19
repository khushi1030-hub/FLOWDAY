import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/router/app_router.dart';
import '../notifications/data/local_notification_gateway.dart';
import '../notifications/domain/alarm_audio_service.dart';
import '../notifications/domain/foreground_alarm_manager.dart';
import '../notifications/domain/notification_gateway.dart';
import '../notifications/domain/notification_scheduler.dart';
import 'database_providers.dart';

/// Provider for the notification gateway interface.
final notificationGatewayProvider = Provider<NotificationGateway>((ref) {
  return LocalNotificationGateway();
});

/// Provider for the notification scheduler use case.
final notificationSchedulerProvider = Provider<NotificationScheduler>((ref) {
  final gateway = ref.watch(notificationGatewayProvider);
  final taskRepo = ref.watch(taskRepositoryProvider);
  final settingsRepo = ref.watch(settingsRepositoryProvider);
  final clock = ref.watch(clockProvider);

  final scheduler = NotificationScheduler(
    gateway: gateway,
    taskRepository: taskRepo,
    settingsRepository: settingsRepo,
    clock: clock,
  );

  ref.onDispose(() {
    scheduler.dispose();
  });

  return scheduler;
});

/// Provider for the audio player service.
final alarmAudioServiceProvider = Provider<AlarmAudioService>((ref) {
  final service = AlarmAudioService();
  ref.onDispose(() {
    service.dispose();
  });
  return service;
});

/// Provider for the foreground alarm manager.
final foregroundAlarmManagerProvider = Provider<ForegroundAlarmManager>((ref) {
  final gateway = ref.watch(notificationGatewayProvider);
  final taskRepo = ref.watch(taskRepositoryProvider);
  final clock = ref.watch(clockProvider);

  return ForegroundAlarmManager(
    gateway: gateway,
    taskRepository: taskRepo,
    clock: clock,
    onForegroundAlarmTriggered: (taskId) {
      appRouter.push('/alarm/$taskId');
    },
  );
});
