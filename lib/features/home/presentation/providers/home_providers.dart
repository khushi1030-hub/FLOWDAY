import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/database_providers.dart';
import '../../domain/home_dashboard_state.dart';

/// Riverpod provider delivering real-time Home Dashboard state.
///
/// Reacts to:
/// - Task changes for today ([tasksForDayProvider])
/// - Minute-ticks from the Clock ([minuteTickProvider])
/// - User preferences ([settingsStateProvider])
final homeDashboardProvider = Provider.autoDispose<AsyncValue<HomeDashboardState>>((ref) {
  final clock = ref.watch(clockProvider);
  final tickAsync = ref.watch(minuteTickProvider);
  final now = tickAsync.value ?? clock.now();
  final y = now.year.toString().padLeft(4, '0');
  final m = now.month.toString().padLeft(2, '0');
  final d = now.day.toString().padLeft(2, '0');
  final dateKey = '$y-$m-$d';

  final settingsAsync = ref.watch(settingsStateProvider);
  final tasksAsync = ref.watch(tasksForDayProvider(dateKey));

  if (tasksAsync.hasError) {
    return AsyncError(tasksAsync.error!, tasksAsync.stackTrace ?? StackTrace.current);
  }
  if (settingsAsync.hasError) {
    return AsyncError(settingsAsync.error!, settingsAsync.stackTrace ?? StackTrace.current);
  }

  if ((tasksAsync.isLoading && !tasksAsync.hasValue) ||
      (settingsAsync.isLoading && !settingsAsync.hasValue)) {
    return const AsyncLoading();
  }

  final tasks = tasksAsync.value ?? [];
  final userName = settingsAsync.value?.userName ?? '';

  final state = HomeDashboardState.compute(
    dateKey: dateKey,
    tasks: tasks,
    now: now,
    userName: userName,
  );

  return AsyncData(state);
});
