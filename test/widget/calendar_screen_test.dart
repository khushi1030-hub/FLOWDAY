import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flow_day/core/providers/database_providers.dart';
import 'package:flow_day/core/time/app_clock.dart';
import 'package:flow_day/features/schedule/presentation/calendar_screen.dart';
import 'package:flow_day/features/tasks/domain/entities/task.dart';
import 'package:flow_day/features/tasks/domain/repositories/task_repository.dart';

class _FakeCalendarTaskRepo implements TaskRepository {
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

  @override
  Future<void> applyDelayShift({required Task extendedTask, required List<Task> shiftedTasks}) async {
    await updateTask(extendedTask);
    for (final t in shiftedTasks) {
      await updateTask(t);
    }
  }

  @override
  Future<void> rescheduleTask(Task task, {required String newDateKey, required int newStartMin, required int newEndMin, String? carriedFromDateKey}) async {
    await updateTask(task.copyWith(
      dateKey: newDateKey,
      startMin: newStartMin,
      endMin: newEndMin,
      carriedFromDateKey: carriedFromDateKey,
      wasRescheduled: true,
      status: 'rescheduled',
    ));
  }

  void dispose() {
    _controller.close();
  }
}

void main() {
  group('Phase 6 CalendarScreen Widget Tests', () {
    late FakeClock fakeClock;
    late _FakeCalendarTaskRepo repo;
    late SharedPreferences prefs;

    final fixedTime = DateTime(2026, 5, 14, 10, 0); // May 14, 2026 (Screen 21 source)

    setUp(() async {
      fakeClock = FakeClock(fixedTime);
      repo = _FakeCalendarTaskRepo();
      SharedPreferences.setMockInitialValues({
        'wake_min': 420,
        'sleep_min': 1380,
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
          home: CalendarScreen(),
        ),
      );
    }

    testWidgets('Renders Screen 21 elements: Month only pill, matrix, 3 stat tiles, legend, and agenda',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Insert tasks for May 14 (Screen 21):
      // - Completed: Morning run
      // - In progress: Learn Flutter
      // - Upcoming: Practice DSA
      // - Rescheduled: Reply to emails
      await repo.insertTask(Task(
        id: 't-1',
        title: 'Morning run',
        dateKey: '2026-05-14',
        startMin: 420,
        endMin: 450,
        status: 'completed',
        createdAt: fixedTime.millisecondsSinceEpoch,
        updatedAt: fixedTime.millisecondsSinceEpoch,
      ));

      await repo.insertTask(Task(
        id: 't-2',
        title: 'Learn Flutter',
        dateKey: '2026-05-14',
        startMin: 540,
        endMin: 600,
        status: 'pending',
        createdAt: fixedTime.millisecondsSinceEpoch,
        updatedAt: fixedTime.millisecondsSinceEpoch,
      ));

      await repo.insertTask(Task(
        id: 't-3',
        title: 'Practice DSA',
        dateKey: '2026-05-14',
        startMin: 600,
        endMin: 660,
        status: 'pending',
        createdAt: fixedTime.millisecondsSinceEpoch,
        updatedAt: fixedTime.millisecondsSinceEpoch,
      ));

      await repo.insertTask(Task(
        id: 't-4',
        title: 'Reply to emails',
        dateKey: '2026-05-14',
        startMin: 510,
        endMin: 540,
        status: 'rescheduled',
        createdAt: fixedTime.millisecondsSinceEpoch,
        updatedAt: fixedTime.millisecondsSinceEpoch,
      ));

      // Past day missed task (May 10)
      await repo.insertTask(Task(
        id: 't-past',
        title: 'Past Missed Task',
        dateKey: '2026-05-10',
        startMin: 600,
        endMin: 660,
        status: 'pending', // On past day -> Missed
        createdAt: fixedTime.millisecondsSinceEpoch,
        updatedAt: fixedTime.millisecondsSinceEpoch,
      ));

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Title & Month pill (Week toggle hidden)
      expect(find.text('Calendar'), findsOneWidget);
      expect(find.text('Month'), findsOneWidget);
      expect(find.text('Week'), findsNothing);

      // Month title
      expect(find.text('May 2026'), findsOneWidget);

      // Weekday headers
      expect(find.text('Sun'), findsOneWidget);
      expect(find.text('Mon'), findsOneWidget);
      expect(find.text('Sat'), findsOneWidget);

      // Dot legend items
      expect(find.text('Completed'), findsWidgets);
      expect(find.text('Upcoming'), findsWidgets);
      expect(find.text('Rescheduled'), findsWidgets);
      expect(find.text('Missed'), findsWidgets);

      // 3 Stat tiles counts
      expect(find.text('1'), findsWidgets); // 1 completed, 1 rescheduled, 1 missed

      // Selected day agenda section
      expect(find.text('Open day ->'), findsOneWidget);
      expect(find.text('Morning run'), findsOneWidget);
      expect(find.text('Learn Flutter'), findsOneWidget);
      expect(find.text('Practice DSA'), findsOneWidget);
      expect(find.text('Reply to emails'), findsOneWidget);
    });

    testWidgets('Tapping date cell in matrix selects that date and updates agenda list',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await repo.insertTask(Task(
        id: 't-may20',
        title: 'Special Event On 20th',
        dateKey: '2026-05-20',
        startMin: 600,
        endMin: 660,
        status: 'pending',
        createdAt: fixedTime.millisecondsSinceEpoch,
        updatedAt: fixedTime.millisecondsSinceEpoch,
      ));

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Special Event On 20th'), findsNothing);

      // Tap day 20 on the grid
      await tester.tap(find.text('20'));
      await tester.pumpAndSettle();

      // Agenda should now show May 20 task
      expect(find.text('Special Event On 20th'), findsOneWidget);
    });

    testWidgets('Responsive test: 320dp width and 1.3 font scale renders without overflow',
        (tester) async {
      tester.view.physicalSize = const Size(320 * 2, 700 * 2);
      tester.view.devicePixelRatio = 2.0;
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        tester.platformDispatcher.clearTextScaleFactorTestValue();
      });

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Calendar'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
