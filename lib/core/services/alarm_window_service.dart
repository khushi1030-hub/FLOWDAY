import 'package:flutter/services.dart';

/// Platform bridge for managing Android lockscreen presentation flags
/// and battery optimization settings.
class AlarmWindowService {
  static const MethodChannel _channel =
      MethodChannel('com.example.flow_day/alarm_window');

  /// Turns the screen on and displays over keyguard when the alarm triggers.
  static Future<void> turnScreenOnAndShowWhenLocked() async {
    try {
      await _channel.invokeMethod('turnScreenOnAndShowWhenLocked');
    } catch (_) {}
  }

  /// Clears lockscreen flags when dismissing or leaving the alarm screen.
  static Future<void> resetScreenFlags() async {
    try {
      await _channel.invokeMethod('resetScreenFlags');
    } catch (_) {}
  }

  /// Opens the system battery optimization apps list.
  static Future<void> openBatteryOptimizationSettings() async {
    try {
      await _channel.invokeMethod('openBatteryOptimizationSettings');
    } catch (_) {}
  }
}
