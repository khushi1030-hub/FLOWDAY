import 'package:flutter_test/flutter_test.dart';
import 'package:flow_day/core/time/day_window.dart';
import 'package:flow_day/features/schedule/domain/services/free_gap_calculator.dart';
import 'package:flow_day/features/tasks/domain/entities/task.dart';

void main() {
  group('FreeGapCalculator Tests (Decision D16)', () {
    const window = DayWindow(startMin: 420, endMin: 1380); // 07:00 AM to 11:00 PM (420 to 1380)

    Task makeTask(String id, int start, int end, {String status = 'pending'}) {
      return Task(
        id: id,
        title: 'Task $id',
        dateKey: '2026-11-19',
        startMin: start,
        endMin: end,
        status: status,
        createdAt: 1000,
        updatedAt: 1000,
      );
    }

    test('Empty day: entire waking hours is one free gap', () {
      final gaps = FreeGapCalculator.calculateGaps(tasks: [], dayWindow: window);
      expect(gaps.length, 1);
      expect(gaps[0].startMin, 420);
      expect(gaps[0].endMin, 1380);
      expect(gaps[0].durationMin, 960);
    });

    test('Gaps under 15 minutes are excluded as transition buffers', () {
      // Task 1: 08:00 - 09:00 (480 - 540)
      // Task 2: 09:10 - 10:00 (550 - 600) -> 10m gap between 540 and 550 (< 15m!)
      final tasks = [
        makeTask('1', 480, 540),
        makeTask('2', 550, 600),
      ];

      final gaps = FreeGapCalculator.calculateGaps(tasks: tasks, dayWindow: window);
      // Gaps should be:
      // 1. 420 to 480 (60m) -> before Task 1
      // 2. 600 to 1380 (780m) -> after Task 2
      // The 10m gap between 540 and 550 is excluded!
      expect(gaps.length, 2);
      expect(gaps[0].startMin, 420);
      expect(gaps[0].endMin, 480);
      expect(gaps[1].startMin, 600);
      expect(gaps[1].endMin, 1380);
    });

    test('Gap exactly 15 minutes is included', () {
      // Gap between 540 and 555 is exactly 15m
      final tasks = [
        makeTask('1', 420, 540),
        makeTask('2', 555, 600),
      ];

      final gaps = FreeGapCalculator.calculateGaps(tasks: tasks, dayWindow: window);
      expect(gaps.any((g) => g.startMin == 540 && g.endMin == 555 && g.durationMin == 15), isTrue);
    });

    test('Back-to-back tasks leave 0 gaps between them', () {
      final tasks = [
        makeTask('1', 420, 500),
        makeTask('2', 500, 600),
        makeTask('3', 600, 1380),
      ];

      final gaps = FreeGapCalculator.calculateGaps(tasks: tasks, dayWindow: window);
      expect(gaps, isEmpty);
    });

    test('Skipped tasks do not block free time', () {
      // If Task 2 is skipped, time slot 500 - 600 is free!
      final tasks = [
        makeTask('1', 420, 500),
        makeTask('2', 500, 600, status: 'skipped'),
        makeTask('3', 700, 1380),
      ];

      final gaps = FreeGapCalculator.calculateGaps(tasks: tasks, dayWindow: window);
      // Gap from 500 to 700 (200m)
      expect(gaps.length, 1);
      expect(gaps[0].startMin, 500);
      expect(gaps[0].endMin, 700);
      expect(gaps[0].durationMin, 200);
    });
  });
}
