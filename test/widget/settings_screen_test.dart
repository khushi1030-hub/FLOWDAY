import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flow_day/core/providers/database_providers.dart';
import 'package:flow_day/core/providers/notification_providers.dart';
import 'package:flow_day/features/settings/presentation/settings_screen.dart';
import '../unit/notification_scheduler_test.dart';

void main() {
  group('SettingsScreen Widget Tests (Requirement 10, 11, 12)', () {
    late FakeNotificationGateway gateway;
    late SharedPreferences prefs;

    setUp(() async {
      gateway = FakeNotificationGateway();
      SharedPreferences.setMockInitialValues({
        'task_alarms_enabled': true,
        'daily_summary_enabled': true,
        'alarm_vibrate': false,
      });
      prefs = await SharedPreferences.getInstance();
    });

    Widget createTestApp() {
      return ProviderScope(
        overrides: [
          notificationGatewayProvider.overrideWithValue(gateway),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const MaterialApp(
          home: SettingsScreen(),
        ),
      );
    }

    testWidgets('Renders notification toggles and battery optimization guidance', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('NOTIFICATIONS & ALARMS'), findsOneWidget);
      expect(find.text('Task Alarms'), findsOneWidget);
      expect(find.text('Daily Summary'), findsOneWidget);
      expect(find.text('Alarm Vibrate'), findsOneWidget);

      expect(find.text('RELIABLE ALARMS & BATTERY'), findsOneWidget);
      expect(find.text('Battery Optimization Guidance'), findsOneWidget);
      expect(find.textContaining('Samsung One UI'), findsOneWidget);
      expect(find.text('Open Battery Optimization Settings'), findsOneWidget);
    });

    testWidgets('When exact alarms are unavailable, renders warning banner (Requirement 10)', (tester) async {
      gateway.canScheduleExact = false; // Simulate Android 14+ revoked exact alarm permission

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Exact Alarms Disabled'), findsOneWidget);
      expect(find.text('Allow Exact Alarms'), findsOneWidget);
    });
  });
}
