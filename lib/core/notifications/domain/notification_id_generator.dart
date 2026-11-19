import 'dart:convert';
import 'notification_gateway.dart';

/// System notification IDs start at 2,000,000,000.
const int kSystemIdMin = 2000000000;
const int kDailySummaryNotificationId = 2000000001;
const int kNightlyReviewNotificationId = 2000000002;

/// FNV-1a 32-bit hash and collision-free ID generator for task notifications.
class NotificationIdGenerator {
  /// Computes the 32-bit FNV-1a hash of a UTF-8 string.
  static int fnv1a32(String input) {
    var hash = 0x811c9dc5;
    final bytes = utf8.encode(input);
    for (final b in bytes) {
      hash ^= b;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    return hash;
  }

  /// Calculates the base ID for a [taskId].
  ///
  /// base = (hash % 190000000).abs()
  static int getBaseId(String taskId) {
    final hash = fnv1a32(taskId);
    return (hash % 190000000).abs();
  }

  /// Calculates the raw notification ID for a task and type.
  ///
  /// id = base * 10 + type.offset
  static int getNotificationId(String taskId, NotificationType type) {
    final base = getBaseId(taskId);
    return base * 10 + type.offset;
  }

  /// Probes for the next available ID if [requestedId] collides with [usedIds].
  ///
  /// Ensures allocated task IDs never intrude on the system range (>= 2,000,000,000).
  static int allocateId({
    required int requestedId,
    required Set<int> usedIds,
  }) {
    var id = requestedId;
    while (usedIds.contains(id) && id < kSystemIdMin) {
      id++;
    }
    usedIds.add(id);
    return id;
  }
}
