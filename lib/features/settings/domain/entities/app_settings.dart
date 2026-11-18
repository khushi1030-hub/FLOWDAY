/// Domain entity representing persistent user and system settings.
class AppSettings {
  const AppSettings({
    this.onboardingDone = false,
    this.userName = '',
    this.avatarPath,
    this.wakeMin = 420, // 07:00 AM
    this.sleepMin = 1380, // 11:00 PM (23:00)
    this.dayStartMin = 420,
    this.dayEndMin = 1380,
    this.workStartMin = 540, // 09:00 AM
    this.workEndMin = 1080, // 06:00 PM
    this.defaultBreakMin = 15,
    this.nightlyReviewEnabled = true,
    this.nightlyReviewMin = 1290, // 21:30 (09:30 PM) per D6
    this.dailySummaryEnabled = true,
    this.dailySummaryMin = 1230, // 20:30 (08:30 PM) per D12
    this.taskAlarmsEnabled = true,
    this.notificationSound = 'Soft Chime',
    this.alarmVibrate = false,
    this.focusAmbience = 'rain',
    this.focusSilenceEnabled = false,
    this.defaultFocusMinutes = 25,
    this.themeMode = 'dark',
    this.defaultReminderOffset = 10,
  });

  final bool onboardingDone;
  final String userName;
  final String? avatarPath;
  final int wakeMin;
  final int sleepMin;
  final int dayStartMin;
  final int dayEndMin;
  final int workStartMin;
  final int workEndMin;
  final int defaultBreakMin;
  final bool nightlyReviewEnabled;
  final int nightlyReviewMin;
  final bool dailySummaryEnabled;
  final int dailySummaryMin;
  final bool taskAlarmsEnabled;
  final String notificationSound;
  final bool alarmVibrate;
  final String focusAmbience;
  final bool focusSilenceEnabled;
  final int defaultFocusMinutes;
  final String themeMode;
  final int defaultReminderOffset;

  AppSettings copyWith({
    bool? onboardingDone,
    String? userName,
    String? avatarPath,
    int? wakeMin,
    int? sleepMin,
    int? dayStartMin,
    int? dayEndMin,
    int? workStartMin,
    int? workEndMin,
    int? defaultBreakMin,
    bool? nightlyReviewEnabled,
    int? nightlyReviewMin,
    bool? dailySummaryEnabled,
    int? dailySummaryMin,
    bool? taskAlarmsEnabled,
    String? notificationSound,
    bool? alarmVibrate,
    String? focusAmbience,
    bool? focusSilenceEnabled,
    int? defaultFocusMinutes,
    String? themeMode,
    int? defaultReminderOffset,
  }) {
    return AppSettings(
      onboardingDone: onboardingDone ?? this.onboardingDone,
      userName: userName ?? this.userName,
      avatarPath: avatarPath ?? this.avatarPath,
      wakeMin: wakeMin ?? this.wakeMin,
      sleepMin: sleepMin ?? this.sleepMin,
      dayStartMin: dayStartMin ?? this.dayStartMin,
      dayEndMin: dayEndMin ?? this.dayEndMin,
      workStartMin: workStartMin ?? this.workStartMin,
      workEndMin: workEndMin ?? this.workEndMin,
      defaultBreakMin: defaultBreakMin ?? this.defaultBreakMin,
      nightlyReviewEnabled: nightlyReviewEnabled ?? this.nightlyReviewEnabled,
      nightlyReviewMin: nightlyReviewMin ?? this.nightlyReviewMin,
      dailySummaryEnabled: dailySummaryEnabled ?? this.dailySummaryEnabled,
      dailySummaryMin: dailySummaryMin ?? this.dailySummaryMin,
      taskAlarmsEnabled: taskAlarmsEnabled ?? this.taskAlarmsEnabled,
      notificationSound: notificationSound ?? this.notificationSound,
      alarmVibrate: alarmVibrate ?? this.alarmVibrate,
      focusAmbience: focusAmbience ?? this.focusAmbience,
      focusSilenceEnabled: focusSilenceEnabled ?? this.focusSilenceEnabled,
      defaultFocusMinutes: defaultFocusMinutes ?? this.defaultFocusMinutes,
      themeMode: themeMode ?? this.themeMode,
      defaultReminderOffset: defaultReminderOffset ?? this.defaultReminderOffset,
    );
  }
}
