import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/app_database.dart';
import '../time/app_clock.dart';
import '../../features/tasks/domain/entities/task.dart';
import '../../features/tasks/domain/repositories/task_repository.dart';
import '../../features/tasks/domain/repositories/category_repository.dart';
import '../../features/tasks/domain/repositories/task_event_repository.dart';
import '../../features/tasks/data/repositories/sqlite_task_repository.dart';
import '../../features/tasks/data/repositories/sqlite_category_repository.dart';
import '../../features/tasks/data/repositories/sqlite_task_event_repository.dart';
import '../../features/focus/domain/repositories/focus_session_repository.dart';
import '../../features/focus/data/repositories/sqlite_focus_session_repository.dart';
import '../../features/review/domain/repositories/day_confirmation_repository.dart';
import '../../features/review/data/repositories/sqlite_day_confirmation_repository.dart';
import '../../features/rescheduling/domain/repositories/reschedule_repository.dart';
import '../../features/rescheduling/data/repositories/sqlite_reschedule_repository.dart';
import '../../features/settings/domain/entities/app_settings.dart';
import '../../features/settings/domain/repositories/settings_repository.dart';
import '../../features/settings/data/repositories/shared_preferences_settings_repository.dart';

/// AppDatabase provider, overridden at app startup.
final databaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError('databaseProvider must be overridden in ProviderScope');
});

/// SharedPreferences provider, overridden at app startup.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden in ProviderScope');
});

/// System clock provider, defaults to SystemClock(). Can be overridden with FakeClock in tests.
final clockProvider = Provider<AppClock>((ref) {
  return const SystemClock();
});

/// Task repository provider.
final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  final appDb = ref.watch(databaseProvider);
  final clock = ref.watch(clockProvider);
  final repo = SqliteTaskRepository(appDb.db, clock);
  ref.onDispose(repo.dispose);
  return repo;
});

/// Category repository provider.
final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  final appDb = ref.watch(databaseProvider);
  return SqliteCategoryRepository(appDb.db);
});

/// Task event audit repository provider.
final taskEventRepositoryProvider = Provider<TaskEventRepository>((ref) {
  final appDb = ref.watch(databaseProvider);
  return SqliteTaskEventRepository(appDb.db);
});

/// Focus session repository provider.
final focusSessionRepositoryProvider = Provider<FocusSessionRepository>((ref) {
  final appDb = ref.watch(databaseProvider);
  return SqliteFocusSessionRepository(appDb.db);
});

/// Day confirmation repository provider.
final dayConfirmationRepositoryProvider = Provider<DayConfirmationRepository>((ref) {
  final appDb = ref.watch(databaseProvider);
  final clock = ref.watch(clockProvider);
  return SqliteDayConfirmationRepository(appDb.db, clock);
});

/// Reschedule repository provider.
final rescheduleRepositoryProvider = Provider<RescheduleRepository>((ref) {
  final appDb = ref.watch(databaseProvider);
  return SqliteRescheduleRepository(appDb.db);
});

/// Settings repository provider.
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final repo = SharedPreferencesSettingsRepository(prefs);
  ref.onDispose(repo.dispose);
  return repo;
});

/// Reactive stream of AppSettings.
final settingsStateProvider = StreamProvider<AppSettings>((ref) {
  final repo = ref.watch(settingsRepositoryProvider);
  return repo.watchSettings();
});

/// Reactive stream of tasks for a given dateKey ('YYYY-MM-DD').
final tasksForDayProvider = StreamProvider.family<List<Task>, String>((ref, dateKey) {
  final repo = ref.watch(taskRepositoryProvider);
  return repo.watchTasksForDate(dateKey);
});
