import '../entities/app_settings.dart';

/// Repository interface for app settings persistence.
abstract class SettingsRepository {
  Future<AppSettings> getSettings();
  Stream<AppSettings> watchSettings();
  Future<void> updateSettings(AppSettings settings);
  Future<void> resetAll();
}
