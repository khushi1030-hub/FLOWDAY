import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/notifications/domain/notification_scheduler.dart';
import '../../../../core/providers/database_providers.dart';
import '../../../../core/providers/notification_providers.dart';
import '../../../tasks/data/repositories/sqlite_task_repository.dart';
import '../../../tasks/domain/entities/task.dart';
import '../../domain/entities/reschedule_batch.dart';
import '../../domain/entities/reschedule_proposal.dart';
import '../../domain/rescheduling_engine.dart';

/// Provider for the pure Dart rescheduling engine.
final reschedulingEngineProvider = Provider<ReschedulingEngine>((ref) {
  return const ReschedulingEngine();
});

/// Input parameters for the Smart Rescheduling screen.
class RescheduleScreenParams {
  const RescheduleScreenParams({
    this.triggerTaskId,
    this.extraMinutes = 30,
    this.newConflictingTask,
    this.dateKey,
  });

  final String? triggerTaskId;
  final int extraMinutes;
  final Task? newConflictingTask;
  final String? dateKey;

  bool get isConflictVariant => newConflictingTask != null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RescheduleScreenParams &&
          runtimeType == other.runtimeType &&
          triggerTaskId == other.triggerTaskId &&
          extraMinutes == other.extraMinutes &&
          newConflictingTask?.id == other.newConflictingTask?.id &&
          dateKey == other.dateKey;

  @override
  int get hashCode =>
      (triggerTaskId?.hashCode ?? 0) ^
      extraMinutes.hashCode ^
      (newConflictingTask?.id.hashCode ?? 0) ^
      (dateKey?.hashCode ?? 0);
}

/// Provider computing proposal strategies for the given parameters.
final rescheduleProposalsProvider =
    FutureProvider.autoDispose.family<List<RescheduleProposal>, RescheduleScreenParams>((ref, params) async {
  final engine = ref.watch(reschedulingEngineProvider);
  final clock = ref.watch(clockProvider);
  final taskRepo = ref.watch(taskRepositoryProvider);
  final settingsAsync = ref.watch(settingsStateProvider);
  final settings = settingsAsync.value;

  final todayKey = params.dateKey ?? clock.currentDateKey;
  final todayDate = NotificationScheduler.parseDateKey(todayKey);
  final tomorrowDate = todayDate.add(const Duration(days: 1));
  final tomorrowKey = NotificationScheduler.formatDateKey(tomorrowDate);

  final todayTasks = await taskRepo.getTasksForDate(todayKey);
  final tomorrowTasks = await taskRepo.getTasksForDate(tomorrowKey);

  final dayStart = settings?.wakeMin ?? 420; // 07:00 default
  final dayEnd = settings?.sleepMin ?? 1380; // 23:00 default

  // Screen 19: Conflict variant when adding a new conflicting task
  if (params.newConflictingTask != null) {
    return engine.generateConflictProposals(
      currentDayTasks: todayTasks,
      newConflictingTask: params.newConflictingTask!,
      dayStartMin: dayStart,
      dayEndMin: dayEnd,
      todayDateKey: todayKey,
      tomorrowDateKey: tomorrowKey,
      tomorrowTasks: tomorrowTasks,
    );
  }

  // Screen 16: Delayed / Extra Time extension
  Task? trigger;
  if (params.triggerTaskId != null) {
    trigger = todayTasks.where((t) => t.id == params.triggerTaskId).firstOrNull;
    trigger ??= await taskRepo.getTaskById(params.triggerTaskId!);
  }

  if (trigger == null) {
    // If no trigger task specified, find first overdue/delayed task
    final currentMin = clock.currentMinutesSinceMidnight;
    trigger = todayTasks
        .where((t) => t.status != 'completed' && t.status != 'skipped' && t.endMin <= currentMin)
        .firstOrNull;
  }

  if (trigger == null && todayTasks.isNotEmpty) {
    trigger = todayTasks.first;
  }

  if (trigger == null) {
    return [
      RescheduleProposal.noValidSchedule(
        id: 'A',
        reason: 'No tasks found on schedule to reschedule.',
      ),
    ];
  }

  return engine.generateProposals(
    currentDayTasks: todayTasks,
    triggerTask: trigger,
    extraMinutes: params.extraMinutes,
    dayStartMin: dayStart,
    dayEndMin: dayEnd,
    todayDateKey: todayKey,
    tomorrowDateKey: tomorrowKey,
    tomorrowTasks: tomorrowTasks,
  );
});

/// Tracks the currently selected proposal ID ('A', 'B', 'C', 'D').
class SelectedProposalIdNotifier extends Notifier<String> {
  @override
  String build() => 'A';

  @override
  set state(String value) => super.state = value;
  void select(String id) => state = id;
}

final selectedProposalIdProvider =
    NotifierProvider<SelectedProposalIdNotifier, String>(SelectedProposalIdNotifier.new);

/// Controller for executing atomic apply and undo actions.
class RescheduleActionNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  /// Applies the selected proposal transactionally.
  Future<RescheduleBatch?> applyProposal({
    required RescheduleProposal proposal,
    required String reason,
    String? triggerTaskId,
  }) async {
    state = const AsyncValue.loading();
    try {
      final rescheduleRepo = ref.read(rescheduleRepositoryProvider);
      final taskRepo = ref.read(taskRepositoryProvider);

      final batch = await rescheduleRepo.applyProposal(
        proposal: proposal,
        reason: reason,
        triggerTaskId: triggerTaskId,
      );

      // Trigger live updates on task streams
      if (taskRepo is SqliteTaskRepository) {
        taskRepo.notifyAll();
      }

      // Resync pending alarms and notifications
      try {
        await ref.read(notificationSchedulerProvider).resyncAll();
      } catch (_) {
        // Safe fallback in test or restricted environments
      }

      state = const AsyncValue.data(null);
      return batch;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Undoes the last active reschedule batch in one transaction.
  Future<void> undoLatestBatch() async {
    state = const AsyncValue.loading();
    try {
      final rescheduleRepo = ref.read(rescheduleRepositoryProvider);
      final taskRepo = ref.read(taskRepositoryProvider);

      await rescheduleRepo.undoLatestBatch();

      if (taskRepo is SqliteTaskRepository) {
        taskRepo.notifyAll();
      }

      try {
        await ref.read(notificationSchedulerProvider).resyncAll();
      } catch (_) {
        // Safe fallback in test environments
      }

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final rescheduleActionProvider =
    NotifierProvider<RescheduleActionNotifier, AsyncValue<void>>(RescheduleActionNotifier.new);
