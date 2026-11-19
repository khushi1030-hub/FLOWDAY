import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flow_day/core/notifications/domain/notification_gateway.dart';
import 'package:flow_day/core/notifications/domain/notification_id_generator.dart';
import 'package:flow_day/core/notifications/domain/notification_scheduler.dart';
import 'package:flow_day/core/time/app_clock.dart';
import 'package:flow_day/features/settings/domain/entities/app_settings.dart';
import 'package:flow_day/features/settings/domain/repositories/settings_repository.dart';
import 'package:flow_day/features/tasks/domain/entities/task.dart';
import 'package:flow_day/features/tasks/domain/repositories/task_repository.dart';

class ScheduledRecord {
  ScheduledRecord({
    required this.id,
    required this.title,
    required this.body,
    required this.scheduledDate,
    required this.channelId,
    this.payload,
    this.fullScreenIntent = false,
    this.exact = true,
  });

  final int id;
  final String title;
  final String body;
  final DateTime scheduledDate;
  final String channelId;
  final String? payload;
  final bool fullScreenIntent;
  final bool exact;
}

class FakeNotificationGateway implements NotificationGateway {
  final Map<int, ScheduledRecord> scheduled = {};
  bool canScheduleExact = true;
  bool canFullScreen = true;

  @override
  Future<void> initialize({
    required void Function(String payload) onNotificationSelected,
  }) async {}

  @override
  Future<bool> requestNotificationPermission() async => true;

  @override
  Future<bool> areNotificationsEnabled() async => true;

  @override
  Future<bool> canScheduleExactAlarms() async => canScheduleExact;

  @override
  Future<bool> canUseFullScreenIntent() async => canFullScreen;

  @override
  Future<void> openExactAlarmSettings() async {}

  @override
  Future<void> scheduleZonedNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    required String channelId,
    String? payload,
    bool fullScreenIntent = false,
    bool exact = true,
  }) async {
    scheduled[id] = ScheduledRecord(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      channelId: channelId,
      payload: payload,
      fullScreenIntent: fullScreenIntent,
      exact: exact,
    );
  }

  @override
  Future<void> cancel(int id) async {
    scheduled.remove(id);
  }

  @override
  Future<void> cancelAll() async {
    scheduled.clear();
  }

  @override
  Future<List<int>> getPendingNotificationIds() async => scheduled.keys.toList();
}

class FakeTaskRepo implements TaskRepository {
  final List<Task> _tasks = [];
  final _controller = StreamController<List<Task>>.broadcast();

