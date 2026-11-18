import 'package:sqflite/sqflite.dart';
import '../../domain/entities/reschedule_batch.dart';
import '../../domain/entities/reschedule_change.dart';
import '../../domain/repositories/reschedule_repository.dart';

/// SQLite implementation of [RescheduleRepository].
class SqliteRescheduleRepository implements RescheduleRepository {
  const SqliteRescheduleRepository(this._db);

  final Database _db;

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
}
