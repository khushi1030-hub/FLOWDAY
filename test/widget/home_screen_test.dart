import 'dart:async';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flow_day/core/providers/database_providers.dart';
import 'package:flow_day/core/time/app_clock.dart';
import 'package:flow_day/features/home/presentation/home_screen.dart';
import 'package:flow_day/features/home/presentation/providers/home_providers.dart';
import 'package:flow_day/features/home/presentation/widgets/now_task_card.dart';
import 'package:flow_day/features/tasks/domain/entities/task.dart';
import 'package:flow_day/features/tasks/domain/repositories/task_repository.dart';
import 'package:flow_day/features/tasks/presentation/widgets/swipeable_task_card.dart';

class FakeHomeTaskRepository implements TaskRepository {
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

  void notifyAll() {
    _controller.add(List.of(_tasks));
  }
}

class _FailingStreamRepo implements TaskRepository {
  _FailingStreamRepo(this._stream);
  final Stream<List<Task>> _stream;

  @override
  Stream<List<Task>> watchTasksForDate(String dateKey) => _stream;

  @override
  Future<Task?> getTaskById(String id) async => null;

  @override
  Future<List<Task>> getTasksForDate(String dateKey) async => [];

  @override
  Future<List<Task>> getAllTasks() async => [];

  @override
  Future<void> insertTask(Task task) async {}

  @override
  Future<void> updateTask(Task task) async {}

  @override
  Future<void> deleteTask(String id) async {}

  @override
  Future<void> markCompleted(String id, int completedAt) async {}

  @override
  Future<void> markIncomplete(String id) async {}

  @override
  Future<void> deleteAll() async {}
}

