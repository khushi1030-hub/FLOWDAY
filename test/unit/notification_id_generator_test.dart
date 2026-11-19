import 'package:flutter_test/flutter_test.dart';
import 'package:flow_day/core/notifications/domain/notification_gateway.dart';
import 'package:flow_day/core/notifications/domain/notification_id_generator.dart';

void main() {
  group('NotificationIdGenerator & FNV-1a Unit Tests (Requirement 1)', () {
    test('FNV-1a 32-bit hash is deterministic and stable across calls', () {
      const taskId = 'task-uuid-1234-abcd';
      final hash1 = NotificationIdGenerator.fnv1a32(taskId);
      final hash2 = NotificationIdGenerator.fnv1a32(taskId);

      expect(hash1, equals(hash2));
      expect(hash1, isNonNegative);
    });

    test('Task notification IDs are stable and deterministic', () {
      const taskId = 't-study-flutter';

      final startId1 = NotificationIdGenerator.getNotificationId(
        taskId,
        NotificationType.startReminder,
      );
      final startId2 = NotificationIdGenerator.getNotificationId(
        taskId,
        NotificationType.startReminder,
      );
      final endId = NotificationIdGenerator.getNotificationId(
        taskId,
        NotificationType.endAlarm,
      );

      expect(startId1, equals(startId2));
      expect(startId1, isNot(equals(endId)));
      expect(startId1 % 10, equals(1)); // Type offset 1
      expect(endId % 10, equals(2)); // Type offset 2
    });

    test('All task IDs remain strictly below the reserved system range (2,000,000,000)', () {
      final sampleTaskIds = List.generate(100, (i) => 'task-id-sample-key-$i');

      for (final id in sampleTaskIds) {
        final startId = NotificationIdGenerator.getNotificationId(
          id,
          NotificationType.startReminder,
        );
        final endId = NotificationIdGenerator.getNotificationId(
          id,
          NotificationType.endAlarm,
        );

        expect(startId, lessThan(kSystemIdMin));
        expect(endId, lessThan(kSystemIdMin));
      }
    });

    test('System IDs are in the reserved 2,000,000,000+ range', () {
      expect(kDailySummaryNotificationId, greaterThanOrEqualTo(kSystemIdMin));
      expect(kNightlyReviewNotificationId, greaterThanOrEqualTo(kSystemIdMin));
      expect(kDailySummaryNotificationId, isNot(equals(kNightlyReviewNotificationId)));
    });

    test('Collision detection probes to the next free ID', () {
      final usedIds = <int>{1001, 1002, 1003};

      final allocated = NotificationIdGenerator.allocateId(
        requestedId: 1001,
        usedIds: usedIds,
      );

      expect(allocated, equals(1004));
      expect(usedIds.contains(1004), isTrue);
    });
  });
}
