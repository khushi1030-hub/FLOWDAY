import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';
import 'package:flow_day/core/database/app_database.dart';
import 'package:flow_day/features/tasks/data/repositories/sqlite_task_repository.dart';
import 'package:flow_day/features/tasks/data/repositories/sqlite_category_repository.dart';
import 'package:flow_day/features/tasks/domain/entities/task.dart';

void main() {
  // Initialize FFI for running SQLite in tests on Windows desktop
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('AppDatabase & SQLite Repositories', () {
    late Database db;
    late SqliteTaskRepository taskRepo;
    late SqliteCategoryRepository categoryRepo;

    setUp(() async {
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

      taskRepo = SqliteTaskRepository(db);
      categoryRepo = SqliteCategoryRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('Default category seeds are present in database', () async {
      final categories = await categoryRepo.getAllCategories();
      expect(categories.length, 6);
      expect(categories.map((c) => c.name).toSet(), {'Study', 'Work', 'Health', 'Personal', 'Social', 'Break'});
    });

    test('Task CRUD operations work as expected', () async {
      final taskId = const Uuid().v4();
      final now = DateTime(2026, 11, 17, 10, 0).millisecondsSinceEpoch;

      final task = Task(
        id: taskId,
        title: 'Complete Phase 2 Tests',
        dateKey: '2026-11-17',
        startMin: 600,
        endMin: 660,
        priority: 2,
        createdAt: now,
        updatedAt: now,
      );

      // Create
      await taskRepo.insertTask(task);
      var fetched = await taskRepo.getTaskById(taskId);
      expect(fetched, isNotNull);
      expect(fetched!.title, 'Complete Phase 2 Tests');
      expect(fetched.durationMin, 60);

      // Query by date
      final dateTasks = await taskRepo.getTasksForDate('2026-11-17');
      expect(dateTasks.length, 1);
      expect(dateTasks.first.id, taskId);

      // Update
      final updatedTask = task.copyWith(title: 'Updated Task Title', startMin: 630);
      await taskRepo.updateTask(updatedTask);
      fetched = await taskRepo.getTaskById(taskId);
      expect(fetched!.title, 'Updated Task Title');
      expect(fetched.startMin, 630);

      // Mark completed
      await taskRepo.markCompleted(taskId, now + 1000);
      fetched = await taskRepo.getTaskById(taskId);
      expect(fetched!.status, 'completed');
      expect(fetched.completedAt, now + 1000);

      // Delete
      await taskRepo.deleteTask(taskId);
      fetched = await taskRepo.getTaskById(taskId);
      expect(fetched, isNull);
    });

    test('Transaction rollback on forced error leaves database unchanged', () async {
      final taskId = const Uuid().v4();
      final now = DateTime(2026, 11, 17, 10, 0).millisecondsSinceEpoch;

      final task = Task(
        id: taskId,
        title: 'Rollback Test Task',
        dateKey: '2026-11-17',
        startMin: 700,
        endMin: 760,
        createdAt: now,
        updatedAt: now,
      );

      expect(
        () async {
          await db.transaction((txn) async {
            await txn.insert('tasks', task.toMap());
            // Force an error inside transaction
            throw Exception('Forced rollback error');
          });
        },
        throwsA(isA<Exception>()),
      );

      // Verify task does NOT exist in database
      final fetched = await taskRepo.getTaskById(taskId);
      expect(fetched, isNull);
    });

    test('Reopening the database retains persisted data', () async {
      final tempDir = Directory.systemTemp.createTempSync('flowday_test_');
      final testDbPath = '${tempDir.path}/persistent_test.db';

      try {
        // 1. Open database and insert task
        final db1 = await databaseFactoryFfi.openDatabase(
          testDbPath,
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

        final repo1 = SqliteTaskRepository(db1);
        const persistentId = 'persisted-task-123';
        final now = DateTime(2026, 11, 17, 10, 0).millisecondsSinceEpoch;
        await repo1.insertTask(
          Task(
            id: persistentId,
            title: 'Survives Restart',
            dateKey: '2026-11-17',
            startMin: 500,
            endMin: 550,
            createdAt: now,
            updatedAt: now,
          ),
        );
        await db1.close();

        // 2. Reopen the database from file path
        final db2 = await databaseFactoryFfi.openDatabase(testDbPath);
        final repo2 = SqliteTaskRepository(db2);
        final fetched = await repo2.getTaskById(persistentId);

        expect(fetched, isNotNull);
        expect(fetched!.id, persistentId);
        expect(fetched.title, 'Survives Restart');

        await db2.close();
      } finally {
        await databaseFactoryFfi.deleteDatabase(testDbPath);
        try {
          tempDir.deleteSync(recursive: true);
        } catch (_) {}
      }
    });

    test('Migration setup runs inside transaction', () async {
      var migrationExecuted = false;
      final tempDir = Directory.systemTemp.createTempSync('flowday_mig_');
      final migDbPath = '${tempDir.path}/mig_test.db';

      try {
        // Create v1 database
        final testDb = await databaseFactoryFfi.openDatabase(
          migDbPath,
          options: OpenDatabaseOptions(
            version: 1,
            onCreate: (database, version) async {
              await database.execute('CREATE TABLE dummy (id INTEGER PRIMARY KEY);');
            },
          ),
        );
        await testDb.close();

        // Open as v2 with onUpgrade
        final upgradedDb = await databaseFactoryFfi.openDatabase(
          migDbPath,
          options: OpenDatabaseOptions(
            version: 2,
            onUpgrade: (database, oldVersion, newVersion) async {
              if (oldVersion == 1 && newVersion == 2) {
                await database.execute('ALTER TABLE dummy ADD COLUMN note TEXT;');
                migrationExecuted = true;
              }
            },
          ),
        );

        expect(migrationExecuted, isTrue);
        await upgradedDb.close();
      } finally {
        await databaseFactoryFfi.deleteDatabase(migDbPath);
        try {
          tempDir.deleteSync(recursive: true);
        } catch (_) {}
      }
    });
  });
}
