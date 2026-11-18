import '../entities/reschedule_batch.dart';

/// Repository interface for reschedule batches and changes.
abstract class RescheduleRepository {
  Future<void> createBatch(RescheduleBatch batch);
  Future<RescheduleBatch?> getBatchById(String id);
  Future<RescheduleBatch?> getLatestBatch();
  Future<void> markBatchUndone(String id, int undoneAt);
  Future<List<RescheduleBatch>> getAllBatches();
}
