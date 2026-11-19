import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import '../shell/scaffold_with_nav_bar.dart';
import '../../core/theme/flow_colors.dart';
import '../../core/theme/flow_typography.dart';
import '../../core/widgets/flow_buttons.dart';
import '../../features/dev/components_gallery_screen.dart';
import '../../features/dev/database_debug_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/onboarding/presentation/splash_screen.dart';
import '../../features/onboarding/presentation/intro_screen.dart';
import '../../features/onboarding/presentation/personalize_screen.dart';
import '../../features/onboarding/presentation/permissions_screen.dart';
import '../../features/tasks/presentation/edit_task_screen.dart';
import '../../features/tasks/presentation/new_task_screen.dart';
import '../../features/tasks/presentation/task_completed_screen.dart';
import '../../features/schedule/presentation/schedule_screen.dart';
import '../../features/schedule/presentation/calendar_screen.dart';
import '../../features/alarms/presentation/alarm_screen.dart';
import '../../features/delay/presentation/unfinished_adjust_screen.dart';
import '../../features/rescheduling/presentation/reschedule_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/tasks/domain/entities/task.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _homeNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'home');
final GlobalKey<NavigatorState> _scheduleNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'schedule');
final GlobalKey<NavigatorState> _insightsNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'insights');
final GlobalKey<NavigatorState> _settingsNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'settings');

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/splash',
  routes: [
    // ShellRoute with 4 bottom navigation tabs
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return ScaffoldWithNavBar(navigationShell: navigationShell);
      },
      branches: [
        // Tab 0: Home
        StatefulShellBranch(
          navigatorKey: _homeNavigatorKey,
          routes: [
            GoRoute(
              path: '/home',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: HomeScreen(),
              ),
            ),
          ],
        ),

        // Tab 1: Schedule
        StatefulShellBranch(
          navigatorKey: _scheduleNavigatorKey,
          routes: [
            GoRoute(
              path: '/schedule',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: ScheduleScreen(),
              ),
            ),
          ],
        ),

        // Tab 2: Insights
        StatefulShellBranch(
          navigatorKey: _insightsNavigatorKey,
          routes: [
            GoRoute(
              path: '/insights',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: _PlaceholderTabScreen(
                  title: 'Insights',
                  subtitle: 'Productivity & Habits (Screen 23)',
                  icon: Icons.bar_chart_rounded,
                  hasHistoryAction: true,
                ),
              ),
            ),
          ],
        ),

        // Tab 3: Settings
        StatefulShellBranch(
          navigatorKey: _settingsNavigatorKey,
          routes: [
            GoRoute(
              path: '/settings',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: SettingsScreen(),
              ),
            ),
          ],
        ),
      ],
    ),

    // Dev Component Gallery
    GoRoute(
      path: '/dev/components',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ComponentsGalleryScreen(),
    ),

    // Dev Database Debug Screen (Phase 2 persistence test)
    GoRoute(
      path: '/dev/database',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const DatabaseDebugScreen(),
    ),

    // Screen 01: Splash Screen
    GoRoute(
      path: '/splash',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const SplashScreen(),
    ),

    // Screens 02, 03, 04: Intro Pager
    GoRoute(
      path: '/onboarding/1',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const IntroScreen(initialPage: 0),
    ),
    GoRoute(
      path: '/onboarding/2',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const IntroScreen(initialPage: 1),
    ),
    GoRoute(
      path: '/onboarding/3',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const IntroScreen(initialPage: 2),
    ),

    // Screen 05: Personalize Your Flow
    GoRoute(
      path: '/onboarding/personalize',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const PersonalizeScreen(),
    ),

    // Screen 06: Notification Permissions
    GoRoute(
      path: '/onboarding/permissions',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const PermissionsScreen(),
    ),
    GoRoute(
      path: '/task/new',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final date = state.uri.queryParameters['date'];
        final start = int.tryParse(state.uri.queryParameters['start'] ?? '');
        final end = int.tryParse(state.uri.queryParameters['end'] ?? '');
        return NewTaskScreen(
          initialDateKey: date,
          initialStartMin: start,
          initialEndMin: end,
        );
      },
    ),
    GoRoute(
      path: '/task/:id/edit',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return EditTaskScreen(taskId: id);
      },
    ),
    GoRoute(
      path: '/focus/:taskId',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => _SimpleRoutePlaceholder('Focus Mode: ${state.pathParameters['taskId']} (11)'),
    ),
    GoRoute(
      path: '/alarm/:taskId',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final taskId = state.pathParameters['taskId'] ?? '';
        return AlarmScreen(taskId: taskId);
      },
    ),
    GoRoute(
      path: '/completed/:taskId',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final taskId = state.pathParameters['taskId'] ?? '';
        return TaskCompletedScreen(taskId: taskId);
      },
    ),
    GoRoute(
      path: '/delay/:taskId',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final taskId = state.pathParameters['taskId'] ?? '';
        return UnfinishedAdjustScreen(taskId: taskId);
      },
    ),
    GoRoute(
      path: '/reschedule',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final queryTaskId = state.uri.queryParameters['taskId'];
        final queryExtraMin = int.tryParse(state.uri.queryParameters['extraMinutes'] ?? '');
        final queryDateKey = state.uri.queryParameters['dateKey'];

        Task? newConflictingTask;
        String? taskId = queryTaskId;
        int extraMinutes = queryExtraMin ?? 30;
        String? dateKey = queryDateKey;

        if (state.extra is Task) {
          newConflictingTask = state.extra as Task;
        } else if (state.extra is Map<String, dynamic>) {
          final map = state.extra as Map<String, dynamic>;
          newConflictingTask = map['newConflictingTask'] as Task?;
          taskId = map['taskId'] as String? ?? taskId;
          extraMinutes = map['extraMinutes'] as int? ?? extraMinutes;
          dateKey = map['dateKey'] as String? ?? dateKey;
        }

        return RescheduleScreen(
          taskId: taskId,
          extraMinutes: extraMinutes,
          newConflictingTask: newConflictingTask,
          dateKey: dateKey,
        );
      },
    ),
    GoRoute(
      path: '/review/:dateKey',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => _SimpleRoutePlaceholder('Nightly Review: ${state.pathParameters['dateKey']} (18)'),
    ),
    GoRoute(
      path: '/review/:dateKey/done',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => _SimpleRoutePlaceholder('Schedule Confirmed (20)'),
    ),
    GoRoute(
      path: '/schedule/calendar',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const CalendarScreen(),
    ),
    GoRoute(
      path: '/history',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const _SimpleRoutePlaceholder('Task History (22)'),
    ),
  ],
);

