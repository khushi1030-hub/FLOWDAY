import 'dart:async';

/// Notification type identifier for generating stable notification IDs.
enum NotificationType {
  startReminder(1),
  endAlarm(2);

  const NotificationType(this.offset);
  final int offset;
}

/// Abstract contract for scheduling and managing platform notifications.
///
/// Inversion of Control interface so tests can use [FakeNotificationGateway]
/// without touching Android native plugins.
abstract class NotificationGateway {
  /// Initializes notification channels and listeners.
  Future<void> initialize({
    required void Function(String payload) onNotificationSelected,
  });

  /// Requests notification display permission (POST_NOTIFICATIONS on Android 13+).
  Future<bool> requestNotificationPermission();

  /// Checks if notifications are enabled for the application.
  Future<bool> areNotificationsEnabled();

  /// Checks if exact alarms can be scheduled (Android 12+ / 14+).
  Future<bool> canScheduleExactAlarms();

  /// Checks if full-screen intents can be displayed (Android 14+).
  Future<bool> canUseFullScreenIntent();

  /// Schedules a notification at the given wall-clock [scheduledDate].
  Future<void> scheduleZonedNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    required String channelId,
    String? payload,
    bool fullScreenIntent = false,
    bool exact = true,
  });

  /// Cancels a specific notification by [id].
  Future<void> cancel(int id);

  /// Cancels all notifications scheduled by this gateway.
  Future<void> cancelAll();

  /// Returns list of all pending notification IDs.
  Future<List<int>> getPendingNotificationIds();

  /// Opens the system exact alarms settings page for this app.
  Future<void> openExactAlarmSettings();
}
