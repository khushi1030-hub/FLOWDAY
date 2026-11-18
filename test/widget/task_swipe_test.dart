import 'dart:async';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flow_day/features/tasks/domain/entities/task.dart';
import 'package:flow_day/features/tasks/domain/repositories/task_repository.dart';
import 'package:flow_day/features/tasks/presentation/widgets/swipeable_task_card.dart';

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
  Future<List<Task>> getTasksForDate(String dateKey) async =>
      _tasks.where((t) => t.dateKey == dateKey).toList();

  @override
  Stream<List<Task>> watchTasksForDate(String dateKey) =>
      _controller.stream.map((list) => list.where((t) => t.dateKey == dateKey).toList());

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
}

void main() {
  group('SwipeableTaskCard Repository & Widget Tests', () {
    late FakeTaskRepository taskRepo;

    final task = Task(
      id: 'task-swipe-test-1',
      title: 'Practice LeetCode',
      dateKey: '2026-11-19',
      startMin: 600, // 10:00 AM
      endMin: 660, // 11:00 AM
      priority: 2,
      createdAt: 1000,
      updatedAt: 1000,
    );

    setUp(() async {
      taskRepo = FakeTaskRepository();
      await taskRepo.insertTask(task);
    });

    testWidgets('Swipe right triggers onComplete, updates repo to completed, and task is NOT deleted', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwipeableTaskCard(
              task: task,
              onComplete: (t) async {
                await taskRepo.markCompleted(t.id, 2000);
              },
              onIncomplete: (t) async {
                await taskRepo.markIncomplete(t.id);
              },
            ),
          ),
        ),
      );

      // Verify initial state
      expect(find.text('Practice LeetCode'), findsOneWidget);
      expect(find.byType(SwipeableTaskCard), findsOneWidget);
      expect(await taskRepo.getTaskById('task-swipe-test-1'), isNotNull);

      // Swipe right (drag from left to right)
      await tester.drag(find.text('Practice LeetCode'), const Offset(500, 0));
      await tester.pumpAndSettle();

      // REPOSITORY ASSERTION: Task must STILL exist in repository
      final repoTask = await taskRepo.getTaskById('task-swipe-test-1');
      expect(repoTask, isNotNull, reason: 'Task must NOT be deleted from repository on swipe right');
      expect(repoTask!.status, 'completed', reason: 'Task status should update to completed');

      // WIDGET ASSERTION: Task card must NOT be dismissed from UI
      expect(find.text('Practice LeetCode'), findsOneWidget);
      expect(find.byType(SwipeableTaskCard), findsOneWidget);
    });

    testWidgets('Swipe left triggers onIncomplete, updates repo to incomplete, and task is NOT deleted', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwipeableTaskCard(
              task: task,
              onComplete: (t) async {
                await taskRepo.markCompleted(t.id, 2000);
              },
              onIncomplete: (t) async {
                await taskRepo.markIncomplete(t.id);
              },
            ),
          ),
        ),
      );

      // Verify initial state
      expect(find.text('Practice LeetCode'), findsOneWidget);
      expect(find.byType(SwipeableTaskCard), findsOneWidget);
      expect(await taskRepo.getTaskById('task-swipe-test-1'), isNotNull);

      // Swipe left (drag from right to left)
      await tester.drag(find.text('Practice LeetCode'), const Offset(-500, 0));
      await tester.pumpAndSettle();

      // REPOSITORY ASSERTION: Task must STILL exist in repository
      final repoTask = await taskRepo.getTaskById('task-swipe-test-1');
      expect(repoTask, isNotNull, reason: 'Task must NOT be deleted from repository on swipe left');
      expect(repoTask!.status, 'incomplete', reason: 'Task status should update to incomplete');

      // WIDGET ASSERTION: Task card must NOT be dismissed from UI
      expect(find.text('Practice LeetCode'), findsOneWidget);
      expect(find.byType(SwipeableTaskCard), findsOneWidget);
    });
  });
}
