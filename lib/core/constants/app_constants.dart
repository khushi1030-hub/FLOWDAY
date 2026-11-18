/// Global application constants.
class AppConstants {
  AppConstants._();

  static const String appName = 'FlowDay';
  static const String appTagline = 'Plan smart · Stay flexible · Flow better';
  static const String appVersion = 'v1.0.0';

  // Default rhythm preferences (in minutes from midnight)
  static const int defaultWakeMin = 420; // 07:00 AM
  static const int defaultSleepMin = 1380; // 11:00 PM
  static const int defaultWorkStartMin = 540; // 09:00 AM
  static const int defaultWorkEndMin = 1080; // 06:00 PM
  static const int defaultBreakMin = 15; // 15 minutes
  static const int defaultNightlyReviewMin = 1290; // 09:30 PM (21:30) per Decision D6
  static const int defaultDailySummaryMin = 1230; // 08:30 PM per Decision D12
}
