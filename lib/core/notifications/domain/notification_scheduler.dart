import 'dart:async';
import 'dart:convert';
import '../../../core/time/app_clock.dart';
import '../../../core/utils/time_utils.dart';
import '../../../features/settings/domain/repositories/settings_repository.dart';
import '../../../features/tasks/domain/repositories/task_repository.dart';
import 'notification_gateway.dart';
import 'notification_id_generator.dart';

/// Domain scheduler that plans and synchronizes all local notifications and alarms.
class NotificationScheduler {
  NotificationScheduler({
    required this.gateway,
    required this.taskRepository,
    required this.settingsRepository,
    required this.clock,
  });

  final NotificationGateway gateway;
  final TaskRepository taskRepository;
  final SettingsRepository settingsRepository;
  final AppClock clock;

  StreamSubscription? _taskSub;
  StreamSubscription? _settingsSub;
  Timer? _debounceTimer;

  /// Tracks all notification IDs currently scheduled by this scheduler.
  final Set<int> _scheduledIds = {};

  /// Starts listening to task and settings changes with a debounced resync.
  void startListening({Duration debounceDuration = const Duration(milliseconds: 300)}) {
    _taskSub?.cancel();
    _settingsSub?.cancel();

    _taskSub = taskRepository.watchAllTasks().listen((_) => _debouncedResync(debounceDuration));
    _settingsSub = settingsRepository.watchSettings().listen((_) => _debouncedResync(debounceDuration));
  }

  void dispose() {
    _debounceTimer?.cancel();
    _taskSub?.cancel();
    _settingsSub?.cancel();
  }

