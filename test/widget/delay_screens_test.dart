import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flow_day/core/providers/database_providers.dart';
import 'package:flow_day/core/time/app_clock.dart';
import 'package:flow_day/features/delay/presentation/unfinished_adjust_screen.dart';
import 'package:flow_day/features/delay/presentation/widgets/extra_time_bottom_sheet.dart';
import 'package:flow_day/features/tasks/domain/entities/task.dart';
import 'package:flow_day/features/tasks/domain/repositories/task_repository.dart';

class _FakeDelayTaskRepo implements TaskRepository {
  _FakeDelayTaskRepo(List<Task> initialTasks) : _tasks = List.of(initialTasks);

  final List<Task> _tasks;
  Task? appliedExtendedTask;
  List<Task>? appliedShiftedTasks;
  Task? rescheduledTask;

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
  Stream<List<Task>> watchAllTasks() {
    return Stream.value(List.of(_tasks));
  }

  @override
  Future<List<Task>> getAllTasks() async => List.of(_tasks);

  @override
  Future<void> insertTask(Task task) async {
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
  Future<void> markCompleted(String id, int completedAt) async {
    final idx = _tasks.indexWhere((t) => t.id == id);
    if (idx != -1) _tasks[idx] = _tasks[idx].copyWith(status: 'completed');
  }

  @override
  Future<void> markIncomplete(String id) async {
    final idx = _tasks.indexWhere((t) => t.id == id);
    if (idx != -1) _tasks[idx] = _tasks[idx].copyWith(status: 'incomplete');
  }

  @override
  Future<void> applyDelayShift({required Task extendedTask, required List<Task> shiftedTasks}) async {
    appliedExtendedTask = extendedTask;
    appliedShiftedTasks = shiftedTasks;
    await updateTask(extendedTask);
    for (final t in shiftedTasks) {
      await updateTask(t);
    }
  }

  @override
  Future<void> rescheduleTask(Task task, {required String newDateKey, required int newStartMin, required int newEndMin, String? carriedFromDateKey}) async {
    rescheduledTask = task.copyWith(
      dateKey: newDateKey,
      startMin: newStartMin,
      endMin: newEndMin,
      carriedFromDateKey: carriedFromDateKey,
      wasRescheduled: true,
      status: 'rescheduled',
    );
    await updateTask(rescheduledTask!);
  }

  @override
  Future<void> deleteAll() async {
    _tasks.clear();
  }
}

void main() {
  group('Screen 14: UnfinishedAdjustScreen Widget Tests', () {
    late FakeClock fakeClock;
    late _FakeDelayTaskRepo repo;

    final fixedNow = DateTime(2026, 5, 14, 10, 0); // 10:00 AM
    final mainTask = Task(
      id: 'task-delay-1',
      title: 'Learn Flutter',
      dateKey: '2026-05-14',
      startMin: 540, // 09:00 AM
      endMin: 600, // 10:00 AM
      priority: 3, // High priority
      categoryId: 1, // Study
      createdAt: 1000,
      updatedAt: 1000,
    );

    final nextTask = Task(
      id: 'task-delay-2',
      title: 'Practice DSA',
      dateKey: '2026-05-14',
      startMin: 660, // 11:00 AM (leaves free gap 10:00 - 11:00)
      endMin: 720,
      createdAt: 1000,
      updatedAt: 1000,
    );

    setUp(() {
      fakeClock = FakeClock(fixedNow);
      repo = _FakeDelayTaskRepo([mainTask, nextTask]);
    });

    testWidgets('renders Screen 14 header, task card, estimate pills, and 3 choices', (tester) async {
      SharedPreferences.setMockInitialValues({'sleep_min': 1380, 'wake_min': 420});
      final prefs = await SharedPreferences.getInstance();

      final testRouter = GoRouter(
        initialLocation: '/delay/${mainTask.id}',
        routes: [
          GoRoute(
            path: '/delay/:taskId',
            builder: (context, state) => UnfinishedAdjustScreen(taskId: state.pathParameters['taskId']!),
          ),
          GoRoute(path: '/home', builder: (context, state) => const Scaffold(body: Text('Home Screen'))),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            clockProvider.overrideWithValue(fakeClock),
            taskRepositoryProvider.overrideWithValue(repo),
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: MaterialApp.router(
            routerConfig: testRouter,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 1. Header & Hero
      expect(find.text("No worries!\nLet's adjust your schedule."), findsOneWidget);
      expect(find.byIcon(Icons.hourglass_top_rounded), findsOneWidget);

      // 2. Task card details
      expect(find.text('Learn Flutter'), findsOneWidget);
      expect(find.text('Study · High priority'), findsOneWidget);
      expect(find.text('Unfinished'), findsOneWidget);
      expect(find.text('09:00 AM – 10:00 AM'), findsOneWidget);
      expect(find.text('10:00 AM'), findsOneWidget);

      // 3. Estimate pills
      expect(find.text('15m'), findsOneWidget);
      expect(find.text('30m'), findsOneWidget);
      expect(find.text('45m'), findsOneWidget);
      expect(find.text('1h+'), findsOneWidget);

      // 4. Three choices
      expect(find.text('Add Extra Time'), findsOneWidget);
      expect(find.text('Reschedule Later Today'), findsOneWidget);
      expect(find.text('Move to Tomorrow'), findsOneWidget);

      // Free slot today discovered
      expect(find.textContaining('Free slot found'), findsOneWidget);

      // Encouragement card & Continue button
      expect(find.textContaining("One unfinished task doesn't have to ruin your entire day"), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);
    });

    testWidgets('selecting Move to Tomorrow and tapping Continue reschedules task to tomorrow', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      SharedPreferences.setMockInitialValues({'sleep_min': 1380, 'wake_min': 420});
      final prefs = await SharedPreferences.getInstance();

      final testRouter = GoRouter(
        initialLocation: '/delay/${mainTask.id}',
        routes: [
          GoRoute(
            path: '/delay/:taskId',
            builder: (context, state) => UnfinishedAdjustScreen(taskId: state.pathParameters['taskId']!),
          ),
          GoRoute(path: '/home', builder: (context, state) => const Scaffold(body: Text('Home Screen'))),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            clockProvider.overrideWithValue(fakeClock),
            taskRepositoryProvider.overrideWithValue(repo),
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: MaterialApp.router(
            routerConfig: testRouter,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap Option 3: Move to Tomorrow
      await tester.tap(find.text('Move to Tomorrow'));
      await tester.pumpAndSettle();

      // Tap Continue
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(repo.rescheduledTask, isNotNull);
      expect(repo.rescheduledTask?.dateKey, '2026-05-15');
      expect(repo.rescheduledTask?.carriedFromDateKey, '2026-05-14');
      expect(repo.rescheduledTask?.status, 'rescheduled');
    });
  });

  group('Screen 15: ExtraTimeBottomSheet Widget Tests', () {
    late FakeClock fakeClock;
    late _FakeDelayTaskRepo repo;

    final fixedNow = DateTime(2026, 5, 14, 10, 0); // 10:00 AM
    final mainTask = Task(
      id: 'task-1',
      title: 'Learn Flutter',
      dateKey: '2026-05-14',
      startMin: 540, // 09:00 AM
      endMin: 600, // 10:00 AM
      createdAt: 1000,
      updatedAt: 1000,
    );

    final subsequentTask = Task(
      id: 'task-2',
      title: 'Practice DSA',
      dateKey: '2026-05-14',
      startMin: 600, // 10:00 AM
      endMin: 660, // 11:00 AM
      createdAt: 1000,
      updatedAt: 1000,
    );

    setUp(() {
      fakeClock = FakeClock(fixedNow);
      repo = _FakeDelayTaskRepo([mainTask, subsequentTask]);
    });

    testWidgets('renders Screen 15 presets, new end time, and applies delay shift', (tester) async {
      SharedPreferences.setMockInitialValues({'sleep_min': 1380});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            clockProvider.overrideWithValue(fakeClock),
            taskRepositoryProvider.overrideWithValue(repo),
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => ExtraTimeBottomSheet.show(
                    context,
                    task: mainTask,
                    dayTasks: [mainTask, subsequentTask],
                    initialMinutes: 30,
                  ),
                  child: const Text('Open Sheet'),
                ),
              ),
            ),
          ),
        ),
      );

      // Open sheet
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      // Title & subtitle
      expect(find.text("How much more time\ndo you need?"), findsOneWidget);
      expect(find.textContaining("Learn Flutter · originally ends 10:00 AM"), findsOneWidget);

      // Preset grid
      expect(find.text('10 minutes'), findsOneWidget);
      expect(find.text('15 minutes'), findsOneWidget);
      expect(find.text('30 minutes'), findsOneWidget);
      expect(find.text('45 minutes'), findsOneWidget);
      expect(find.text('1 hour'), findsOneWidget);
      expect(find.text('Custom'), findsOneWidget);

      // Result card: 10:00 AM -> 10:30 AM with +30 min badge
      expect(find.text('NEW END TIME'), findsOneWidget);
      expect(find.text('10:30 AM'), findsOneWidget);
      expect(find.text('+30 min'), findsOneWidget);

      // Ripple impact: Practice DSA shifted
      expect(find.text('Practice DSA'), findsOneWidget);
      expect(find.text('Shifted'), findsOneWidget);

      // Switch to +15 min preset
      await tester.tap(find.text('15 minutes'));
      await tester.pumpAndSettle();

      expect(find.text('10:15 AM'), findsOneWidget);
      expect(find.text('+15 min'), findsOneWidget);

      // Tap Apply Changes
      await tester.tap(find.text('Apply Changes'));
      await tester.pumpAndSettle();

      expect(repo.appliedExtendedTask, isNotNull);
      expect(repo.appliedExtendedTask?.endMin, 615); // 10:15
      expect(repo.appliedShiftedTasks, isNotNull);
      expect(repo.appliedShiftedTasks?.length, 1);
      expect(repo.appliedShiftedTasks?.first.startMin, 615);
      expect(repo.appliedShiftedTasks?.first.endMin, 675);
    });

    testWidgets('shows warning and fixed chip when extending task collides with fixed task', (tester) async {
      SharedPreferences.setMockInitialValues({'sleep_min': 1380});
      final prefs = await SharedPreferences.getInstance();

      final fixedLunch = Task(
        id: 'lunch-fixed',
        title: 'Lunch with Aarav',
        dateKey: '2026-05-14',
        startMin: 630, // 10:30 AM
        endMin: 690, // 11:30 AM
        isFixed: true,
        createdAt: 1000,
        updatedAt: 1000,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            clockProvider.overrideWithValue(fakeClock),
            taskRepositoryProvider.overrideWithValue(_FakeDelayTaskRepo([mainTask, subsequentTask, fixedLunch])),
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => ExtraTimeBottomSheet.show(
                    context,
                    task: mainTask,
                    dayTasks: [mainTask, subsequentTask, fixedLunch],
                    initialMinutes: 30, // +30m pushes mainTask to 10:30, Practice DSA to 10:30-11:30 which overlaps Lunch (10:30)
                  ),
                  child: const Text('Open Collision Sheet'),
                ),
              ),
            ),
          ),
        ),
      );

      // Open sheet
      await tester.tap(find.text('Open Collision Sheet'));
      await tester.pumpAndSettle();

      // Fixed task chip
      expect(find.text('Fixed'), findsOneWidget);
      expect(find.textContaining('Overlaps Lunch with Aarav'), findsOneWidget);

      // Warning text & Reschedule button
      expect(find.textContaining('Smart Rescheduling will offer options'), findsOneWidget);
      expect(find.text('Reschedule'), findsOneWidget);
    });
  });
}
