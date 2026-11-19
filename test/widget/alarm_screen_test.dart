import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flow_day/core/providers/database_providers.dart';
import 'package:flow_day/core/providers/notification_providers.dart';
import 'package:flow_day/core/time/app_clock.dart';
import 'package:flow_day/features/alarms/presentation/alarm_screen.dart';
import 'package:flow_day/features/alarms/presentation/widgets/alarm_swipe_slider.dart';
import 'package:flow_day/features/alarms/presentation/delay_placeholder_screen.dart';
import 'package:flow_day/features/tasks/domain/entities/task.dart';
import '../unit/notification_scheduler_test.dart';

void main() {
  group('Screen 12 AlarmScreen Widget Tests (Requirement 5)', () {
    late FakeNotificationGateway gateway;
    late FakeTaskRepo taskRepo;
    late FakeClock clock;
    late SharedPreferences prefs;

    final baseTime = DateTime(2026, 5, 14, 10, 0); // 10:00 AM

    setUp(() async {
      gateway = FakeNotificationGateway();
      taskRepo = FakeTaskRepo();
      clock = FakeClock(baseTime);

      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();

      await taskRepo.insertTask(Task(
        id: 't-alarm-test',
        title: 'Learn Flutter',
        dateKey: '2026-05-14',
        startMin: 540, // 09:00 AM
        endMin: 600,   // 10:00 AM
        status: 'pending',
        alarmEnabled: true,
        createdAt: baseTime.millisecondsSinceEpoch,
        updatedAt: baseTime.millisecondsSinceEpoch,
      ));
    });

    Widget createTestApp(GoRouter router) {
      return ProviderScope(
        overrides: [
          clockProvider.overrideWithValue(clock),
          taskRepositoryProvider.overrideWithValue(taskRepo),
          notificationGatewayProvider.overrideWithValue(gateway),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: MaterialApp.router(
          routerConfig: router,
        ),
      );
    }

    testWidgets('Renders all Screen 12 elements from design: rings, clock, copy, buttons', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final router = GoRouter(
        initialLocation: '/alarm/t-alarm-test',
        routes: [
          GoRoute(
            path: '/alarm/:taskId',
            builder: (ctx, state) => AlarmScreen(taskId: state.pathParameters['taskId']!),
          ),
        ],
      );

      await tester.pumpWidget(createTestApp(router));
      await tester.pumpAndSettle();

      expect(find.text('FLOWDAY ALARM'), findsOneWidget);
      expect(find.text("Time's up! ⏰"), findsOneWidget);
      expect(find.text('Learn Flutter'), findsOneWidget);
      expect(find.text('Did you complete your task?'), findsOneWidget);
      expect(find.text('< Not completed'), findsOneWidget);
      expect(find.text('Completed >'), findsOneWidget);
      expect(find.text('⌛ Not completed'), findsOneWidget);
      expect(find.text('✓ Completed'), findsOneWidget);
      expect(find.text('⏰ Snooze 5m'), findsOneWidget);
      expect(find.text('+ 10 min'), findsOneWidget);
      expect(find.text('Dismiss'), findsOneWidget);
    });

    testWidgets('Tapping "✓ Completed" marks task completed in repo and navigates', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      var completedRouteVisited = false;

      final router = GoRouter(
        initialLocation: '/alarm/t-alarm-test',
        routes: [
          GoRoute(
            path: '/alarm/:taskId',
            builder: (ctx, state) => AlarmScreen(taskId: state.pathParameters['taskId']!),
          ),
          GoRoute(
            path: '/completed/:taskId',
            builder: (ctx, state) {
              completedRouteVisited = true;
              return const Scaffold(body: Text('Completed Route Screen'));
            },
          ),
        ],
      );

      await tester.pumpWidget(createTestApp(router));
      await tester.pumpAndSettle();

      await tester.tap(find.text('✓ Completed'));
      await tester.pumpAndSettle();

      final updatedTask = await taskRepo.getTaskById('t-alarm-test');
      expect(updatedTask?.status, equals('completed'));
      expect(completedRouteVisited, isTrue);
    });

    testWidgets('Tapping "⌛ Not completed" marks task incomplete and navigates to delay placeholder', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final router = GoRouter(
        initialLocation: '/alarm/t-alarm-test',
        routes: [
          GoRoute(
            path: '/alarm/:taskId',
            builder: (ctx, state) => AlarmScreen(taskId: state.pathParameters['taskId']!),
          ),
          GoRoute(
            path: '/delay/:taskId',
            builder: (ctx, state) => DelayPlaceholderScreen(taskId: state.pathParameters['taskId']!),
          ),
        ],
      );

      await tester.pumpWidget(createTestApp(router));
      await tester.pumpAndSettle();

      await tester.tap(find.text('⌛ Not completed'));
      await tester.pumpAndSettle();

      final updatedTask = await taskRepo.getTaskById('t-alarm-test');
      expect(updatedTask?.status, equals('incomplete'));
      expect(find.text('Delay Management'), findsOneWidget);
      expect(find.text('Back to Schedule'), findsOneWidget);
    });

    testWidgets('Tapping "⏰ Snooze 5m" schedules snooze alarm and pops', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final router = GoRouter(
        initialLocation: '/alarm/t-alarm-test',
        routes: [
          GoRoute(
            path: '/',
            builder: (ctx, state) => const Scaffold(body: Text('Home Root')),
          ),
          GoRoute(
            path: '/alarm/:taskId',
            builder: (ctx, state) => AlarmScreen(taskId: state.pathParameters['taskId']!),
          ),
        ],
      );

      await tester.pumpWidget(createTestApp(router));
      await tester.pumpAndSettle();

      await tester.tap(find.text('⏰ Snooze 5m'));
      await tester.pumpAndSettle();

      expect(gateway.scheduled.isNotEmpty, isTrue);
      expect(find.text('Home Root'), findsOneWidget);
    });

    testWidgets('Tapping "+ 10 min" without conflict extends task and updates repo', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final router = GoRouter(
        initialLocation: '/alarm/t-alarm-test',
        routes: [
          GoRoute(
            path: '/',
            builder: (ctx, state) => const Scaffold(body: Text('Home Root')),
          ),
          GoRoute(
            path: '/alarm/:taskId',
            builder: (ctx, state) => AlarmScreen(taskId: state.pathParameters['taskId']!),
          ),
        ],
      );

      await tester.pumpWidget(createTestApp(router));
      await tester.pumpAndSettle();

      await tester.tap(find.text('+ 10 min'));
      await tester.pumpAndSettle();

      final updatedTask = await taskRepo.getTaskById('t-alarm-test');
      expect(updatedTask?.endMin, equals(610)); // 600 + 10
      expect(find.text('Home Root'), findsOneWidget);
    });

    testWidgets('Tapping "+ 10 min" with overlap shows schedule conflict dialog', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Add conflicting task starting at 605 (overlaps with 600..610)
      await taskRepo.insertTask(Task(
        id: 't-conflict',
        title: 'Team Sync',
        dateKey: '2026-05-14',
        startMin: 605,
        endMin: 650,
        status: 'pending',
        createdAt: baseTime.millisecondsSinceEpoch,
        updatedAt: baseTime.millisecondsSinceEpoch,
      ));

      final router = GoRouter(
        initialLocation: '/alarm/t-alarm-test',
        routes: [
          GoRoute(
            path: '/alarm/:taskId',
            builder: (ctx, state) => AlarmScreen(taskId: state.pathParameters['taskId']!),
          ),
        ],
      );

      await tester.pumpWidget(createTestApp(router));
      await tester.pumpAndSettle();

      await tester.tap(find.text('+ 10 min'));
      await tester.pumpAndSettle();

      // Verified: Conflict dialog appears per Requirement 5
      expect(find.text('Schedule Conflict'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Extend Anyway'), findsOneWidget);
    });

    testWidgets('Swiping slider to the right completes the task and navigates', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      var completedRouteVisited = false;

      final router = GoRouter(
        initialLocation: '/alarm/t-alarm-test',
        routes: [
          GoRoute(
            path: '/alarm/:taskId',
            builder: (ctx, state) => AlarmScreen(taskId: state.pathParameters['taskId']!),
          ),
          GoRoute(
            path: '/completed/:taskId',
            builder: (ctx, state) {
              completedRouteVisited = true;
              return const Scaffold(body: Text('Completed Route Screen'));
            },
          ),
        ],
      );

      await tester.pumpWidget(createTestApp(router));
      await tester.pumpAndSettle();

      // Find slider and drag right
      final sliderFinder = find.byType(AlarmSwipeSlider);
      expect(sliderFinder, findsOneWidget);

      await tester.drag(sliderFinder, const Offset(250, 0));
      await tester.pumpAndSettle();

      expect(completedRouteVisited, isTrue);
      final updated = await taskRepo.getTaskById('t-alarm-test');
      expect(updated?.status, 'completed');
    });

    testWidgets('Swiping slider to the left delays the task and navigates to delay placeholder', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      var delayRouteVisited = false;

      final router = GoRouter(
        initialLocation: '/alarm/t-alarm-test',
        routes: [
          GoRoute(
            path: '/alarm/:taskId',
            builder: (ctx, state) => AlarmScreen(taskId: state.pathParameters['taskId']!),
          ),
          GoRoute(
            path: '/delay/:taskId',
            builder: (ctx, state) {
              delayRouteVisited = true;
              return const Scaffold(body: Text('Delay Route Screen'));
            },
          ),
        ],
      );

      await tester.pumpWidget(createTestApp(router));
      await tester.pumpAndSettle();

      final sliderFinder = find.byType(AlarmSwipeSlider);
      expect(sliderFinder, findsOneWidget);

      await tester.drag(sliderFinder, const Offset(-250, 0));
      await tester.pumpAndSettle();

      expect(delayRouteVisited, isTrue);
      final updated = await taskRepo.getTaskById('t-alarm-test');
      expect(updated?.status, 'incomplete');
    });
  });
}
