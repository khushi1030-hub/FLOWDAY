import '../entities/reschedule_batch.dart';
import '../entities/reschedule_proposal.dart';

/// Thrown when schedule tasks were modified after the proposal was generated.
class RescheduleStaleException implements Exception {
  const RescheduleStaleException([this.message = 'Schedule was modified. Please re-evaluate proposals.']);
  final String message;
  @override
  String toString() => message;
}

/// Thrown when undo cannot be performed because tasks were modified after rescheduling.
class UndoBlockedException implements Exception {
  const UndoBlockedException([this.message = 'Undo not available: schedule was modified since.']);
  final String message;
  @override
  String toString() => message;
}

/// Thrown when there is no active batch to undo.
class NoBatchToUndoException implements Exception {
  const NoBatchToUndoException([this.message = 'No active reschedule batch found to undo.']);
  final String message;
  @override
  String toString() => message;
}

/// Repository interface for reschedule batches, changes, and atomic transactional operations.
abstract class RescheduleRepository {
  Future<void> createBatch(RescheduleBatch batch);
  Future<RescheduleBatch?> getBatchById(String id);
  Future<RescheduleBatch?> getLatestBatch();
  Future<void> markBatchUndone(String id, int undoneAt);
  Future<List<RescheduleBatch>> getAllBatches();

  /// Applies a proposal in a single SQLite transaction with stale checks, batch logging,
  /// task moves, event logging, and day unconfirmation.
  Future<RescheduleBatch> applyProposal({
    required RescheduleProposal proposal,
    required String reason,
    String? triggerTaskId,
    int? simulatedFailureStep,
  });

  /// Undoes a specific reschedule batch, restoring tasks to their original times in one transaction.
  /// Refuses undo if any affected task was modified after the batch was created.
  Future<void> undoBatch(String batchId, {int? simulatedFailureStep});

  /// Undoes the latest un-undone reschedule batch.
  Future<void> undoLatestBatch({int? simulatedFailureStep});
}
