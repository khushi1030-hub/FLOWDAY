import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/database_providers.dart';
import '../../../core/providers/notification_providers.dart';
import '../../../core/services/alarm_window_service.dart';
import '../../../core/theme/flow_colors.dart';
import '../../../core/theme/flow_radii.dart';
import '../../../core/theme/flow_spacing.dart';
import '../../../core/theme/flow_typography.dart';
import '../domain/entities/app_settings.dart';

/// Screen 24: Settings Screen.
///
/// Houses the Phase 7 Notification & Alarm settings, exact alarm guidance,
/// Samsung battery optimization instructions, and persistence toggles.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _canExact = true;
  bool _checkedExact = false;
  bool _notificationsEnabled = true;
  bool _checkedNotifications = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    try {
      final gateway = ref.read(notificationGatewayProvider);
      final canExact = await gateway.canScheduleExactAlarms();
      final notificationsEnabled = await gateway.areNotificationsEnabled();
      if (mounted) {
        setState(() {
          _canExact = canExact;
          _checkedExact = true;
          _notificationsEnabled = notificationsEnabled;
          _checkedNotifications = true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _checkedExact = true;
          _checkedNotifications = true;
        });
      }
    }
  }

  Future<void> _requestNotificationPermission() async {
    final gateway = ref.read(notificationGatewayProvider);
    await gateway.requestNotificationPermission();
    await _checkPermissions();
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsStateProvider);
    final settings = settingsAsync.value ?? const AppSettings();
    final settingsRepo = ref.read(settingsRepositoryProvider);

    return Scaffold(
      backgroundColor: FlowColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Settings', style: FlowTypography.headlineLarge),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: FlowSpacing.space16,
          vertical: FlowSpacing.space8,
        ),
        children: [
          // Guidance Warning Banner if Exact Alarms are Disabled (Requirement 10)
          if (_checkedExact && !_canExact) ...[
            Container(
              margin: const EdgeInsets.only(bottom: FlowSpacing.space16),
              padding: const EdgeInsets.all(FlowSpacing.space16),
              decoration: BoxDecoration(
                color: FlowColors.warningContainer,
                borderRadius: BorderRadius.circular(FlowRadii.squircle),
                border: Border.all(color: FlowColors.warningBorder, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: FlowColors.warning, size: 22),
                      SizedBox(width: FlowSpacing.space8),
                      Text(
                        'Exact Alarms Disabled',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: FlowColors.warning,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: FlowSpacing.space8),
                  const Text(
                    'Alarms may be delayed by the Android battery optimizer because exact alarms are not permitted. Tap below to allow exact alarms in system settings.',
                    style: TextStyle(fontSize: 13, color: FlowColors.textSecondary, height: 1.4),
                  ),
                  const SizedBox(height: FlowSpacing.space12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FlowColors.warning,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(FlowRadii.pill),
                        ),
                      ),
                      icon: const Icon(Icons.settings_outlined, size: 18),
                      label: const Text('Allow Exact Alarms', style: TextStyle(fontWeight: FontWeight.w700)),
                      onPressed: () async {
                        final gateway = ref.read(notificationGatewayProvider);
                        await gateway.openExactAlarmSettings();
                        await _checkPermissions();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Guidance Warning Banner if Notification Permission is Disabled
          if (_checkedNotifications && !_notificationsEnabled) ...[
            Container(
              margin: const EdgeInsets.only(bottom: FlowSpacing.space16),
              padding: const EdgeInsets.all(FlowSpacing.space16),
              decoration: BoxDecoration(
                color: FlowColors.errorContainer,
                borderRadius: BorderRadius.circular(FlowRadii.squircle),
                border: Border.all(color: FlowColors.error.withValues(alpha: 0.5), width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.notifications_off_rounded, color: FlowColors.error, size: 22),
                      SizedBox(width: FlowSpacing.space8),
                      Text(
                        'Notifications Disabled',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: FlowColors.error,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: FlowSpacing.space8),
                  const Text(
                    'FlowDay cannot sound alarms, ring tones, or show alerts when your phone is locked unless notifications are permitted. Tap below to enable them.',
                    style: TextStyle(fontSize: 13, color: FlowColors.textSecondary, height: 1.4),
                  ),
                  const SizedBox(height: FlowSpacing.space12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FlowColors.error,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(FlowRadii.pill),
                        ),
                      ),
                      icon: const Icon(Icons.notifications_active_rounded, size: 18),
                      label: const Text('Enable Notifications', style: TextStyle(fontWeight: FontWeight.w700)),
                      onPressed: _requestNotificationPermission,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // SECTION: NOTIFICATIONS & ALARMS
          const Text(
            'NOTIFICATIONS & ALARMS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: FlowColors.textSecondary,
            ),
          ),
          const SizedBox(height: FlowSpacing.space12),

          Material(
            color: FlowColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(FlowRadii.squircle),
              side: const BorderSide(color: FlowColors.surfaceBorder, width: 1),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Task Alarms', style: FlowTypography.bodyLarge),
                  subtitle: const Text('Sound alarm when task scheduled time ends', style: FlowTypography.bodySmall),
                  value: settings.taskAlarmsEnabled,
                  activeTrackColor: FlowColors.primary,
                  onChanged: (val) async {
                    await settingsRepo.updateSettings(settings.copyWith(taskAlarmsEnabled: val));
                  },
                ),
                const Divider(height: 1, color: FlowColors.surfaceBorder),
                SwitchListTile(
                  title: const Text('Daily Summary', style: FlowTypography.bodyLarge),
                  subtitle: const Text('Evening summary of planned & completed tasks', style: FlowTypography.bodySmall),
                  value: settings.dailySummaryEnabled,
                  activeTrackColor: FlowColors.primary,
                  onChanged: (val) async {
                    await settingsRepo.updateSettings(settings.copyWith(dailySummaryEnabled: val));
                  },
                ),
                const Divider(height: 1, color: FlowColors.surfaceBorder),
                SwitchListTile(
                  title: const Text('Alarm Vibrate', style: FlowTypography.bodyLarge),
                  subtitle: const Text('Vibrate phone when alarm sounds', style: FlowTypography.bodySmall),
                  value: settings.alarmVibrate,
                  activeTrackColor: FlowColors.primary,
                  onChanged: (val) async {
                    await settingsRepo.updateSettings(settings.copyWith(alarmVibrate: val));
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: FlowSpacing.space24),

          // SECTION: BATTERY OPTIMIZATION & RELIABLE ALARMS (Requirement 11)
          const Text(
            'RELIABLE ALARMS & BATTERY',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: FlowColors.textSecondary,
            ),
          ),
          const SizedBox(height: FlowSpacing.space12),

          Container(
            padding: const EdgeInsets.all(FlowSpacing.space16),
            decoration: BoxDecoration(
              color: FlowColors.surface,
              borderRadius: BorderRadius.circular(FlowRadii.squircle),
              border: Border.all(color: FlowColors.surfaceBorder, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.battery_charging_full_rounded, color: FlowColors.success, size: 22),
                    SizedBox(width: FlowSpacing.space8),
                    Text(
                      'Battery Optimization Guidance',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: FlowColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: FlowSpacing.space8),
                const Text(
                  'Some manufacturers (Samsung, Xiaomi) aggressively kill background alarms.\n\n'
                  '• Samsung One UI:\nGo to Settings → Apps → FlowDay → Battery → select "Unrestricted", or Device Care → Battery → Background usage limits → Add to "Never sleeping apps".',
                  style: FlowTypography.bodySmall,
                ),
                const SizedBox(height: FlowSpacing.space16),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: FlowColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(FlowRadii.pill),
                    ),
                  ),
                  icon: const Icon(Icons.open_in_new_rounded, size: 16, color: FlowColors.primary),
                  label: const Text('Open Battery Optimization Settings', style: TextStyle(color: FlowColors.primary)),
                  onPressed: () {
                    AlarmWindowService.openBatteryOptimizationSettings();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: FlowSpacing.space24),
        ],
      ),
    );
  }
}
