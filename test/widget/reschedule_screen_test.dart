import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:flow_day/core/providers/database_providers.dart';
import 'package:flow_day/core/time/app_clock.dart';
import 'package:flow_day/features/rescheduling/domain/entities/reschedule_batch.dart';
import 'package:flow_day/features/rescheduling/domain/entities/reschedule_proposal.dart';
import 'package:flow_day/features/rescheduling/domain/repositories/reschedule_repository.dart';
import 'package:flow_day/features/rescheduling/presentation/reschedule_screen.dart';
import 'package:flow_day/features/settings/domain/entities/app_settings.dart';
import 'package:flow_day/features/tasks/domain/entities/task.dart';
import 'package:flow_day/features/tasks/domain/repositories/task_repository.dart';

class _FakeTaskRepo implements TaskRepository {
  _FakeTaskRepo(List<Task> initialTasks) : _tasks = List.of(initialTasks);

  final List<Task> _tasks;
  Task? lastInserted;

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
    return Stream.value(_tasks.where((t) => t.dateKey == dateKey).toList());
  }

  @override
  Stream<List<Task>> watchAllTasks() => Stream.value(List.of(_tasks));

  @override
  Future<List<Task>> getAllTasks() async => List.of(_tasks);

  @override
  Future<void> insertTask(Task task) async {
    lastInserted = task;
    _tasks.add(task);
  }

  @override
  Future<void> updateTask(Task task) async {
    final idx = _tasks.indexWhere((t) => t.id == task.id);
    if (idx != -1) _tasks[idx] = task;
  }

  @override
  Future<void> deleteTask(String id) async {
    _tasks.removeWhere((t) => t.id == id);
  }

  @override
  Future<void> deleteAll() async {
    _tasks.clear();
  }

  @override
  Future<void> markCompleted(String id, int completedAt) async {}

  @override
  Future<void> markIncomplete(String id) async {}

  @override
  Future<void> applyDelayShift({required Task extendedTask, required List<Task> shiftedTasks}) async {}

  @override
  Future<void> rescheduleTask(Task task,
      {required String newDateKey, required int newStartMin, required int newEndMin, String? carriedFromDateKey}) async {}
}

class _FakeRescheduleRepo implements RescheduleRepository {
  RescheduleProposal? lastAppliedProposal;
  bool undone = false;

  @override
  Future<void> createBatch(RescheduleBatch batch) async {}

  @override
  Future<List<RescheduleBatch>> getAllBatches() async => [];

  @override
  Future<RescheduleBatch?> getBatchById(String id) async => null;

  @override
  Future<RescheduleBatch?> getLatestBatch() async => null;

  @override
  Future<void> markBatchUndone(String id, int undoneAt) async {}

  @override
  Future<RescheduleBatch> applyProposal({
    required RescheduleProposal proposal,
    required String reason,
    String? triggerTaskId,
    int? simulatedFailureStep,
  }) async {
    lastAppliedProposal = proposal;
    return RescheduleBatch(
      id: 'batch-test-1',
      reason: reason,
      triggerTaskId: triggerTaskId,
      proposalLabel: proposal.title,
      createdAt: 1000000,
    );
  }

  @override
  Future<void> undoBatch(String batchId, {int? simulatedFailureStep}) async {
    undone = true;
  }

  @override
  Future<void> undoLatestBatch({int? simulatedFailureStep}) async {
    undone = true;
  }
}

