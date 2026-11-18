/// Domain entity representing a confirmed day schedule from nightly review.
class DayConfirmation {
  const DayConfirmation({
    required this.dateKey,
    this.confirmed = false,
    this.confirmedAt,
  });

  final String dateKey;
  final bool confirmed;
  final int? confirmedAt; // epoch milliseconds UTC

  DayConfirmation copyWith({
    String? dateKey,
    bool? confirmed,
    int? confirmedAt,
  }) {
    return DayConfirmation(
      dateKey: dateKey ?? this.dateKey,
      confirmed: confirmed ?? this.confirmed,
      confirmedAt: confirmedAt ?? this.confirmedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date_key': dateKey,
      'confirmed': confirmed ? 1 : 0,
      'confirmed_at': confirmedAt,
    };
  }

  factory DayConfirmation.fromMap(Map<String, dynamic> map) {
    return DayConfirmation(
      dateKey: map['date_key'] as String,
      confirmed: (map['confirmed'] as int? ?? 0) == 1,
      confirmedAt: map['confirmed_at'] as int?,
    );
  }
}
