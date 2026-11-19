import 'dart:async';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flow_day/core/providers/database_providers.dart';
import 'package:flow_day/core/time/app_clock.dart';
import 'package:flow_day/features/tasks/domain/entities/task.dart';
import 'package:flow_day/features/tasks/domain/repositories/task_repository.dart';
import 'package:flow_day/features/tasks/presentation/edit_task_screen.dart';
import 'package:flow_day/features/tasks/presentation/new_task_screen.dart';
import 'package:flow_day/features/tasks/presentation/task_completed_screen.dart';
import 'package:flow_day/features/tasks/presentation/widgets/task_preview_card.dart';

class FakeTaskRepository implements TaskRepository {
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
    return _controller.stream.map((list) => list.where((t) => t.dateKey == dateKey).toList());
  }

  @override
  Stream<List<Task>> watchAllTasks() => _controller.stream;

  @override
  Future<List<Task>> getAllTasks() async => List.unmodifiable(_tasks);

  @override
  Future<void> insertTask(Task task) async {
    _tasks.add(task);
    _controller.add(_tasks);
  }

  @override
  Future<void> updateTask(Task task) async {
    final idx = _tasks.indexWhere((t) => t.id == task.id);
    if (idx != -1) {
      _tasks[idx] = task;
      _controller.add(_tasks);
    }
  }

  @override
  Future<void> deleteTask(String id) async {
    _tasks.removeWhere((t) => t.id == id);
    _controller.add(_tasks);
  }

  @override
  Future<void> markCompleted(String id, int completedAt) async {
    final idx = _tasks.indexWhere((t) => t.id == id);
    if (idx != -1) {
      _tasks[idx] = _tasks[idx].copyWith(status: 'completed', completedAt: completedAt);
      _controller.add(_tasks);
    }
  }

  @override
  Future<void> markIncomplete(String id) async {
    final idx = _tasks.indexWhere((t) => t.id == id);
    if (idx != -1) {
      _tasks[idx] = _tasks[idx].copyWith(status: 'incomplete');
      _controller.add(_tasks);
    }
  }

  @override
  Future<void> deleteAll() async {
    _tasks.clear();
    _controller.add(_tasks);
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
}

