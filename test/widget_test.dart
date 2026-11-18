import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flow_day/app/app.dart';
import 'package:flow_day/core/providers/database_providers.dart';
import 'package:flow_day/features/home/presentation/home_screen.dart';
import 'package:flow_day/features/tasks/domain/entities/task.dart';
import 'package:flow_day/features/tasks/domain/repositories/task_repository.dart';

class _FakeTaskRepository implements TaskRepository {
  @override
  Future<Task?> getTaskById(String id) async => null;

  @override
  Future<List<Task>> getTasksForDate(String dateKey) async => [];

  @override
  Stream<List<Task>> watchTasksForDate(String dateKey) =>
      Stream.value(<Task>[]);

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
  testWidgets('FlowDayApp boots and displays 4 bottom navigation tabs when onboarding is completed', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'onboarding_done': true,
      'user_name': 'Khushi',
    });
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          taskRepositoryProvider.overrideWithValue(_FakeTaskRepository()),
        ],
        child: const FlowDayApp(),
      ),
    );

    // Allow splash timer to complete and route to /home
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pumpAndSettle();

    // Verify all 4 tab buttons exist in bottom nav bar
    expect(find.byKey(const ValueKey('tab_home')), findsOneWidget);
    expect(find.byKey(const ValueKey('tab_schedule')), findsOneWidget);
    expect(find.byKey(const ValueKey('tab_insights')), findsOneWidget);
    expect(find.byKey(const ValueKey('tab_settings')), findsOneWidget);

    // Verify initial home screen content
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('No tasks scheduled'), findsWidgets);

    // Switch to Schedule tab
    await tester.tap(find.byKey(const ValueKey('tab_schedule')));
    await tester.pumpAndSettle();
    expect(find.text('Daily Timeline & Agenda (Screen 08)'), findsOneWidget);

    // Switch to Insights tab
    await tester.tap(find.byKey(const ValueKey('tab_insights')));
    await tester.pumpAndSettle();
    expect(find.text('Productivity & Habits (Screen 23)'), findsOneWidget);

    // Switch to Settings tab
    await tester.tap(find.byKey(const ValueKey('tab_settings')));
    await tester.pumpAndSettle();
    expect(find.text('Preferences & Schedule (Screen 24)'), findsOneWidget);
  });
}
