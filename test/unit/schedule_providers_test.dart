import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flow_day/core/providers/database_providers.dart';
import 'package:flow_day/core/time/app_clock.dart';
import 'package:flow_day/features/schedule/presentation/providers/schedule_providers.dart';

void main() {
  group('Schedule Providers - Midnight Rollover & Date Selection (Requirement 6)', () {
    test('Midnight rollover moves selected date to tomorrow if user was viewing today', () async {
      final fakeClock = FakeClock(DateTime(2026, 5, 14, 23, 59));
      final container = ProviderContainer(
        overrides: [
          clockProvider.overrideWithValue(fakeClock),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(fakeClock.dispose);

      // Listen to tick provider and selectedScheduleDateProvider to keep them active
      container.listen(selectedScheduleDateProvider, (_, _) {});

      expect(container.read(selectedScheduleDateProvider), '2026-05-14');

      // Tick to midnight: 00:00 May 15
      fakeClock.setNow(DateTime(2026, 5, 15, 0, 0));
      await Future<void>.delayed(Duration.zero);

      expect(container.read(selectedScheduleDateProvider), '2026-05-15');
    });

    test('Midnight rollover keeps selected date unchanged if user was viewing another day', () async {
      final fakeClock = FakeClock(DateTime(2026, 5, 14, 23, 59));
      final container = ProviderContainer(
        overrides: [
          clockProvider.overrideWithValue(fakeClock),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(fakeClock.dispose);

      container.listen(selectedScheduleDateProvider, (_, _) {});

      // User manually navigates to a different day (e.g. yesterday)
      container.read(selectedScheduleDateProvider.notifier).selectDate('2026-05-10');
      expect(container.read(selectedScheduleDateProvider), '2026-05-10');

      // Tick to midnight
      fakeClock.setNow(DateTime(2026, 5, 15, 0, 0));
      await Future<void>.delayed(Duration.zero);

      // Should still be viewing 2026-05-10
      expect(container.read(selectedScheduleDateProvider), '2026-05-10');
    });

    test('User viewing future day (e.g. next week) stays on that day after midnight rollover', () async {
      final fakeClock = FakeClock(DateTime(2026, 5, 14, 23, 59));
      final container = ProviderContainer(
        overrides: [
          clockProvider.overrideWithValue(fakeClock),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(fakeClock.dispose);

      container.listen(selectedScheduleDateProvider, (_, _) {});

      // User navigates to next week
      container.read(selectedScheduleDateProvider.notifier).selectDate('2026-05-20');
      expect(container.read(selectedScheduleDateProvider), '2026-05-20');

      // Tick past midnight
      fakeClock.setNow(DateTime(2026, 5, 15, 0, 1));
      await Future<void>.delayed(Duration.zero);

      // Must remain on 2026-05-20
      expect(container.read(selectedScheduleDateProvider), '2026-05-20');
    });
  });
}
