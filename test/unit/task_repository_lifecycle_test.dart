import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flow_day/core/database/app_database.dart';
import 'package:flow_day/core/time/app_clock.dart';
import 'package:flow_day/features/tasks/data/repositories/sqlite_task_repository.dart';
import 'package:flow_day/features/tasks/domain/entities/task.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('Task Repository Lifecycle & History Events (Phase 4)', () {
    late Database db;
    late FakeClock fakeClock;
    late SqliteTaskRepository taskRepo;

    final fixedTime = DateTime(2026, 11, 19, 10, 0); // 10:00 AM

    setUp(() async {
      fakeClock = FakeClock(fixedTime);
      db = await databaseFactoryFfi.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(
          version: AppDatabase.schemaVersion,
          onConfigure: (database) async {
            await database.execute('PRAGMA foreign_keys = ON;');
          },
          onCreate: (database, version) async {
            await AppDatabase.initializeDatabase(database);
          },
        ),
      );

      taskRepo = SqliteTaskRepository(db, fakeClock);
    });

    tearDown(() async {
      await db.close();
    });

    test('Creating a task persists task and logs "created" event', () async {
      final task = Task(
        id: 'task-create-1',
        title: 'Study Flutter State Management',
        dateKey: '2026-11-19',
        startMin: 600, // 10:00 AM
        endMin: 660, // 11:00 AM
        priority: 2,
        categoryId: 1,
        alarmEnabled: true,
        reminderOffsetMin: 10,
        createdAt: fixedTime.millisecondsSinceEpoch,
        updatedAt: fixedTime.millisecondsSinceEpoch,
      );

      await taskRepo.insertTask(task);

      final retrieved = await taskRepo.getTaskById('task-create-1');
      expect(retrieved, isNotNull);
      expect(retrieved!.title, 'Study Flutter State Management');
      expect(retrieved.status, 'pending');
      expect(retrieved.priority, 2);
      expect(retrieved.durationMin, 60);

      // Verify task_events audit row
      final events = await db.query(
        'task_events',
        where: 'task_id = ?',
        whereArgs: ['task-create-1'],
      );
      expect(events.length, 1);
      expect(events.first['event_type'], 'created');
      expect(events.first['task_title'], 'Study Flutter State Management');
      expect(events.first['planned_minutes'], 60);
    });

    test('Editing a task updates attributes and logs "edited" event', () async {
      final task = Task(
        id: 'task-edit-1',
        title: 'Initial Title',
        dateKey: '2026-11-19',
        startMin: 600,
        endMin: 645,
        priority: 1,
        createdAt: fixedTime.millisecondsSinceEpoch,
        updatedAt: fixedTime.millisecondsSinceEpoch,
      );
      await taskRepo.insertTask(task);

      // Advance clock
      fakeClock.setNow(DateTime(2026, 11, 19, 10, 15));
      final updatedTask = task.copyWith(
        title: 'Updated Title',
        endMin: 660, // 60 min duration
        hasConflict: true,
      );
      await taskRepo.updateTask(updatedTask);

      final retrieved = await taskRepo.getTaskById('task-edit-1');
      expect(retrieved!.title, 'Updated Title');
      expect(retrieved.endMin, 660);
      expect(retrieved.hasConflict, isTrue);

      // Check task_events for edited row
      final events = await db.query(
        'task_events',
        where: 'task_id = ?',
        whereArgs: ['task-edit-1'],
        orderBy: 'occurred_at ASC',
      );
      expect(events.length, 2); // created + edited
      expect(events.last['event_type'], 'edited');
      expect(events.last['task_title'], 'Updated Title');
      expect(events.last['planned_minutes'], 60);
    });

    test('Completing a task updates status and writes task history row', () async {
      final task = Task(
        id: 'task-complete-1',
        title: 'Sprint Retrospective',
        dateKey: '2026-11-19',
        startMin: 720, // 12:00 PM
        endMin: 750, // 12:30 PM (30 min)
        createdAt: fixedTime.millisecondsSinceEpoch,
        updatedAt: fixedTime.millisecondsSinceEpoch,
      );
      await taskRepo.insertTask(task);

      final completionTimestamp = DateTime(2026, 11, 19, 12, 30).millisecondsSinceEpoch;
      await taskRepo.markCompleted('task-complete-1', completionTimestamp);

      final completedTask = await taskRepo.getTaskById('task-complete-1');
      expect(completedTask!.status, 'completed');
      expect(completedTask.completedAt, completionTimestamp);

      // Verify task history row written on completion per Phase 4 exit check
      final events = await db.query(
        'task_events',
        where: 'task_id = ? AND event_type = ?',
        whereArgs: ['task-complete-1', 'completed'],
      );
      expect(events.length, 1);
      final event = events.first;
      expect(event['task_title'], 'Sprint Retrospective');
      expect(event['planned_minutes'], 30);
      expect(event['actual_minutes'], 30);
      expect(event['occurred_at'], completionTimestamp);
    });

    test('Marking a task incomplete reverts status, removes stale completed row, and logs "marked_incomplete" event', () async {
      final task = Task(
        id: 'task-incomplete-1',
        title: 'Review PRs',
        dateKey: '2026-11-19',
        startMin: 800,
        endMin: 830,
        createdAt: fixedTime.millisecondsSinceEpoch,
        updatedAt: fixedTime.millisecondsSinceEpoch,
      );
      await taskRepo.insertTask(task);
      await taskRepo.markCompleted('task-incomplete-1', fixedTime.millisecondsSinceEpoch);

      // Verify 'completed' event exists before un-completing
      final completedEventsBefore = await db.query(
        'task_events',
        where: 'task_id = ? AND event_type = ?',
        whereArgs: ['task-incomplete-1', 'completed'],
      );
      expect(completedEventsBefore.length, 1);

      // Now mark incomplete (swipe left)
      await taskRepo.markIncomplete('task-incomplete-1');

      final taskAfter = await taskRepo.getTaskById('task-incomplete-1');
      expect(taskAfter!.status, 'incomplete');
      expect(taskAfter.completedAt, isNull);

      // Stale 'completed' event MUST be removed
      final completedEventsAfter = await db.query(
        'task_events',
        where: 'task_id = ? AND event_type = ?',
        whereArgs: ['task-incomplete-1', 'completed'],
      );
      expect(completedEventsAfter, isEmpty, reason: 'Stale completed event must not remain');

      final events = await db.query(
        'task_events',
        where: 'task_id = ? AND event_type = ?',
        whereArgs: ['task-incomplete-1', 'marked_incomplete'],
      );
      expect(events.length, 1);
    });

    test('Completing task is transactional: forced error rolls back both status and history row', () async {
      final task = Task(
        id: 'task-rollback-1',
        title: 'Mission Critical Task',
        dateKey: '2026-11-19',
        startMin: 500,
        endMin: 560,
        createdAt: fixedTime.millisecondsSinceEpoch,
        updatedAt: fixedTime.millisecondsSinceEpoch,
      );
      await taskRepo.insertTask(task);

      // Simulate a forced failure inside completion transaction
      try {
        await db.transaction((txn) async {
          await txn.update(
            'tasks',
            {'status': 'completed', 'completed_at': 123456789},
            where: 'id = ?',
            whereArgs: ['task-rollback-1'],
          );

          // Force an intentional error
          throw Exception('Forced DB Error inside completion transaction');
        });
      } catch (_) {}

      // Verify rollback: task is still pending and not completed
      final taskAfter = await taskRepo.getTaskById('task-rollback-1');
      expect(taskAfter!.status, 'pending');
      expect(taskAfter.completedAt, isNull);

      final events = await db.query(
        'task_events',
        where: 'task_id = ? AND event_type = ?',
        whereArgs: ['task-rollback-1', 'completed'],
      );
      expect(events, isEmpty);
    });

    test('Deleting a task triggers reminder cancellation hook, deletes task, and preserves history', () async {
      final task = Task(
        id: 'task-delete-hook-1',
        title: 'Cancelable Reminder Task',
        dateKey: '2026-11-19',
        startMin: 900,
        endMin: 930,
        createdAt: fixedTime.millisecondsSinceEpoch,
        updatedAt: fixedTime.millisecondsSinceEpoch,
      );
      await taskRepo.insertTask(task);

      String? cancelledTaskId;
      taskRepo.onTaskDeleted = (id) async {
        cancelledTaskId = id;
      };

      await taskRepo.deleteTask('task-delete-hook-1');

      // Hook was invoked
      expect(cancelledTaskId, 'task-delete-hook-1');

      // Task is removed from tasks table
      expect(await taskRepo.getTaskById('task-delete-hook-1'), isNull);

      // History rows (created + deleted) survive without cascade deletion
      final events = await db.query(
        'task_events',
        where: 'task_id = ?',
        whereArgs: ['task-delete-hook-1'],
      );
      expect(events.length, 2); // 'created' and 'deleted'
      expect(events.map((e) => e['event_type']), containsAll(['created', 'deleted']));
    });

    test('Deleting a task removes row and logs "deleted" event', () async {
      final task = Task(
        id: 'task-delete-1',
        title: 'Cancelable Task',
        dateKey: '2026-11-19',
        startMin: 900,
        endMin: 930,
        createdAt: fixedTime.millisecondsSinceEpoch,
        updatedAt: fixedTime.millisecondsSinceEpoch,
      );
      await taskRepo.insertTask(task);
      expect(await taskRepo.getTaskById('task-delete-1'), isNotNull);

      await taskRepo.deleteTask('task-delete-1');
      expect(await taskRepo.getTaskById('task-delete-1'), isNull);

      final events = await db.query(
        'task_events',
        where: 'task_id = ? AND event_type = ?',
        whereArgs: ['task-delete-1', 'deleted'],
      );
      expect(events.length, 1);
    });
  });
}
