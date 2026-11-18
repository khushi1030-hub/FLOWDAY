import 'package:material_ui/material_ui.dart';
import '../core/constants/app_constants.dart';
import '../core/theme/flow_theme.dart';
import 'router/app_router.dart';

/// Root application widget configuring theme and GoRouter.
class FlowDayApp extends StatelessWidget {
  const FlowDayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: FlowTheme.darkTheme,
      routerConfig: appRouter,
    );
  }
}
