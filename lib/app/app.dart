import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_constants.dart';
import '../core/providers/database_providers.dart';
import '../core/providers/notification_providers.dart';
import '../core/theme/flow_theme.dart';
import 'router/app_router.dart';

/// Root application widget configuring theme, router, and lifecycle listeners.
class FlowDayApp extends ConsumerStatefulWidget {
  const FlowDayApp({super.key});

  @override
  ConsumerState<FlowDayApp> createState() => _FlowDayAppState();
}

class _FlowDayAppState extends ConsumerState<FlowDayApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Start listening to task/setting changes and perform initial resync
      final scheduler = ref.read(notificationSchedulerProvider);
      scheduler.startListening();
      scheduler.resyncAll();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    ref.read(foregroundAlarmManagerProvider).updateLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      // Resync on app resume per Requirement 7
      ref.read(notificationSchedulerProvider).resyncAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to minute ticks for foreground alarm checks
    ref.listen(minuteTickProvider, (_, _) {
      ref.read(foregroundAlarmManagerProvider).checkMinuteTick();
    });

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: FlowTheme.darkTheme,
      routerConfig: appRouter,
    );
  }
}