void main() {
  group('Phase 4 Task Screens Widget Tests', () {
    late FakeClock fakeClock;
    late FakeTaskRepository taskRepo;
    late SharedPreferences prefs;

    final fixedTime = DateTime(2026, 11, 19, 10, 0);

    setUp(() async {
      fakeClock = FakeClock(fixedTime);
      SharedPreferences.setMockInitialValues({
        'wake_min': 420, // 07:00
        'sleep_min': 1380, // 23:00
        'default_break_min': 15,
      });
      prefs = await SharedPreferences.getInstance();
      taskRepo = FakeTaskRepository();
    });

    testWidgets('NewTaskScreen: validates empty title and creates task', (tester) async {
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
            taskRepositoryProvider.overrideWithValue(taskRepo),
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const MaterialApp(
            home: NewTaskScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Screen 09 header elements
      expect(find.text('New task'), findsOneWidget);
      expect(find.byType(TaskPreviewCard), findsOneWidget);

      final saveBtn = find.text('✓ Save Task');
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pump(const Duration(milliseconds: 300));

      // Validation error must appear
      expect(find.text('Please enter a task title.'), findsOneWidget);

      // Enter valid title
      final titleField = find.byType(TextField).first;
      await tester.enterText(titleField, 'Build Phase 4 Feature');
      await tester.pump(const Duration(milliseconds: 100));

      // Tap Work category
      final workCategory = find.text('Work');
      await tester.ensureVisible(workCategory);
      await tester.tap(workCategory);
      await tester.pump(const Duration(milliseconds: 100));

      // Save valid task
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pump(const Duration(milliseconds: 300));

      // Verify task persisted in database
      final tasks = await taskRepo.getTasksForDate('2026-11-19');
      expect(tasks.length, 1);
      expect(tasks.first.title, 'Build Phase 4 Feature');
      expect(tasks.first.categoryId, 2); // Work category id
    });

    testWidgets('EditTaskScreen: loads task and confirms explicit deletion', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final task = Task(
        id: 'task-to-delete-1',
        title: 'Task For Deletion Test',
        dateKey: '2026-11-19',
        startMin: 600,
        endMin: 645,
        priority: 1,
        categoryId: 1,
        createdAt: fixedTime.millisecondsSinceEpoch,
        updatedAt: fixedTime.millisecondsSinceEpoch,
      );
      await taskRepo.insertTask(task);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            clockProvider.overrideWithValue(fakeClock),
            taskRepositoryProvider.overrideWithValue(taskRepo),
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const MaterialApp(
            home: EditTaskScreen(taskId: 'task-to-delete-1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Loaded task title in field
      expect(find.text('Task For Deletion Test'), findsOneWidget);

      // Tap trash button at top bar
      final deleteIcon = find.byIcon(Icons.delete_outline_rounded);
      expect(deleteIcon, findsOneWidget);
      await tester.tap(deleteIcon);
      await tester.pumpAndSettle();

      // Confirmation dialog must appear
      expect(find.text('Delete Task?'), findsOneWidget);
      final dialogCancel = find.descendant(of: find.byType(AlertDialog), matching: find.text('Cancel'));
      expect(dialogCancel, findsOneWidget);
      final dialogDelete = find.descendant(of: find.byType(AlertDialog), matching: find.text('Delete'));
      expect(dialogDelete, findsOneWidget);

      // Cancel keeps task
      await tester.tap(dialogCancel);
      await tester.pumpAndSettle();
      expect(await taskRepo.getTaskById('task-to-delete-1'), isNotNull);

      // Tap trash again and confirm delete
      await tester.tap(deleteIcon);
      await tester.pumpAndSettle();
      await tester.tap(dialogDelete);
      await tester.pumpAndSettle();

      // Task must now be deleted from database
      expect(await taskRepo.getTaskById('task-to-delete-1'), isNull);
    });

    testWidgets('TaskCompletedScreen: renders celebration, stats, and done button', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final task = Task(
        id: 'task-celebrate-1',
        title: 'Complete Deep Work Session',
        dateKey: '2026-11-19',
        startMin: 600,
        endMin: 660,
        status: 'completed',
        completedAt: fixedTime.millisecondsSinceEpoch,
        createdAt: fixedTime.millisecondsSinceEpoch,
        updatedAt: fixedTime.millisecondsSinceEpoch,
      );
      await taskRepo.insertTask(task);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            clockProvider.overrideWithValue(fakeClock),
            taskRepositoryProvider.overrideWithValue(taskRepo),
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const MaterialApp(
            home: TaskCompletedScreen(taskId: 'task-celebrate-1'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Screen 13 elements
      expect(find.text('Amazing! 🎉'), findsOneWidget);
      expect(find.text('Task completed.'), findsOneWidget);
      expect(find.text('Complete Deep Work Session'), findsOneWidget);
      expect(find.text('Duration'), findsOneWidget);
      expect(find.text('60m'), findsWidgets);
      expect(find.text('Back to Home'), findsOneWidget);
    });

    testWidgets('NewTaskScreen: bad query parameters safely fall back to valid defaults', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Pass completely invalid parameters: bad date string, negative/out-of-bounds start & end
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            clockProvider.overrideWithValue(fakeClock),
            taskRepositoryProvider.overrideWithValue(taskRepo),
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const MaterialApp(
            home: NewTaskScreen(
              initialDateKey: 'invalid-date-format',
              initialStartMin: 9999,
              initialEndMin: -100,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Screen must render without crashing and preview must show today's date
      expect(find.text('New task'), findsOneWidget);
      expect(find.byType(TaskPreviewCard), findsOneWidget);
      // Fallback date should be today's dateKey
      expect(find.text('2026-11-19'), findsWidgets);
    });
  });
}