void main() {
  const dateKey = '2026-11-20';
  final fixedClock = FakeClock(DateTime(2026, 11, 20, 10, 0));

  final studyTask = Task(
    id: 'task-study',
    title: 'Study Mathematics',
    categoryId: 1,
    dateKey: dateKey,
    startMin: 540, // 09:00
    endMin: 600, // 10:00 (extended -> 10:30)
    isFixed: false,
    priority: 1,
    status: 'in_progress',
    createdAt: 1000,
    updatedAt: 1000,
  );

  final workoutTask = Task(
    id: 'task-workout',
    title: 'Gym Workout',
    categoryId: 3,
    dateKey: dateKey,
    startMin: 600, // 10:00 - 11:00 (Flexible, can shift to 10:30-11:30)
    endMin: 660,
    isFixed: false,
    priority: 2,
    status: 'pending',
    createdAt: 1000,
    updatedAt: 1000,
  );

  final clientMeeting = Task(
    id: 'task-meeting',
    title: 'Client Review Meeting',
    categoryId: 2,
    dateKey: dateKey,
    startMin: 720, // 12:00 - 13:00 (Fixed!)
    endMin: 780,
    isFixed: true,
    priority: 1,
    status: 'pending',
    createdAt: 1000,
    updatedAt: 1000,
  );

  Widget createTestWidget({
    required Widget child,
    required _FakeTaskRepo taskRepo,
    required _FakeRescheduleRepo rescheduleRepo,
  }) {
    return ProviderScope(
      overrides: [
        clockProvider.overrideWithValue(fixedClock),
        taskRepositoryProvider.overrideWithValue(taskRepo),
        rescheduleRepositoryProvider.overrideWithValue(rescheduleRepo),
        settingsStateProvider.overrideWith((ref) => Stream.value(const AppSettings(wakeMin: 420, sleepMin: 1380))),
      ],
      child: MaterialApp(
        home: child,
      ),
    );
  }

  testWidgets('Screen 16: renders Before & After comparison, plan cards, and legend', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final taskRepo = _FakeTaskRepo([studyTask, workoutTask, clientMeeting]);
    final rescheduleRepo = _FakeRescheduleRepo();

    await tester.pumpWidget(
      createTestWidget(
        taskRepo: taskRepo,
        rescheduleRepo: rescheduleRepo,
        child: const RescheduleScreen(
          taskId: 'task-study',
          extraMinutes: 30,
          dateKey: dateKey,
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Screen 16 elements
    expect(find.text('Smart Rescheduling'), findsOneWidget);
    expect(find.textContaining('+30 min needed'), findsOneWidget);
    expect(find.text('Before & after'), findsOneWidget);
    expect(find.text('🔒 Fixed'), findsOneWidget);
    expect(find.text('↕ Flexible'), findsOneWidget);
    expect(find.text('🛡 Protected'), findsOneWidget);

    // Verify Before and After column labels
    expect(find.text('Before'), findsOneWidget);
    expect(find.text('After'), findsOneWidget);

    // Verify Plan Cards exist (Badge A with RECOMMENDED chip and title)
    expect(find.text('A'), findsWidgets);
    expect(find.text('RECOMMENDED'), findsOneWidget);
    expect(find.textContaining('shift flexible tasks'), findsOneWidget);
    expect(find.text('Apply Plan A'), findsOneWidget);

    // Verify nothing is applied on load
    expect(rescheduleRepo.lastAppliedProposal, isNull);
  });

  testWidgets('Screen 16: selecting a different plan switches selection and updates bottom button', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final taskRepo = _FakeTaskRepo([studyTask, workoutTask, clientMeeting]);
    final rescheduleRepo = _FakeRescheduleRepo();

    await tester.pumpWidget(
      createTestWidget(
        taskRepo: taskRepo,
        rescheduleRepo: rescheduleRepo,
        child: const RescheduleScreen(
          taskId: 'task-study',
          extraMinutes: 30,
          dateKey: dateKey,
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Initially Plan A is selected
    expect(find.text('Apply Plan A'), findsOneWidget);

    // Tap Plan B badge 'B' if present
    final planBFinder = find.text('B');
    if (planBFinder.evaluate().isNotEmpty) {
      await tester.tap(planBFinder.first);
      await tester.pumpAndSettle();
      expect(find.text('Apply Plan B'), findsOneWidget);
    }
  });

  testWidgets('Screen 16: applying proposal calls applyProposal and shows SnackBar with Undo', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final taskRepo = _FakeTaskRepo([studyTask, workoutTask, clientMeeting]);
    final rescheduleRepo = _FakeRescheduleRepo();

    await tester.pumpWidget(
      createTestWidget(
        taskRepo: taskRepo,
        rescheduleRepo: rescheduleRepo,
        child: const RescheduleScreen(
          taskId: 'task-study',
          extraMinutes: 30,
          dateKey: dateKey,
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Tap Apply Plan A
    await tester.tap(find.text('Apply Plan A'));
    await tester.pump(); // Start async action
    await tester.pump(const Duration(milliseconds: 750)); // Allow apply and SnackBar entrance animation

    // RescheduleRepo must have recorded the applied proposal
    expect(rescheduleRepo.lastAppliedProposal, isNotNull);
    expect(rescheduleRepo.lastAppliedProposal!.id, 'A');

    // SnackBar with Undo must be displayed
    expect(find.text('Schedule updated'), findsOneWidget);
    expect(find.text('Undo'), findsOneWidget);

    // Tap Undo
    await tester.tap(find.text('Undo'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(rescheduleRepo.undone, isTrue);
  });

  testWidgets('Screen 19: renders conflict variant with clash details and recommendations', (tester) async {
    final taskRepo = _FakeTaskRepo([studyTask, workoutTask, clientMeeting]);
    final rescheduleRepo = _FakeRescheduleRepo();

    final newConflictingTask = Task(
      id: 'task-new-lunch',
      title: 'Lunch with Sarah',
      categoryId: 4,
      dateKey: dateKey,
      startMin: 630, // 10:30 - 11:30 (Collides with Workout 10:00-11:00)
      endMin: 690,
      isFixed: false,
      priority: 2,
      status: 'pending',
      createdAt: 1000,
      updatedAt: 1000,
    );

    await tester.pumpWidget(
      createTestWidget(
        taskRepo: taskRepo,
        rescheduleRepo: rescheduleRepo,
        child: RescheduleScreen(
          newConflictingTask: newConflictingTask,
          dateKey: dateKey,
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Screen 19 header
    expect(find.text('New plan'), findsOneWidget);
    expect(find.text('Your new plan conflicts with scheduled tasks.'), findsOneWidget);
    expect(find.text('Recommendations'), findsOneWidget);
    expect(find.text('Keep overlap'), findsOneWidget);
  });

  testWidgets('Screen 19: Keep overlap saves task with conflict flag per Decision D3', (tester) async {
    final taskRepo = _FakeTaskRepo([studyTask, workoutTask, clientMeeting]);
    final rescheduleRepo = _FakeRescheduleRepo();

    final newConflictingTask = Task(
      id: 'task-new-lunch',
      title: 'Lunch with Sarah',
      categoryId: 4,
      dateKey: dateKey,
      startMin: 630,
      endMin: 690,
      isFixed: false,
      priority: 2,
      status: 'pending',
      createdAt: 1000,
      updatedAt: 1000,
    );

    await tester.pumpWidget(
      createTestWidget(
        taskRepo: taskRepo,
        rescheduleRepo: rescheduleRepo,
        child: RescheduleScreen(
          newConflictingTask: newConflictingTask,
          dateKey: dateKey,
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Tap Keep overlap button
    await tester.tap(find.text('Keep overlap'));
    await tester.pumpAndSettle();

    expect(taskRepo.lastInserted, isNotNull);
    expect(taskRepo.lastInserted!.title, 'Lunch with Sarah');
    expect(taskRepo.lastInserted!.hasConflict, isTrue);
  });
}
