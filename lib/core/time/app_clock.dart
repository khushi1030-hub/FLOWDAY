/// Abstraction over system time for deterministic scheduling and testing.
abstract class AppClock {
  DateTime now();

  /// Minutes from midnight (0..1439) for the current moment.
  int get currentMinutesSinceMidnight {
    final current = now();
    return current.hour * 60 + current.minute;
  }

  /// Current date key in 'YYYY-MM-DD' format.
  String get currentDateKey {
    final current = now();
    final y = current.year.toString().padLeft(4, '0');
    final m = current.month.toString().padLeft(2, '0');
    final d = current.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}

/// Standard production clock delegating to system time.
class SystemClock implements AppClock {
  const SystemClock();

  @override
  DateTime now() => DateTime.now();

  @override
  int get currentMinutesSinceMidnight {
    final current = DateTime.now();
    return current.hour * 60 + current.minute;
  }

  @override
  String get currentDateKey {
    final current = DateTime.now();
    final y = current.year.toString().padLeft(4, '0');
    final m = current.month.toString().padLeft(2, '0');
    final d = current.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}

/// Settable clock for deterministic unit and property tests.
class FakeClock implements AppClock {
  FakeClock([DateTime? initialTime]) : _now = initialTime ?? DateTime(2026, 11, 17, 9, 0);

  DateTime _now;

  @override
  DateTime now() => _now;

  void setNow(DateTime dt) {
    _now = dt;
  }

  void advance(Duration duration) {
    _now = _now.add(duration);
  }

  @override
  int get currentMinutesSinceMidnight {
    return _now.hour * 60 + _now.minute;
  }

  @override
  String get currentDateKey {
    final y = _now.year.toString().padLeft(4, '0');
    final m = _now.month.toString().padLeft(2, '0');
    final d = _now.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
