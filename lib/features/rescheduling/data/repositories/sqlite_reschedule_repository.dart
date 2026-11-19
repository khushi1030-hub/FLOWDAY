import 'package:sqflite/sqflite.dart';
import '../../../../core/time/app_clock.dart';
import '../../../tasks/domain/entities/task.dart';
import '../../../tasks/domain/entities/task_event.dart';
import '../../domain/entities/reschedule_batch.dart';
import '../../domain/entities/reschedule_change.dart';
import '../../domain/entities/reschedule_proposal.dart';
import '../../domain/repositories/reschedule_repository.dart';

/// SQLite implementation of [RescheduleRepository] with atomic multi-table transactions.
class SqliteRescheduleRepository implements RescheduleRepository {
  SqliteRescheduleRepository(this._db, [AppClock? clock]) : _clock = clock ?? const SystemClock();

  final Database _db;
  final AppClock _clock;

  /// Callbacks to sync with NotificationScheduler and notify stream listeners
  void Function(RescheduleBatch batch)? onBatchApplied;
  void Function(RescheduleBatch batch)? onBatchUndone;

  @override
  Future<void> createBatch(RescheduleBatch batch) async {
    await _db.transaction((txn) async {
      await txn.insert(
        'reschedule_batches',
        batch.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      for (final change in batch.changes) {
        await txn.insert(
          'reschedule_changes',
          change.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  @override
  Future<RescheduleBatch?> getBatchById(String id) async {
    final batchRows = await _db.query(
      'reschedule_batches',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (batchRows.isEmpty) return null;

    final changeRows = await _db.query(
      'reschedule_changes',
      where: 'batch_id = ?',
      whereArgs: [id],
      orderBy: 'id ASC',
    );
    final changes = changeRows.map(RescheduleChange.fromMap).toList();

    return RescheduleBatch.fromMap(batchRows.first, changes);
  }

  @override
  Future<RescheduleBatch?> getLatestBatch() async {
    final batchRows = await _db.query(
      'reschedule_batches',
      orderBy: 'created_at DESC',
      limit: 1,
    );
    if (batchRows.isEmpty) return null;

    final batchId = batchRows.first['id'] as String;
    final changeRows = await _db.query(
      'reschedule_changes',
      where: 'batch_id = ?',
      whereArgs: [batchId],
      orderBy: 'id ASC',
    );
    final changes = changeRows.map(RescheduleChange.fromMap).toList();

    return RescheduleBatch.fromMap(batchRows.first, changes);
  }

  @override
  Future<void> markBatchUndone(String id, int undoneAt) async {
    await _db.update(
      'reschedule_batches',
      {'undone_at': undoneAt},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<List<RescheduleBatch>> getAllBatches() async {
    final batchRows = await _db.query('reschedule_batches', orderBy: 'created_at DESC');
    final batches = <RescheduleBatch>[];

    for (final row in batchRows) {
      final batchId = row['id'] as String;
      final changeRows = await _db.query(
        'reschedule_changes',
        where: 'batch_id = ?',
        whereArgs: [batchId],
        orderBy: 'id ASC',
      );
      final changes = changeRows.map(RescheduleChange.fromMap).toList();
      batches.add(RescheduleBatch.fromMap(row, changes));
    }

    return batches;
  }

  @override
  Future<RescheduleBatch> applyProposal({
    required RescheduleProposal proposal,
    required String reason,
    String? triggerTaskId,
    int? simulatedFailureStep,
  }) async {
    final nowMs = _clock.now().millisecondsSinceEpoch;
    final batchId = 'batch_${nowMs}_${proposal.id}';

    final batch = RescheduleBatch(
      id: batchId,
      reason: reason,
      triggerTaskId: triggerTaskId,
      proposalLabel: 'Plan ${proposal.id}: ${proposal.title}',
      createdAt: nowMs,
      changes: proposal.moves.where((m) => m.isShifted).map((m) {
        return RescheduleChange(
          batchId: batchId,
          taskId: m.taskId,
          oldDateKey: m.oldDateKey,
          oldStartMin: m.oldStartMin,
          oldEndMin: m.oldEndMin,
          newDateKey: m.newDateKey,
          newStartMin: m.newStartMin,
          newEndMin: m.newEndMin,
        );
      }).toList(),
    );

    await _db.transaction((txn) async {
      // 1. Stale checks: re-query current tasks from DB inside txn
      for (final move in proposal.moves) {
        final rows = await txn.query('tasks', where: 'id = ?', whereArgs: [move.taskId], limit: 1);
        if (rows.isEmpty) {
          throw RescheduleStaleException('Task "${move.taskTitle}" no longer exists.');
        }
        final currentTask = Task.fromMap(rows.first);
        if (currentTask.startMin != move.oldStartMin ||
            currentTask.endMin != move.oldEndMin ||
            currentTask.dateKey != move.oldDateKey) {
          throw RescheduleStaleException('Task "${move.taskTitle}" was modified before proposal could be applied.');
        }
      }

      // Simulated failure 1 (for unit testing transaction rollback)
      if (simulatedFailureStep == 1) {
        throw Exception('Simulated failure during reschedule transaction');
      }

      // 2. Insert batch record
      await txn.insert('reschedule_batches', batch.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);

      // 3. Insert change records
      for (final change in batch.changes) {
        await txn.insert('reschedule_changes', change.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      }

      // 4. Update tasks
      for (final move in proposal.moves) {
        final isDifferentDate = move.oldDateKey != move.newDateKey;
        final updates = <String, dynamic>{
          'date_key': move.newDateKey,
          'start_min': move.newStartMin,
          'end_min': move.newEndMin,
          'was_rescheduled': 1,
          'updated_at': nowMs,
        };
        if (isDifferentDate) {
          updates['status'] = 'rescheduled';
          updates['carried_from_date_key'] = move.oldDateKey;
        }

        await txn.update(
          'tasks',
          updates,
          where: 'id = ?',
          whereArgs: [move.taskId],
        );

        // Record task_events
        final event = TaskEvent(
          taskId: move.taskId,
          taskTitle: move.taskTitle,
          dateKey: move.newDateKey,
          eventType: isDifferentDate ? 'postponed' : 'rescheduled',
          plannedMinutes: move.newDurationMin,
          occurredAt: nowMs,
        );
        await txn.insert('task_events', event.toMap());

        // If tomorrow touched, un-confirm tomorrow
        if (isDifferentDate) {
          await txn.update(
            'day_confirmations',
            {'confirmed': 0},
            where: 'date_key = ?',
            whereArgs: [move.newDateKey],
          );
        }
      }
    });

    onBatchApplied?.call(batch);
    return batch;
  }

  @override
  Future<void> undoBatch(String batchId, {int? simulatedFailureStep}) async {
    final batch = await getBatchById(batchId);
    if (batch == null) {
      throw NoBatchToUndoException('Reschedule batch "$batchId" not found.');
    }
    if (batch.isUndone) {
      throw const UndoBlockedException('This reschedule batch has already been undone.');
    }

    final nowMs = _clock.now().millisecondsSinceEpoch;

    // Safety check: verify no task was modified since the batch was applied
    for (final change in batch.changes) {
      final rows = await _db.query('tasks', where: 'id = ?', whereArgs: [change.taskId], limit: 1);
      if (rows.isEmpty) {
        throw UndoBlockedException('Undo blocked: task "${change.taskId}" was deleted.');
      }
      final currentTask = Task.fromMap(rows.first);
      if (currentTask.updatedAt > batch.createdAt) {
        throw UndoBlockedException('Undo blocked: task "${currentTask.title}" was modified after rescheduling.');
      }
    }

    await _db.transaction((txn) async {
      if (simulatedFailureStep == 2) {
        throw Exception('Simulated failure during undo transaction');
      }

      for (final change in batch.changes) {
        await txn.update(
          'tasks',
          {
            'date_key': change.oldDateKey,
            'start_min': change.oldStartMin,
            'end_min': change.oldEndMin,
            'updated_at': nowMs,
          },
          where: 'id = ?',
          whereArgs: [change.taskId],
        );

        final event = TaskEvent(
          taskId: change.taskId,
          taskTitle: 'Restored Task',
          dateKey: change.oldDateKey,
          eventType: 'rescheduled',
          plannedMinutes: change.oldEndMin - change.oldStartMin,
          occurredAt: nowMs,
        );
        await txn.insert('task_events', event.toMap());
      }

      // Mark batch undone
      await txn.update(
        'reschedule_batches',
        {'undone_at': nowMs},
        where: 'id = ?',
        whereArgs: [batchId],
      );
    });

    onBatchUndone?.call(batch);
  }

  @override
  Future<void> undoLatestBatch({int? simulatedFailureStep}) async {
    final batch = await getLatestBatch();
    if (batch == null || batch.isUndone) {
      throw const NoBatchToUndoException('No active reschedule operation to undo.');
    }
    await undoBatch(batch.id, simulatedFailureStep: simulatedFailureStep);
  }
}
