import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../domain/notification_gateway.dart';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  // Handled when user taps a notification action in background.
}

/// Concrete [NotificationGateway] backed by [FlutterLocalNotificationsPlugin] and [timezone].
class LocalNotificationGateway implements NotificationGateway {
  LocalNotificationGateway({
    FlutterLocalNotificationsPlugin? plugin,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  void Function(String payload)? _onNotificationSelected;
  bool _initialized = false;

  AndroidFlutterLocalNotificationsPlugin? get _androidPlugin {
    try {
      return _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> initialize({
    required void Function(String payload) onNotificationSelected,
  }) async {
    if (_initialized) return;
    _onNotificationSelected = onNotificationSelected;

    // Initialize time zone database and detect local device zone
    try {
      tz.initializeTimeZones();
      final timeZoneInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneInfo.identifier));
    } catch (_) {
      try {
        tz.setLocalLocation(tz.getLocation('UTC'));
      } catch (_) {}
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings();

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );

    try {
      await _plugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (response) {
          final payload = response.payload;
          if (payload != null && payload.isNotEmpty) {
            _onNotificationSelected?.call(payload);
          }
        },
        onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
      );

      // Create default channels with max importance and alarm attributes
      await _createDefaultChannels();

      // Handle launch from notification when app was closed/terminated
      final launchDetails = await _plugin.getNotificationAppLaunchDetails();
      if (launchDetails?.didNotificationLaunchApp ?? false) {
        final payload = launchDetails?.notificationResponse?.payload;
        if (payload != null && payload.isNotEmpty) {
          Future.microtask(() => _onNotificationSelected?.call(payload));
        }
      }
    } catch (e) {
      debugPrint('LocalNotificationGateway.initialize caught: $e');
    }

    _initialized = true;
  }

  Future<void> _createDefaultChannels() async {
    final android = _androidPlugin;
    if (android == null) return;
    try {
      const soundSlugs = [
        'soft_chime',
        'crystal_bell',
        'morning_breeze',
        'lofi_piano',
        'default',
      ];
      for (final slug in soundSlugs) {
        final soundResource = slug == 'default'
            ? null
            : RawResourceAndroidNotificationSound(slug);

        final alarmChannel = AndroidNotificationChannel(
          'flowday_alarms_$slug',
          'Task Alarms',
          description: 'Alarms and full-screen alerts when task time ends',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          audioAttributesUsage: AudioAttributesUsage.alarm,
          sound: soundResource,
        );
        await android.createNotificationChannel(alarmChannel);

        final reminderChannel = AndroidNotificationChannel(
          'flowday_reminders_$slug',
          'Task Reminders',
          description: 'Reminders before scheduled tasks start',
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
          sound: soundResource,
        );
        await android.createNotificationChannel(reminderChannel);
      }

      const summaryChannel = AndroidNotificationChannel(
        'flowday_summary',
        'Daily Summary',
        description: 'Evening review and daily schedule summary',
        importance: Importance.high,
        playSound: true,
      );
      await android.createNotificationChannel(summaryChannel);
    } catch (e) {
      debugPrint('LocalNotificationGateway._createDefaultChannels caught: $e');
    }
  }

  @override
  Future<bool> requestNotificationPermission() async {
    try {
      if (_androidPlugin != null) {
        final granted = await _androidPlugin!.requestNotificationsPermission();
        return granted ?? false;
      }
    } catch (_) {}
    return true;
  }

  @override
  Future<bool> areNotificationsEnabled() async {
    try {
      if (_androidPlugin != null) {
        final enabled = await _androidPlugin!.areNotificationsEnabled();
        return enabled ?? true;
      }
    } catch (_) {}
    return true;
  }

  @override
  Future<bool> canScheduleExactAlarms() async {
    try {
      if (_androidPlugin != null) {
        final canExact = await _androidPlugin!.canScheduleExactNotifications();
        return canExact ?? true;
      }
    } catch (_) {}
    return true;
  }

  @override
  Future<bool> canUseFullScreenIntent() async {
    return true;
  }

  @override
  Future<void> openExactAlarmSettings() async {
    try {
      if (_androidPlugin != null) {
        await _androidPlugin!.requestExactAlarmsPermission();
      }
    } catch (_) {}
  }

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
    try {
      final tzScheduledDate = tz.TZDateTime.from(scheduledDate, tz.local);

      final soundSlug = _extractSoundSlug(channelId);
      final soundResource = (soundSlug != null && soundSlug != 'default')
          ? RawResourceAndroidNotificationSound(soundSlug)
          : null;

      final androidDetails = AndroidNotificationDetails(
        channelId,
        _getChannelName(channelId),
        channelDescription: _getChannelDescription(channelId),
        importance: fullScreenIntent ? Importance.max : Importance.high,
        priority: fullScreenIntent ? Priority.max : Priority.high,
        fullScreenIntent: fullScreenIntent,
        category: fullScreenIntent ? AndroidNotificationCategory.alarm : null,
        visibility: NotificationVisibility.public,
        audioAttributesUsage: fullScreenIntent
            ? AudioAttributesUsage.alarm
            : AudioAttributesUsage.notification,
        playSound: true,
        enableVibration: true,
        sound: soundResource,
        actions: fullScreenIntent
            ? const [
                AndroidNotificationAction(
                  'action_done',
                  'Done',
                  showsUserInterface: true,
                ),
              ]
            : null,
      );

      const darwinDetails = DarwinNotificationDetails();

      final details = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
      );

      final scheduleMode = exact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle;

      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tzScheduledDate,
        notificationDetails: details,
        androidScheduleMode: scheduleMode,
        payload: payload,
      );
    } catch (e) {
      debugPrint('LocalNotificationGateway.scheduleZonedNotification caught: $e');
    }
  }

  @override
  Future<void> cancel(int id) async {
    try {
      await _plugin.cancel(id: id);
    } catch (_) {}
  }

  @override
  Future<void> cancelAll() async {
    try {
      await _plugin.cancelAll();
    } catch (_) {}
  }

  @override
  Future<List<int>> getPendingNotificationIds() async {
    try {
      final pending = await _plugin.pendingNotificationRequests();
      return pending.map((p) => p.id).toList();
    } catch (_) {
      return [];
    }
  }

  String? _extractSoundSlug(String channelId) {
    const slugs = ['soft_chime', 'crystal_bell', 'morning_breeze', 'lofi_piano', 'default'];
    for (final slug in slugs) {
      if (channelId.endsWith(slug)) return slug;
    }
    return null;
  }

  String _getChannelName(String channelId) {
    if (channelId.startsWith('flowday_alarms')) return 'Task Alarms';
    if (channelId.startsWith('flowday_reminders')) return 'Task Reminders';
    if (channelId.startsWith('flowday_summary')) return 'Daily Summary';
    return 'FlowDay Notifications';
  }

  String _getChannelDescription(String channelId) {
    if (channelId.startsWith('flowday_alarms')) {
      return 'Alarms and full-screen alerts when task time ends';
    }
    if (channelId.startsWith('flowday_reminders')) {
      return 'Reminders before scheduled tasks start';
    }
    if (channelId.startsWith('flowday_summary')) {
      return 'Evening review and daily schedule summary';
    }
    return 'FlowDay Notifications';
  }
}
