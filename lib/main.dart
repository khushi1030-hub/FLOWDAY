import 'dart:convert';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app/app.dart';
import 'app/router/app_router.dart';
import 'core/database/app_database.dart';
import 'core/notifications/data/local_notification_gateway.dart';
import 'core/providers/database_providers.dart';
import 'core/providers/notification_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SQLite database and SharedPreferences
  final appDb = await AppDatabase.open();
  final prefs = await SharedPreferences.getInstance();

  // Initialize platform notifications
  final notificationGateway = LocalNotificationGateway();
  await notificationGateway.initialize(
    onNotificationSelected: (payload) {
      try {
        final data = jsonDecode(payload);
        final route = data['route'] as String?;
        if (route != null) {
          appRouter.push(route);
        }
      } catch (_) {
        if (payload.startsWith('/')) {
          appRouter.push(payload);
        }
      }
    },
  );

  // Request notifications permission for Android 13+
  await notificationGateway.requestNotificationPermission();

  runApp(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(appDb),
        sharedPreferencesProvider.overrideWithValue(prefs),
        notificationGatewayProvider.overrideWithValue(notificationGateway),
      ],
      child: const FlowDayApp(),
    ),
  );
}
