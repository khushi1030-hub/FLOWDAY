import 'package:sqflite/sqflite.dart';
import '../../domain/entities/day_confirmation.dart';
import '../../domain/repositories/day_confirmation_repository.dart';

/// SQLite implementation of [DayConfirmationRepository].
class SqliteDayConfirmationRepository implements DayConfirmationRepository {
  const SqliteDayConfirmationRepository(this._db);

  final Database _db;

  @override
  Future<DayConfirmation?> getConfirmation(String dateKey) async {
    final rows = await _db.query(
      'day_confirmations',
      where: 'date_key = ?',
      whereArgs: [dateKey],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return DayConfirmation.fromMap(rows.first);
  }

  @override
  Future<void> setConfirmation(String dateKey, bool confirmed, [int? confirmedAt]) async {
    await _db.insert(
      'day_confirmations',
      {
        'date_key': dateKey,
        'confirmed': confirmed ? 1 : 0,
        'confirmed_at': confirmedAt ?? (confirmed ? DateTime.now().millisecondsSinceEpoch : null),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> unconfirmDay(String dateKey) async {
    await setConfirmation(dateKey, false, null);
  }

  @override
  Future<List<DayConfirmation>> getAllConfirmations() async {
    final rows = await _db.query('day_confirmations', orderBy: 'date_key DESC');
    return rows.map(DayConfirmation.fromMap).toList();
  }
}