  @override
  Future<Task?> getTaskById(String id) async {
    try {
      return _tasks.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Task>> getTasksForDate(String dateKey) async {
    return _tasks.where((t) => t.dateKey == dateKey).toList();
  }

  @override
  Stream<List<Task>> watchTasksForDate(String dateKey) async* {
    yield await getTasksForDate(dateKey);
  }

  @override
  Stream<List<Task>> watchAllTasks() => _controller.stream;

  @override
  Future<List<Task>> getAllTasks() async => List.of(_tasks);

  @override
  Future<void> insertTask(Task task) async {
    _tasks.add(task);
    _controller.add(List.of(_tasks));
  }

  @override
  Future<void> updateTask(Task task) async {
    final idx = _tasks.indexWhere((t) => t.id == task.id);
    if (idx != -1) {
      _tasks[idx] = task;
      _controller.add(List.of(_tasks));
    }
  }

  @override
  Future<void> deleteTask(String id) async {
    _tasks.removeWhere((t) => t.id == id);
    _controller.add(List.of(_tasks));
  }

  @override
  Future<void> markCompleted(String id, int completedAt) async {
    final idx = _tasks.indexWhere((t) => t.id == id);
    if (idx != -1) {
      _tasks[idx] = _tasks[idx].copyWith(status: 'completed', completedAt: completedAt);
      _controller.add(List.of(_tasks));
    }
  }

  @override
  Future<void> markIncomplete(String id) async {
    final idx = _tasks.indexWhere((t) => t.id == id);
    if (idx != -1) {
      _tasks[idx] = _tasks[idx].copyWith(status: 'incomplete');
      _controller.add(List.of(_tasks));
    }
  }

  @override
  Future<void> deleteAll() async {
    _tasks.clear();
    _controller.add(List.of(_tasks));
  }
}

class FakeSettingsRepo implements SettingsRepository {
  AppSettings _settings = const AppSettings();
  final _controller = StreamController<AppSettings>.broadcast();

  @override
  Future<AppSettings> getSettings() async => _settings;

  @override
  Stream<AppSettings> watchSettings() => _controller.stream;

  @override
  Future<void> updateSettings(AppSettings settings) async {
    _settings = settings;
    _controller.add(_settings);
  }

  @override
  Future<void> resetAll() async {
    _settings = const AppSettings();
    _controller.add(_settings);
  }
}

void main() {
  group('NotificationScheduler Domain Tests (Phase 7)', () {
    late FakeNotificationGateway gateway;
    late FakeTaskRepo taskRepo;
    late FakeSettingsRepo settingsRepo;
    late FakeClock clock;
    late NotificationScheduler scheduler;

    final baseTime = DateTime(2026, 5, 14, 9, 0); // 09:00 AM (minute 540)

    setUp(() {
      gateway = FakeNotificationGateway();
      taskRepo = FakeTaskRepo();
      settingsRepo = FakeSettingsRepo();
      clock = FakeClock(baseTime);

      scheduler = NotificationScheduler(
        gateway: gateway,
        taskRepository: taskRepo,
        settingsRepository: settingsRepo,
        clock: clock,
      );
    });

    test('resyncAll() schedules start reminder and end alarm for upcoming pending tasks', () async {
      await taskRepo.insertTask(Task(
        id: 't-1',
        title: 'Learn Flutter',
        dateKey: '2026-05-14',
        startMin: 600, // 10:00 AM
        endMin: 660,   // 11:00 AM
        status: 'pending',
        reminderOffsetMin: 15,
        alarmEnabled: true,
        createdAt: baseTime.millisecondsSinceEpoch,
        updatedAt: baseTime.millisecondsSinceEpoch,
      ));

      await scheduler.resyncAll();

      final startId = NotificationIdGenerator.getNotificationId('t-1', NotificationType.startReminder);
      final endId = NotificationIdGenerator.getNotificationId('t-1', NotificationType.endAlarm);

      expect(gateway.scheduled.containsKey(startId), isTrue);
      expect(gateway.scheduled.containsKey(endId), isTrue);

      final startRecord = gateway.scheduled[startId]!;
      expect(startRecord.scheduledDate, equals(DateTime(2026, 5, 14, 9, 45))); // 10:00 - 15m
      expect(startRecord.title, contains('Learn Flutter'));

      final endRecord = gateway.scheduled[endId]!;
      expect(endRecord.scheduledDate, equals(DateTime(2026, 5, 14, 11, 0)));
      expect(endRecord.fullScreenIntent, isTrue);
    });

    test('resyncAll() excludes completed, skipped, and incomplete tasks (Requirement 8)', () async {
      // Completed task
      await taskRepo.insertTask(Task(
        id: 't-comp',
        title: 'Completed Task',
        dateKey: '2026-05-14',
        startMin: 600,
        endMin: 660,
        status: 'completed',
        reminderOffsetMin: 10,
        alarmEnabled: true,
        createdAt: baseTime.millisecondsSinceEpoch,
        updatedAt: baseTime.millisecondsSinceEpoch,
      ));

      // Skipped task
      await taskRepo.insertTask(Task(
        id: 't-skip',
        title: 'Skipped Task',
        dateKey: '2026-05-14',
        startMin: 700,
        endMin: 760,
        status: 'skipped',
        reminderOffsetMin: 10,
        alarmEnabled: true,
        createdAt: baseTime.millisecondsSinceEpoch,
        updatedAt: baseTime.millisecondsSinceEpoch,
      ));

      // Incomplete task
      await taskRepo.insertTask(Task(
        id: 't-incomp',
        title: 'Incomplete Task',
        dateKey: '2026-05-14',
        startMin: 800,
        endMin: 860,
        status: 'incomplete',
        reminderOffsetMin: 10,
        alarmEnabled: true,
        createdAt: baseTime.millisecondsSinceEpoch,
        updatedAt: baseTime.millisecondsSinceEpoch,
      ));

      await scheduler.resyncAll();

      // None of the task IDs should be scheduled
      expect(gateway.scheduled.containsKey(NotificationIdGenerator.getNotificationId('t-comp', NotificationType.endAlarm)), isFalse);
      expect(gateway.scheduled.containsKey(NotificationIdGenerator.getNotificationId('t-skip', NotificationType.endAlarm)), isFalse);
      expect(gateway.scheduled.containsKey(NotificationIdGenerator.getNotificationId('t-incomp', NotificationType.endAlarm)), isFalse);
    });

    test('resyncAll() schedules rescheduled tasks if in the future', () async {
      await taskRepo.insertTask(Task(
        id: 't-resched',
        title: 'Rescheduled Meeting',
        dateKey: '2026-05-14',
        startMin: 720, // 12:00 PM
        endMin: 780,
        status: 'rescheduled',
        reminderOffsetMin: 10,
        alarmEnabled: true,
        createdAt: baseTime.millisecondsSinceEpoch,
        updatedAt: baseTime.millisecondsSinceEpoch,
      ));

      await scheduler.resyncAll();

      final endId = NotificationIdGenerator.getNotificationId('t-resched', NotificationType.endAlarm);
      expect(gateway.scheduled.containsKey(endId), isTrue);
    });

    test('resyncAll() is completely idempotent (running twice produces identical set)', () async {
      await taskRepo.insertTask(Task(
        id: 't-idem',
        title: 'Idempotent Task',
        dateKey: '2026-05-14',
        startMin: 600,
        endMin: 660,
        status: 'pending',
        reminderOffsetMin: 10,
        alarmEnabled: true,
        createdAt: baseTime.millisecondsSinceEpoch,
        updatedAt: baseTime.millisecondsSinceEpoch,
      ));

      await scheduler.resyncAll();
      final set1 = Set<int>.from(gateway.scheduled.keys);

      await scheduler.resyncAll();
      final set2 = Set<int>.from(gateway.scheduled.keys);

      expect(set1, equals(set2));
    });

    test('cancelTaskNotifications() removes start reminder and end alarm immediately', () async {
      await taskRepo.insertTask(Task(
        id: 't-cancel',
        title: 'To Be Cancelled',
        dateKey: '2026-05-14',
        startMin: 600,
        endMin: 660,
        status: 'pending',
        reminderOffsetMin: 10,
        alarmEnabled: true,
        createdAt: baseTime.millisecondsSinceEpoch,
        updatedAt: baseTime.millisecondsSinceEpoch,
      ));

      await scheduler.resyncAll();
      final endId = NotificationIdGenerator.getNotificationId('t-cancel', NotificationType.endAlarm);
      expect(gateway.scheduled.containsKey(endId), isTrue);

      await scheduler.cancelTaskNotifications('t-cancel');
      expect(gateway.scheduled.containsKey(endId), isFalse);
    });

    test('Daily summary notification schedules with static body and wraps midnight safely (Requirement 9)', () async {
      // Set daily summary to 20:30 (1230 min)
      await settingsRepo.updateSettings(const AppSettings(
        dailySummaryEnabled: true,
        dailySummaryMin: 1230,
      ));

      await scheduler.resyncAll();

      expect(gateway.scheduled.containsKey(kDailySummaryNotificationId), isTrue);
      final summary = gateway.scheduled[kDailySummaryNotificationId]!;
      expect(summary.title, equals('Daily Summary 🎉'));
      expect(summary.body, equals("Tap to see today's progress and your schedule.")); // Static text
      expect(summary.scheduledDate.hour, equals(20));
      expect(summary.scheduledDate.minute, equals(30));
    });

    test('Channel names honor sound choice (Requirement 2)', () async {
      await settingsRepo.updateSettings(const AppSettings(
        notificationSound: 'Morning Breeze',
      ));

      await taskRepo.insertTask(Task(
        id: 't-sound',
        title: 'Sound Test Task',
        dateKey: '2026-05-14',
        startMin: 600,
        endMin: 660,
        status: 'pending',
        alarmEnabled: true,
        createdAt: baseTime.millisecondsSinceEpoch,
        updatedAt: baseTime.millisecondsSinceEpoch,
      ));

      await scheduler.resyncAll();

      final endId = NotificationIdGenerator.getNotificationId('t-sound', NotificationType.endAlarm);
      expect(gateway.scheduled[endId]!.channelId, equals('flowday_alarms_morning_breeze'));
    });
  });
}
