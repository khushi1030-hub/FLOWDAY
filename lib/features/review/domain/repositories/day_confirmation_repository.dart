import '../entities/day_confirmation.dart';

/// Repository interface for day confirmations.
abstract class DayConfirmationRepository {
  Future<DayConfirmation?> getConfirmation(String dateKey);
  Future<void> setConfirmation(String dateKey, bool confirmed, [int? confirmedAt]);
  Future<void> unconfirmDay(String dateKey);
  Future<List<DayConfirmation>> getAllConfirmations();
}
