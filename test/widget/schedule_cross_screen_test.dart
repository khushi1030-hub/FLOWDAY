import 'dart:async';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flow_day/core/providers/database_providers.dart';
import 'package:flow_day/core/time/app_clock.dart';
import 'package:flow_day/core/widgets/flow_empty_state.dart';
import 'package:flow_day/features/home/presentation/home_screen.dart';
import 'package:flow_day/features/schedule/presentation/schedule_screen.dart';
import 'package:flow_day/features/tasks/domain/entities/task.dart';
import 'package:flow_day/features/tasks/domain/repositories/task_repository.dart';
import 'package:flow_day/features/tasks/presentation/widgets/swipeable_task_card.dart';

class _FakeCrossScreenTaskRepo implements TaskRepository {
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
  group('Phase 6 Cross-Screen Reactivity Tests', () {
    late FakeClock fakeClock;
    late _FakeCrossScreenTaskRepo repo;
    late SharedPreferences prefs;

    final baseTime = DateTime(2026, 5, 14, 9, 24); // 09:24 AM

    setUp(() async {
      fakeClock = FakeClock(baseTime);
      repo = _FakeCrossScreenTaskRepo();
      SharedPreferences.setMockInitialValues({
        'wake_min': 420,
        'sleep_min': 1380,
        'default_break_min': 15,
        'user_name': 'Tester',
        'nightly_review_min': 1290,
      });
      prefs = await SharedPreferences.getInstance();
    });

    tearDown(() {
      repo.dispose();
      fakeClock.dispose();
    });

    testWidgets('Task added on Schedule appears on Home without refresh', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // App with bottom navigation containing both Home and Schedule tabs
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            clockProvider.overrideWithValue(fakeClock),
            taskRepositoryProvider.overrideWithValue(repo),
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: MaterialApp(
            home: StatefulBuilder(
              builder: (context, setState) {
                int currentIndex = 0;
                return Scaffold(
                  body: IndexedStack(
                    index: currentIndex,
                    children: const [
                      HomeScreen(),
                      ScheduleScreen(),
                    ],
                  ),
                  bottomNavigationBar: BottomNavigationBar(
                    currentIndex: currentIndex,
                    onTap: (index) => setState(() => currentIndex = index),
                    items: const [
                      BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
                      BottomNavigationBarItem(icon: Icon(Icons.schedule), label: 'Schedule'),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Home starts with empty state
      final homeFinder = find.byType(HomeScreen);
      expect(
        find.descendant(of: homeFinder, matching: find.byType(FlowEmptyState)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: homeFinder, matching: find.text('Client Architecture Review')),
        findsNothing,
      );

      // Now simulate task added on Schedule screen
      await repo.insertTask(Task(
        id: 't-from-schedule',
        title: 'Client Architecture Review',
        dateKey: '2026-05-14',
        startMin: 600, // 10:00 AM
        endMin: 660,   // 11:00 AM
        status: 'pending',
        createdAt: baseTime.millisecondsSinceEpoch,
        updatedAt: baseTime.millisecondsSinceEpoch,
      ));
      await tester.pumpAndSettle();

      // Home screen reflects the task IMMEDIATELY without any manual refresh
      expect(
        find.descendant(of: homeFinder, matching: find.byType(FlowEmptyState)),
        findsNothing,
      );
      expect(
        find.descendant(of: homeFinder, matching: find.byType(SwipeableTaskCard)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: homeFinder, matching: find.text('Client Architecture Review')),
        findsWidgets,
      );
      expect(
        find.descendant(of: homeFinder, matching: find.text('0 of 1 tasks\ncompleted')),
        findsOneWidget,
      );
    });
  });
}