void main() {
  group('Phase 5 HomeScreen Widget Tests', () {
    late FakeClock fakeClock;
    late FakeHomeTaskRepository taskRepo;
    late SharedPreferences prefs;

    const today = '2026-11-19';
    final fixedNow = DateTime(2026, 11, 19, 10, 0); // 10:00 AM

    setUp(() async {
      fakeClock = FakeClock(fixedNow);
      SharedPreferences.setMockInitialValues({
        'user_name': 'Khushi',
        'wake_min': 420,
        'sleep_min': 1380,
        'onboarding_done': true,
      });
      prefs = await SharedPreferences.getInstance();
      taskRepo = FakeHomeTaskRepository();
    });

    Widget createTestWidget() {
      return ProviderScope(
        overrides: [
          clockProvider.overrideWithValue(fakeClock),
          sharedPreferencesProvider.overrideWithValue(prefs),
          taskRepositoryProvider.overrideWithValue(taskRepo),
        ],
        child: const MaterialApp(
          home: HomeScreen(),
        ),
      );
    }

    testWidgets('Empty day shows friendly empty state with action', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestWidget());
      taskRepo.notifyAll();
      await tester.pumpAndSettle();

      // Top bar check
      expect(find.text('Good Morning, Khushi! ☀️'), findsOneWidget);
      expect(find.text('K'), findsOneWidget); // Initials avatar

      // Empty state
      expect(find.text('No tasks scheduled'), findsWidgets);
      expect(find.text('+ Add First Task'), findsOneWidget);
      expect(find.byType(NowTaskCard), findsNothing);
    });

    testWidgets('Tapping bell shows "Notifications coming soon" SnackBar', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestWidget());
      taskRepo.notifyAll();
      await tester.pumpAndSettle();

      final bellBtn = find.byIcon(Icons.notifications_none_rounded);
      expect(bellBtn, findsOneWidget);
      await tester.tap(bellBtn);
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Notifications coming soon'), findsOneWidget);
    });

    testWidgets('Complete a task via swipe right -> ring & counts update immediately (Exit Check 1)', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // 2 tasks: Task 1 (in-progress 09:30-10:30), Task 2 (upcoming 11:00-12:00)
      final task1 = Task(
        id: 'task-1',
        title: 'Learn Flutter',
        dateKey: today,
        startMin: 570, // 09:30
        endMin: 630, // 10:30
        createdAt: 1000,
        updatedAt: 1000,
      );
      final task2 = Task(
        id: 'task-2',
        title: 'Practice DSA',
        dateKey: today,
        startMin: 660, // 11:00
        endMin: 720, // 12:00
        createdAt: 1000,
        updatedAt: 1000,
      );
      await taskRepo.insertTask(task1);
      await taskRepo.insertTask(task2);

      await tester.pumpWidget(createTestWidget());
      taskRepo.notifyAll();
      await tester.pumpAndSettle();

      // Initial state: 0 of 2 tasks completed (0%)
      expect(find.text('0 of 2 tasks\ncompleted'), findsOneWidget);
      expect(find.text('0%'), findsOneWidget);
      expect(find.text('2'), findsOneWidget); // Remaining = 2

      // Swipe right on "Learn Flutter" in timeline list to complete it
      final timelineCard = find.descendant(
        of: find.byType(SwipeableTaskCard),
        matching: find.text('Learn Flutter'),
      );
      expect(timelineCard, findsOneWidget);
      await tester.drag(timelineCard, const Offset(500, 0));
      await tester.pumpAndSettle();

      // VERIFY IMMEDIATE REACTIVE UPDATE: 1 of 2 tasks completed (50%)
      expect(find.text('1 of 2 tasks\ncompleted'), findsOneWidget);
      expect(find.text('50%'), findsOneWidget);
      expect(find.text('1'), findsWidgets); // Done = 1, Remaining = 1
    });

    testWidgets('Swipe left marks task incomplete and preserves task in list', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final task = Task(
        id: 'task-incomplete',
        title: 'Draft Project Specs',
        dateKey: today,
        startMin: 660,
        endMin: 720,
        createdAt: 1000,
        updatedAt: 1000,
      );
      await taskRepo.insertTask(task);

      await tester.pumpWidget(createTestWidget());
      taskRepo.notifyAll();
      await tester.pumpAndSettle();

      // Swipe left on task
      final taskCard = find.descendant(
        of: find.byType(SwipeableTaskCard),
        matching: find.text('Draft Project Specs'),
      );
      await tester.drag(taskCard, const Offset(-500, 0));
      await tester.pumpAndSettle();

      // Task must STILL be in the list
      expect(find.text('Draft Project Specs'), findsWidgets);

      // Phase 8 adjust toast must appear
      expect(find.text('Adjust task: Smart rescheduling coming in Phase 8'), findsOneWidget);

      // Verify in repository: status is incomplete, not deleted
      final repoTask = await taskRepo.getTaskById('task-incomplete');
      expect(repoTask, isNotNull);
      expect(repoTask!.status, 'incomplete');
    });

    testWidgets('Tapping "Mark done" on NOW card updates ring and counts immediately', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // 1 task in progress (09:30 - 10:30, now is 10:00 = 600 min)
      final task = Task(
        id: 'task-active',
        title: 'Learn Flutter',
        dateKey: today,
        startMin: 570,
        endMin: 630,
        createdAt: 1000,
        updatedAt: 1000,
      );
      await taskRepo.insertTask(task);

      await tester.pumpWidget(createTestWidget());
      taskRepo.notifyAll();
      await tester.pumpAndSettle();

      // Verify NOW card is visible
      expect(find.byType(NowTaskCard), findsOneWidget);
      expect(find.text('0 of 1 tasks\ncompleted'), findsOneWidget);

      // Find and tap "Mark done" on NOW card
      final markDoneBtn = find.text('Mark done');
      expect(markDoneBtn, findsOneWidget);
      await tester.tap(markDoneBtn);
      await tester.pumpAndSettle();

      // Counts and ring updated immediately!
      expect(find.text('1 of 1 tasks\ncompleted'), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);
      final updated = await taskRepo.getTaskById('task-active');
      expect(updated?.isCompleted, isTrue);
    });

    testWidgets('All-done state displays 100% ring, completed badge, and motivational subtitle', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final task1 = Task(
        id: 't-done-1',
        title: 'Morning Workout',
        dateKey: today,
        startMin: 420,
        endMin: 480,
        status: 'completed',
        completedAt: 1000,
        createdAt: 1000,
        updatedAt: 1000,
      );
      final task2 = Task(
        id: 't-done-2',
        title: 'Meditation Session',
        dateKey: today,
        startMin: 480,
        endMin: 510,
        status: 'completed',
        completedAt: 1000,
        createdAt: 1000,
        updatedAt: 1000,
      );
      await taskRepo.insertTask(task1);
      await taskRepo.insertTask(task2);

      await tester.pumpWidget(createTestWidget());
      taskRepo.notifyAll();
      await tester.pumpAndSettle();

      expect(find.text('100%'), findsOneWidget);
      expect(find.text('• Completed'), findsOneWidget);
      expect(find.text("All tasks completed! You're flowing great today 🎉"), findsOneWidget);
      expect(find.text('2 of 2 tasks\ncompleted'), findsOneWidget);
      expect(find.text('2'), findsWidgets); // DONE: 2
      expect(find.text('0'), findsWidgets); // REMAINING: 0
    });

    testWidgets('Live updates: advancing FakeClock refreshes greeting and NOW card elapsed/remaining time', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Set clock to 11:50 AM (morning)
      fakeClock.setNow(DateTime(2026, 11, 19, 11, 50));

      // Task is 11:30 - 12:30 (690 - 750 min) -> at 11:50 (710 min): 20 min in, 40 min left
      final task = Task(
        id: 'task-live',
        title: 'Writing Documentation',
        dateKey: today,
        startMin: 690,
        endMin: 750,
        createdAt: 1000,
        updatedAt: 1000,
      );
      await taskRepo.insertTask(task);

      await tester.pumpWidget(createTestWidget());
      taskRepo.notifyAll();
      await tester.pumpAndSettle();

      expect(find.text('Good Morning, Khushi! ☀️'), findsOneWidget);
      expect(find.text('20 min in'), findsOneWidget);
      expect(find.text('40 min left'), findsOneWidget);

      // Advance clock by 15 minutes to 12:05 PM (afternoon)
      fakeClock.advance(const Duration(minutes: 15));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();

      // Greeting and NOW card both updated via tickStream!
      expect(find.text('Good Afternoon, Khushi! 🌤️'), findsOneWidget);
      expect(find.text('35 min in'), findsOneWidget);
      expect(find.text('25 min left'), findsOneWidget);
    });

    testWidgets('Midnight rollover: advancing clock switches today date and schedule', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Set clock to 23:58 on Nov 19
      fakeClock.setNow(DateTime(2026, 11, 19, 23, 58));

      final taskToday = Task(
        id: 'task-today',
        title: 'Nightly Reflection',
        dateKey: '2026-11-19',
        startMin: 1400,
        endMin: 1435,
        createdAt: 1000,
        updatedAt: 1000,
      );
      await taskRepo.insertTask(taskToday);

      await tester.pumpWidget(createTestWidget());
      taskRepo.notifyAll();
      await tester.pumpAndSettle();

      expect(find.text('Thursday, November 19'), findsOneWidget);
      expect(find.text('Nightly Reflection'), findsWidgets);

      // Advance across midnight to 00:05 on Nov 20
      fakeClock.setNow(DateTime(2026, 11, 20, 0, 5));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();

      // Formatted date rolled over to Friday, Nov 20 and empty state for new day shows!
      expect(find.text('Friday, November 20'), findsOneWidget);
      expect(find.text('No tasks scheduled'), findsWidgets);
    });

    testWidgets('Loading state displays CircularProgressIndicator', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            clockProvider.overrideWithValue(fakeClock),
            sharedPreferencesProvider.overrideWithValue(prefs),
            homeDashboardProvider.overrideWithValue(const AsyncLoading()),
          ],
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('Error state displays friendly error card with Retry button', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final controller = StreamController<List<Task>>.broadcast();
      final failingRepo = _FailingStreamRepo(controller.stream);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            clockProvider.overrideWithValue(fakeClock),
            sharedPreferencesProvider.overrideWithValue(prefs),
            taskRepositoryProvider.overrideWithValue(failingRepo),
          ],
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );
      controller.addError(Exception('Database disk I/O error'));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump();

      expect(find.text('Unable to load schedule'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      await controller.close();
    });

    testWidgets('Responsive check: Long user name at font scale 1.3 on 320dp width does not overflow', (tester) async {
      // 320dp width small phone
      tester.view.physicalSize = const Size(320 * 2, 700 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      SharedPreferences.setMockInitialValues({
        'user_name': 'Alexander Bartholomew Montgomery III',
        'onboarding_done': true,
      });
      final longNamePrefs = await SharedPreferences.getInstance();

      final task = Task(
        id: 'task-now',
        title: 'Review Quarterly Architecture Proposal',
        dateKey: today,
        startMin: 570,
        endMin: 630,
        createdAt: 1000,
        updatedAt: 1000,
      );
      await taskRepo.insertTask(task);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            clockProvider.overrideWithValue(fakeClock),
            sharedPreferencesProvider.overrideWithValue(longNamePrefs),
            taskRepositoryProvider.overrideWithValue(taskRepo),
          ],
          child: const MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(
                size: Size(320, 700),
                textScaler: TextScaler.linear(1.3),
              ),
              child: HomeScreen(),
            ),
          ),
        ),
      );
      taskRepo.notifyAll();
      await tester.pumpAndSettle();

      // Avatar initials derived: "AB"
      expect(find.text('AB'), findsOneWidget);

      // Verify no Flutter error / overflow thrown
      expect(tester.takeException(), isNull);
    });
  });
}