  void _debouncedResync(Duration delay) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(delay, () {
      resyncAll();
    });
  }

  static String formatDateKey(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static DateTime parseDateKey(String key) {
    final parts = key.split('-');
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  /// Cancels all scheduled notifications and completely rebuilds them from the DB.
  ///
  /// Idempotent: running consecutive times yields the exact same scheduled state.
  Future<void> resyncAll() async {
    final now = clock.now();
    final todayKey = clock.currentDateKey;
    final settings = await settingsRepository.getSettings();

    // Clear previously tracked IDs from the gateway
    await gateway.cancelAll();
    _scheduledIds.clear();

    final usedIds = <int>{};
    final soundKey = _getSoundSlug(settings.notificationSound);
    final alarmChannel = 'flowday_alarms_$soundKey';
    final reminderChannel = 'flowday_reminders_$soundKey';
    const summaryChannel = 'flowday_summary';

    final canExact = await gateway.canScheduleExactAlarms();

    // 1. Schedule Task Start Reminders and End-of-task Alarms across 7-day horizon
    for (int dayOffset = 0; dayOffset <= 7; dayOffset++) {
      final date = now.add(Duration(days: dayOffset));
      final dateKey = formatDateKey(date);
      final tasks = await taskRepository.getTasksForDate(dateKey);

      for (final task in tasks) {
        // Exclude breaks
        if (task.kind == 'break') continue;

        // Requirement 8: ONLY pending or rescheduled tasks with future time.
        // Never completed, skipped, or incomplete tasks.
        final isEligible = task.status == 'pending' || task.status == 'rescheduled';
        if (!isEligible) continue;

        final taskDate = parseDateKey(task.dateKey);

        // A. Start Reminder
        if (task.reminderOffsetMin != null && task.reminderOffsetMin! > 0) {
          final startDateTime = DateTime(
            taskDate.year,
            taskDate.month,
            taskDate.day,
            task.startMin ~/ 60,
            task.startMin % 60,
          ).subtract(Duration(minutes: task.reminderOffsetMin!));

          if (startDateTime.isAfter(now)) {
            final rawId = NotificationIdGenerator.getNotificationId(
              task.id,
              NotificationType.startReminder,
            );
            final allocatedId = NotificationIdGenerator.allocateId(
              requestedId: rawId,
              usedIds: usedIds,
            );

            final payload = jsonEncode({
              'type': 'start_reminder',
              'taskId': task.id,
              'route': '/task/${task.id}',
            });

            await gateway.scheduleZonedNotification(
              id: allocatedId,
              title: 'Upcoming: ${task.title}',
              body: 'Starts in ${task.reminderOffsetMin}m (${TimeUtils.formatMinutesToTime(task.startMin)})',
              scheduledDate: startDateTime,
              channelId: reminderChannel,
              payload: payload,
              fullScreenIntent: false,
              exact: canExact,
            );
            _scheduledIds.add(allocatedId);
          }
        }

        // B. End-Time Alarm
        if (task.alarmEnabled && settings.taskAlarmsEnabled) {
          final endDateTime = DateTime(
            taskDate.year,
            taskDate.month,
            taskDate.day,
            task.endMin ~/ 60,
            task.endMin % 60,
          );

          if (endDateTime.isAfter(now)) {
            final rawId = NotificationIdGenerator.getNotificationId(
              task.id,
              NotificationType.endAlarm,
            );
            final allocatedId = NotificationIdGenerator.allocateId(
              requestedId: rawId,
              usedIds: usedIds,
            );

            final payload = jsonEncode({
              'type': 'alarm',
              'taskId': task.id,
              'route': '/alarm/${task.id}',
            });

            await gateway.scheduleZonedNotification(
              id: allocatedId,
              title: "Time's up! ⏰",
              body: '${task.title} is complete · Check in now',
              scheduledDate: endDateTime,
              channelId: alarmChannel,
              payload: payload,
              fullScreenIntent: true,
              exact: canExact,
            );
            _scheduledIds.add(allocatedId);
          }
        }
      }
    }

    // 2. Schedule Daily Summary Notification (p17 / D12)
    if (settings.dailySummaryEnabled) {
      // D12: Default = nightly_review_min - 60 min (20:30 / 08:30 PM)
      // Handles wrapping past midnight safely
      final summaryMin = (settings.dailySummaryMin % 1440 + 1440) % 1440;
      final todayDate = parseDateKey(todayKey);

      var summaryTime = DateTime(
        todayDate.year,
        todayDate.month,
        todayDate.day,
        summaryMin ~/ 60,
        summaryMin % 60,
      );

      // If today's summary time has already passed, schedule for tomorrow
      if (summaryTime.isBefore(now) || summaryTime.isAtSameMomentAs(now)) {
        summaryTime = summaryTime.add(const Duration(days: 1));
      }

      final payload = jsonEncode({
        'type': 'daily_summary',
        'route': '/schedule', // Route that exists today (no dead routes)
      });

      await gateway.scheduleZonedNotification(
        id: kDailySummaryNotificationId,
        title: 'Daily Summary 🎉',
        body: "Tap to see today's progress and your schedule.",
        scheduledDate: summaryTime,
        channelId: summaryChannel,
        payload: payload,
        fullScreenIntent: false,
        exact: canExact,
      );
      _scheduledIds.add(kDailySummaryNotificationId);
    }
  }

  /// Cancels both start reminder and end-time alarm for a specific task.
  Future<void> cancelTaskNotifications(String taskId) async {
    final startId = NotificationIdGenerator.getNotificationId(
      taskId,
      NotificationType.startReminder,
    );
    final endId = NotificationIdGenerator.getNotificationId(
      taskId,
      NotificationType.endAlarm,
    );

    await gateway.cancel(startId);
    await gateway.cancel(endId);
    _scheduledIds.remove(startId);
    _scheduledIds.remove(endId);
  }

  /// Public accessor for testing: returns all currently scheduled notification IDs.
  Set<int> get scheduledIds => Set.unmodifiable(_scheduledIds);

  String _getSoundSlug(String soundName) {
    return soundName.toLowerCase().replaceAll(' ', '_');
  }
}
