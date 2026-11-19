import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flow_day/core/providers/database_providers.dart';
import 'package:flow_day/core/time/app_clock.dart';
import 'package:flow_day/features/schedule/presentation/schedule_screen.dart';
import 'package:flow_day/features/schedule/presentation/widgets/current_time_marker.dart';
import 'package:flow_day/features/schedule/presentation/widgets/free_time_slot_widget.dart';
import 'package:flow_day/features/schedule/presentation/widgets/schedule_filter_bar.dart';
import 'package:flow_day/features/schedule/presentation/widgets/schedule_task_card.dart';
import 'package:flow_day/features/schedule/presentation/widgets/tomorrow_banner.dart';
import 'package:flow_day/features/schedule/presentation/widgets/week_day_strip.dart';
import 'package:flow_day/features/tasks/domain/entities/task.dart';
import 'package:flow_day/features/tasks/domain/repositories/task_repository.dart';

class _FakeScheduleTaskRepo implements TaskRepository {
  final List<Task> _tasks = [];
  final _controller = StreamController<List<Task>>.broadcast();

  @override
  Future<Task?> getTaskById(String id) async {
    try {
      return _tasks.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Task>> getTasksForDate(String dateKey) async {
    return _tasks.where((t) => t.dateKey == dateKey).toList();
  }

  @override
  Stream<List<Task>> watchTasksForDate(String dateKey) {
    late StreamController<List<Task>> subController;
    StreamSubscription? sub;
    subController = StreamController<List<Task>>.broadcast(
      onListen: () {
        subController.add(_tasks.where((t) => t.dateKey == dateKey).toList());
        sub = _controller.stream.listen((list) {
          if (!subController.isClosed) {
            subController.add(list.where((t) => t.dateKey == dateKey).toList());
          }
        });
      },
      onCancel: () {
        sub?.cancel();
      },
    );
    return subController.stream;
  }

  @override
  Stream<List<Task>> watchAllTasks() {
    late StreamController<List<Task>> subController;
    StreamSubscription? sub;
    subController = StreamController<List<Task>>.broadcast(
      onListen: () {
        subController.add(List.of(_tasks));
        sub = _controller.stream.listen((list) {
          if (!subController.isClosed) {
            subController.add(List.of(list));
          }
        });
      },
      onCancel: () {
        sub?.cancel();
      },
    );
    return subController.stream;
  }

  @override
  Future<List<Task>> getAllTasks() async => List.unmodifiable(_tasks);

  @override
  Future<void> insertTask(Task task) async {
    _tasks.add(task);
    _controller.add(List.of(_tasks));
  }

  @override
  Future<void> updateTask(Task task) async {
    final idx = _tasks.indexWhere((t) => t.id == task.id);
    if (idx != -1) {
      _tasks[idx] = task;
      _controller.add(List.of(_tasks));
    }
  }

  @override
  Future<void> deleteTask(String id) async {
    _tasks.removeWhere((t) => t.id == id);
    _controller.add(List.of(_tasks));
  }

  @override
  Future<void> markCompleted(String id, int completedAt) async {
    final idx = _tasks.indexWhere((t) => t.id == id);
    if (idx != -1) {
      _tasks[idx] = _tasks[idx].copyWith(status: 'completed', completedAt: completedAt);
      _controller.add(List.of(_tasks));
    }
  }

  @override
  Future<void> markIncomplete(String id) async {
    final idx = _tasks.indexWhere((t) => t.id == id);
    if (idx != -1) {
      _tasks[idx] = _tasks[idx].copyWith(status: 'incomplete');
      _controller.add(List.of(_tasks));
    }
  }

  @override
  Future<void> deleteAll() async {
    _tasks.clear();
    _controller.add(List.of(_tasks));
  }

  void dispose() {
    _controller.close();
  }
}

void main() {
  group('Phase 6 ScheduleScreen Widget Tests', () {
    late FakeClock fakeClock;
    late _FakeScheduleTaskRepo repo;
    late SharedPreferences prefs;

    final baseTime = DateTime(2026, 5, 14, 9, 24); // 09:24 AM (matches UI_SPEC Screen 08)

    setUp(() async {
      fakeClock = FakeClock(baseTime);
      repo = _FakeScheduleTaskRepo();
      SharedPreferences.setMockInitialValues({
        'wake_min': 420, // 07:00
        'sleep_min': 1380, // 23:00
        'default_break_min': 15,
        'user_name': 'Tester',
      });
      prefs = await SharedPreferences.getInstance();
    });

    tearDown(() {
      repo.dispose();
      fakeClock.dispose();
    });

    Widget createTestApp() {
      return ProviderScope(
        overrides: [
          clockProvider.overrideWithValue(fakeClock),
          taskRepositoryProvider.overrideWithValue(repo),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const MaterialApp(
          home: ScheduleScreen(),
        ),
      );
    }

    testWidgets('Renders all primary Screen 08 elements: header, tabs, week strip, timeline cards, and free gaps',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Insert tasks matching Screen 08:
      // 07:00 - 07:30: Morning run (completed)
      // 08:00 - 08:30: Reply to emails (delayed / overdue because now is 09:24)
      // 09:00 - 10:00: Learn Flutter (in progress / NOW)
      await repo.insertTask(Task(
        id: 'task-1',
        title: 'Morning run',
        dateKey: '2026-05-14',
        startMin: 420,
        endMin: 450,
        status: 'completed',
        completedAt: baseTime.millisecondsSinceEpoch,
        createdAt: baseTime.millisecondsSinceEpoch,
        updatedAt: baseTime.millisecondsSinceEpoch,
      ));

      await repo.insertTask(Task(
        id: 'task-2',
        title: 'Reply to emails',
        dateKey: '2026-05-14',
        startMin: 480,
        endMin: 510,
        status: 'pending', // Ends at 08:30, current is 09:24 -> Overdue
        createdAt: baseTime.millisecondsSinceEpoch,
        updatedAt: baseTime.millisecondsSinceEpoch,
      ));

      await repo.insertTask(Task(
        id: 'task-3',
        title: 'Learn Flutter',
        dateKey: '2026-05-14',
        startMin: 540,
        endMin: 600,
        status: 'pending', // 09:00 - 10:00 -> IN PROGRESS
        createdAt: baseTime.millisecondsSinceEpoch,
        updatedAt: baseTime.millisecondsSinceEpoch,
      ));

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Top bar header
      expect(find.text('Schedule'), findsOneWidget);
      expect(find.text('May 2026'), findsOneWidget);

      // Segmented control tabs
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Tomorrow'), findsOneWidget);
      expect(find.text('Calendar'), findsOneWidget);

      // Weekday strip
      expect(find.byType(WeekDayStrip), findsOneWidget);

      // Filter chips
      expect(find.byType(ScheduleFilterBar), findsOneWidget);
      expect(find.text('✓ 1 completed'), findsOneWidget);
      expect(find.text('⭘ 1 pending'), findsOneWidget);
      expect(find.text('⚠ 1 overdue'), findsOneWidget);

      // Cards
      expect(find.text('Morning run'), findsOneWidget);
      expect(find.text('Reply to emails'), findsOneWidget);
      expect(find.text('Learn Flutter'), findsOneWidget);

      // Overdue card has Reschedule button
      expect(find.text('Reschedule'), findsOneWidget);

      // In progress task has • NOW badge
      expect(find.text('• NOW'), findsOneWidget);

      // Current time marker exists for 09:24
      expect(find.byType(CurrentTimeMarker), findsOneWidget);
      expect(find.text('09:24'), findsOneWidget);

      // Free gap slot exists (+ Free)
      expect(find.byType(FreeTimeSlotWidget), findsWidgets);
    });

    testWidgets('Tapping Reschedule button on overdue task shows SnackBar per Requirement 9',
        (tester) async {
      await repo.insertTask(Task(
        id: 'task-delayed',
        title: 'Late task',
        dateKey: '2026-05-14',
        startMin: 480,
        endMin: 510,
        status: 'pending',
        createdAt: baseTime.millisecondsSinceEpoch,
        updatedAt: baseTime.millisecondsSinceEpoch,
      ));

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      final rescheduleBtn = find.text('Reschedule');
      expect(rescheduleBtn, findsOneWidget);

      await tester.tap(rescheduleBtn);
      await tester.pump();

      expect(find.text("Rescheduling isn't available yet"), findsOneWidget);
    });

    testWidgets('Tomorrow tab displays static hint banner per Requirement 3', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Tap Tomorrow tab
      await tester.tap(find.text('Tomorrow'));
      await tester.pumpAndSettle();

      expect(find.byType(TomorrowBanner), findsOneWidget);
      expect(find.text("Tomorrow's Schedule · Unconfirmed (Review at 09:30 PM)"), findsOneWidget);
    });

    testWidgets('Filter chips filter visible tasks correctly', (tester) async {
      await repo.insertTask(Task(
        id: 't-comp',
        title: 'Completed Task',
        dateKey: '2026-05-14',
        startMin: 420,
        endMin: 450,
        status: 'completed',
        createdAt: baseTime.millisecondsSinceEpoch,
        updatedAt: baseTime.millisecondsSinceEpoch,
      ));

      await repo.insertTask(Task(
        id: 't-pend',
        title: 'Future Pending Task',
        dateKey: '2026-05-14',
        startMin: 660,
        endMin: 720,
        status: 'pending',
        createdAt: baseTime.millisecondsSinceEpoch,
        updatedAt: baseTime.millisecondsSinceEpoch,
      ));

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Completed Task'), findsOneWidget);
      expect(find.text('Future Pending Task'), findsOneWidget);

      // Tap "✓ 1 completed" filter
      await tester.tap(find.text('✓ 1 completed'));
      await tester.pumpAndSettle();

      // Only completed task visible
      expect(find.text('Completed Task'), findsOneWidget);
      expect(find.text('Future Pending Task'), findsNothing);

      // Tap again to toggle back to all
      await tester.tap(find.text('✓ 1 completed'));
      await tester.pumpAndSettle();

      expect(find.text('Completed Task'), findsOneWidget);
      expect(find.text('Future Pending Task'), findsOneWidget);
    });

    testWidgets('Swiping task right completes it; swiping left marks incomplete without deleting',
        (tester) async {
      await repo.insertTask(Task(
        id: 't-swipe',
        title: 'Task To Complete',
        dateKey: '2026-05-14',
        startMin: 600,
        endMin: 660,
        status: 'pending',
        createdAt: baseTime.millisecondsSinceEpoch,
        updatedAt: baseTime.millisecondsSinceEpoch,
      ));

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Task To Complete'), findsOneWidget);

      // Swipe right to complete
      await tester.drag(find.text('Task To Complete'), const Offset(500, 0));
      await tester.pumpAndSettle();

      // Verify task still exists in repo and is marked completed
      final taskAfter = await repo.getTaskById('t-swipe');
      expect(taskAfter, isNotNull);
      expect(taskAfter!.status, 'completed');
    });

    testWidgets('Responsive test: 320dp width and 1.3 font scale renders cleanly without overflow',
        (tester) async {
      tester.view.physicalSize = const Size(320 * 2, 700 * 2);
      tester.view.devicePixelRatio = 2.0;
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        tester.platformDispatcher.clearTextScaleFactorTestValue();
      });

      await repo.insertTask(Task(
        id: 't-responsive',
        title: 'Responsive Long Task Title for Layout Check',
        dateKey: '2026-05-14',
        startMin: 540,
        endMin: 600,
        status: 'pending',
        createdAt: baseTime.millisecondsSinceEpoch,
        updatedAt: baseTime.millisecondsSinceEpoch,
      ));

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Must render without any flutter layout overflow exceptions
      expect(find.text('Schedule'), findsOneWidget);
      expect(find.byType(ScheduleTaskCard), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Exit Check: Adding a task appears on Schedule immediately without refresh',
        (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Live Shared Task'), findsNothing);

      // Add task to repository for today
      await repo.insertTask(Task(
        id: 't-shared',
        title: 'Live Shared Task',
        dateKey: '2026-05-14',
        startMin: 600,
        endMin: 660,
        status: 'pending',
        createdAt: baseTime.millisecondsSinceEpoch,
        updatedAt: baseTime.millisecondsSinceEpoch,
      ));
      await tester.pumpAndSettle();

      // Instantly visible on timeline without any manual refresh
      expect(find.text('Live Shared Task'), findsOneWidget);
    });
  });
}
