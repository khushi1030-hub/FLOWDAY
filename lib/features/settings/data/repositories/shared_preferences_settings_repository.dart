import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/repositories/settings_repository.dart';

/// SharedPreferences implementation of [SettingsRepository].
class SharedPreferencesSettingsRepository implements SettingsRepository {
  SharedPreferencesSettingsRepository(this._prefs);

  final SharedPreferences _prefs;
  final _settingsController = StreamController<AppSettings>.broadcast();

  // Keys
  static const _kOnboardingDone = 'onboarding_done';
  static const _kUserName = 'user_name';
  static const _kAvatarPath = 'avatar_path';
  static const _kWakeMin = 'wake_min';
  static const _kSleepMin = 'sleep_min';
  static const _kDayStartMin = 'day_start_min';
  static const _kDayEndMin = 'day_end_min';
  static const _kWorkStartMin = 'work_start_min';
  static const _kWorkEndMin = 'work_end_min';
  static const _kDefaultBreakMin = 'default_break_min';
  static const _kNightlyReviewEnabled = 'nightly_review_enabled';
  static const _kNightlyReviewMin = 'nightly_review_min';
  static const _kDailySummaryEnabled = 'daily_summary_enabled';
  static const _kDailySummaryMin = 'daily_summary_min';
  static const _kTaskAlarmsEnabled = 'task_alarms_enabled';
  static const _kNotificationSound = 'notification_sound';
  static const _kAlarmVibrate = 'alarm_vibrate';
  static const _kFocusAmbience = 'focus_ambience';
  static const _kFocusSilenceEnabled = 'focus_silence_enabled';
  static const _kDefaultFocusMinutes = 'default_focus_minutes';
  static const _kThemeMode = 'theme_mode';
  static const _kDefaultReminderOffset = 'default_reminder_offset';

  @override
  Future<AppSettings> getSettings() async {
    return AppSettings(
      onboardingDone: _prefs.getBool(_kOnboardingDone) ?? false,
      userName: _prefs.getString(_kUserName) ?? '',
      avatarPath: _prefs.getString(_kAvatarPath),
      wakeMin: _prefs.getInt(_kWakeMin) ?? 420,
      sleepMin: _prefs.getInt(_kSleepMin) ?? 1380,
      dayStartMin: _prefs.getInt(_kDayStartMin) ?? 420,
      dayEndMin: _prefs.getInt(_kDayEndMin) ?? 1380,
      workStartMin: _prefs.getInt(_kWorkStartMin) ?? 540,
      workEndMin: _prefs.getInt(_kWorkEndMin) ?? 1080,
      defaultBreakMin: _prefs.getInt(_kDefaultBreakMin) ?? 15,
      nightlyReviewEnabled: _prefs.getBool(_kNightlyReviewEnabled) ?? true,
      nightlyReviewMin: _prefs.getInt(_kNightlyReviewMin) ?? 1290, // 21:30 per D6
      dailySummaryEnabled: _prefs.getBool(_kDailySummaryEnabled) ?? true,
      dailySummaryMin: _prefs.getInt(_kDailySummaryMin) ?? 1230, // 20:30 per D12
      taskAlarmsEnabled: _prefs.getBool(_kTaskAlarmsEnabled) ?? true,
      notificationSound: _prefs.getString(_kNotificationSound) ?? 'Soft Chime',
      alarmVibrate: _prefs.getBool(_kAlarmVibrate) ?? false,
      focusAmbience: _prefs.getString(_kFocusAmbience) ?? 'rain',
      focusSilenceEnabled: _prefs.getBool(_kFocusSilenceEnabled) ?? false,
      defaultFocusMinutes: _prefs.getInt(_kDefaultFocusMinutes) ?? 25,
      themeMode: _prefs.getString(_kThemeMode) ?? 'dark',
      defaultReminderOffset: _prefs.getInt(_kDefaultReminderOffset) ?? 10,
    );
  }

  @override
  Stream<AppSettings> watchSettings() async* {
    yield await getSettings();
    yield* _settingsController.stream;
  }

  @override
  Future<void> updateSettings(AppSettings settings) async {
    await _prefs.setBool(_kOnboardingDone, settings.onboardingDone);
    await _prefs.setString(_kUserName, settings.userName);
    if (settings.avatarPath != null) {
      await _prefs.setString(_kAvatarPath, settings.avatarPath!);
    } else {
      await _prefs.remove(_kAvatarPath);
    }
    await _prefs.setInt(_kWakeMin, settings.wakeMin);
    await _prefs.setInt(_kSleepMin, settings.sleepMin);
    await _prefs.setInt(_kDayStartMin, settings.dayStartMin);
    await _prefs.setInt(_kDayEndMin, settings.dayEndMin);
    await _prefs.setInt(_kWorkStartMin, settings.workStartMin);
    await _prefs.setInt(_kWorkEndMin, settings.workEndMin);
    await _prefs.setInt(_kDefaultBreakMin, settings.defaultBreakMin);
    await _prefs.setBool(_kNightlyReviewEnabled, settings.nightlyReviewEnabled);
    await _prefs.setInt(_kNightlyReviewMin, settings.nightlyReviewMin);
    await _prefs.setBool(_kDailySummaryEnabled, settings.dailySummaryEnabled);
    await _prefs.setInt(_kDailySummaryMin, settings.dailySummaryMin);
    await _prefs.setBool(_kTaskAlarmsEnabled, settings.taskAlarmsEnabled);
    await _prefs.setString(_kNotificationSound, settings.notificationSound);
    await _prefs.setBool(_kAlarmVibrate, settings.alarmVibrate);
    await _prefs.setString(_kFocusAmbience, settings.focusAmbience);
    await _prefs.setBool(_kFocusSilenceEnabled, settings.focusSilenceEnabled);
    await _prefs.setInt(_kDefaultFocusMinutes, settings.defaultFocusMinutes);
    await _prefs.setString(_kThemeMode, settings.themeMode);
    await _prefs.setInt(_kDefaultReminderOffset, settings.defaultReminderOffset);

    if (!_settingsController.isClosed) {
      _settingsController.add(settings);
    }
  }

  @override
  Future<void> resetAll() async {
    await _prefs.clear();
    final defaultSettings = const AppSettings();
    if (!_settingsController.isClosed) {
      _settingsController.add(defaultSettings);
    }
  }

  void dispose() {
    _settingsController.close();
  }
}