/// Placeholder for tab root screens with direct button to open the Component Gallery.
class _PlaceholderTabScreen extends StatelessWidget {
  const _PlaceholderTabScreen({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.hasHistoryAction = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool hasHistoryAction;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FlowColors.background,
      appBar: AppBar(
        backgroundColor: FlowColors.background,
        elevation: 0,
        title: Text(title, style: FlowTypography.headlineLarge),
        actions: [
          if (hasHistoryAction)
            IconButton(
              icon: const Icon(Icons.history_rounded, color: FlowColors.primaryLight),
              tooltip: 'Task History',
              onPressed: () => context.push('/history'),
            ),
          IconButton(
            icon: const Icon(Icons.storage_rounded, color: FlowColors.primaryLight),
            tooltip: 'Open /dev/database',
            onPressed: () => context.push('/dev/database'),
          ),
          IconButton(
            icon: const Icon(Icons.palette_outlined, color: FlowColors.primaryLight),
            tooltip: 'Open /dev/components',
            onPressed: () => context.push('/dev/components'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: FlowColors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: FlowColors.primary.withValues(alpha: 0.3), width: 1.5),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 38, color: FlowColors.primaryLight),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: FlowTypography.headlineLarge,
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: FlowTypography.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              FlowPrimaryButton(
                label: '+ Create New Task (/task/new)',
                icon: const Icon(Icons.add_task_rounded, color: Colors.white, size: 20),
                onPressed: () => context.push('/task/new'),
              ),
              const SizedBox(height: 12),
              FlowSecondaryButton(
                label: 'Open Design Gallery (/dev/components)',
                icon: const Icon(Icons.palette_rounded, color: FlowColors.primaryLight, size: 20),
                onPressed: () => context.push('/dev/components'),
              ),
              const SizedBox(height: 12),
              FlowSecondaryButton(
                label: 'Open Task & DB Manager (/dev/database)',
                icon: const Icon(Icons.storage_rounded, color: FlowColors.primaryLight, size: 18),
                onPressed: () => context.push('/dev/database'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SimpleRoutePlaceholder extends StatelessWidget {
  const _SimpleRoutePlaceholder(this.name);
  final String name;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FlowColors.background,
      appBar: AppBar(
        backgroundColor: FlowColors.background,
        title: Text(name, style: FlowTypography.titleMedium),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: Center(
        child: Text(name, style: FlowTypography.headlineMedium),
      ),
    );
  }
}
