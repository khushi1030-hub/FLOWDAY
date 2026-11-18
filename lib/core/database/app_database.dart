import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Database management class for FlowDay.
/// Manages SQLite connection, schema creation, migrations, and seeding.
class AppDatabase {
  AppDatabase._(this._db);

  static const String databaseName = 'flowday.db';
  static const int schemaVersion = 1;

  final Database _db;

  Database get db => _db;

  /// Creates or opens the production database on device.
  static Future<AppDatabase> open() async {
    final databasesPath = await getDatabasesPath();
    final path = p.join(databasesPath, databaseName);

    final db = await openDatabase(
      path,
      version: schemaVersion,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );

    return AppDatabase._(db);
  }

  /// Wraps an existing database instance (e.g. sqflite_common_ffi in-memory DB for tests).
  factory AppDatabase.fromDatabase(Database db) {
    return AppDatabase._(db);
  }

  static Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON;');
  }

  static Future<void> _onCreate(Database db, int version) async {
    await initializeDatabase(db);
  }

  /// Initializes database with schema v1 and initial category seeds.
  static Future<void> initializeDatabase(Database db) async {
    final batch = db.batch();
    createSchemaV1(batch);
    seedCategoriesV1(batch);
    await batch.commit(noResult: true);
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    for (var v = oldVersion + 1; v <= newVersion; v++) {
      await db.transaction((txn) async {
        final batch = txn.batch();
        switch (v) {
          case 2:
            // Placeholder for future v2 migration
            break;
        }
        await batch.commit(noResult: true);
      });
    }
  }

  /// Schema version 1 definition.
  static void createSchemaV1(Batch batch) {
    // 1. Categories
    batch.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        color INTEGER NOT NULL,
        icon_key TEXT NOT NULL,
        is_default INTEGER NOT NULL DEFAULT 0
      );
    ''');

    // 2. Tasks
    batch.execute('''
      CREATE TABLE tasks (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL CHECK(length(trim(title)) > 0),
        description TEXT,
        date_key TEXT NOT NULL,
        start_min INTEGER NOT NULL CHECK(start_min BETWEEN 0 AND 1439),
        end_min INTEGER NOT NULL CHECK(end_min BETWEEN 1 AND 1440),
        priority INTEGER NOT NULL DEFAULT 1,
        kind TEXT NOT NULL DEFAULT 'task',
        is_fixed INTEGER NOT NULL DEFAULT 0,
        category_id INTEGER REFERENCES categories(id) ON DELETE SET NULL,
        status TEXT NOT NULL DEFAULT 'pending',
        was_rescheduled INTEGER NOT NULL DEFAULT 0,
        alarm_enabled INTEGER NOT NULL DEFAULT 1,
        notes TEXT,
        icon_key TEXT,
        recurrence TEXT NOT NULL DEFAULT 'never',
        recurrence_rule TEXT,
        series_id TEXT,
        has_conflict INTEGER NOT NULL DEFAULT 0,
        reminder_offset_min INTEGER,
        completed_at INTEGER,
        carried_from_date_key TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        CHECK(end_min > start_min)
      );
    ''');

    batch.execute('CREATE INDEX idx_tasks_date ON tasks(date_key, start_min);');

    // 3. Task Events (History)
    batch.execute('''
      CREATE TABLE task_events (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        task_id TEXT NOT NULL,
        task_title TEXT NOT NULL,
        date_key TEXT NOT NULL,
        event_type TEXT NOT NULL,
        planned_minutes INTEGER,
        actual_minutes INTEGER,
        occurred_at INTEGER NOT NULL
      );
    ''');

    // 4. Focus Sessions
    batch.execute('''
      CREATE TABLE focus_sessions (
        id TEXT PRIMARY KEY,
        task_id TEXT,
        planned_seconds INTEGER NOT NULL,
        elapsed_seconds INTEGER NOT NULL DEFAULT 0,
        state TEXT NOT NULL,
        started_at INTEGER NOT NULL,
        last_resumed_at INTEGER,
        ended_at INTEGER
      );
    ''');

    // 5. Day Confirmations
    batch.execute('''
      CREATE TABLE day_confirmations (
        date_key TEXT PRIMARY KEY,
        confirmed INTEGER NOT NULL DEFAULT 0,
        confirmed_at INTEGER
      );
    ''');

    // 6. Reschedule Batches
    batch.execute('''
      CREATE TABLE reschedule_batches (
        id TEXT PRIMARY KEY,
        reason TEXT NOT NULL,
        trigger_task_id TEXT,
        proposal_label TEXT,
        created_at INTEGER NOT NULL,
        undone_at INTEGER
      );
    ''');

    // 7. Reschedule Changes
    batch.execute('''
      CREATE TABLE reschedule_changes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        batch_id TEXT NOT NULL REFERENCES reschedule_batches(id) ON DELETE CASCADE,
        task_id TEXT NOT NULL,
        old_date_key TEXT NOT NULL,
        old_start_min INTEGER NOT NULL,
        old_end_min INTEGER NOT NULL,
        new_date_key TEXT NOT NULL,
        new_start_min INTEGER NOT NULL,
        new_end_min INTEGER NOT NULL
      );
    ''');
  }

  /// Initial category seeds matching UI design specs.
  static void seedCategoriesV1(Batch batch) {
    const seeds = [
      {'name': 'Study', 'color': 0xFF818CF8, 'icon_key': 'book', 'is_default': 1},
      {'name': 'Work', 'color': 0xFF34D399, 'icon_key': 'briefcase', 'is_default': 1},
      {'name': 'Health', 'color': 0xFFF472B6, 'icon_key': 'heart', 'is_default': 1},
      {'name': 'Personal', 'color': 0xFFFBBF24, 'icon_key': 'user', 'is_default': 1},
      {'name': 'Social', 'color': 0xFFFB923C, 'icon_key': 'users', 'is_default': 1},
      {'name': 'Break', 'color': 0xFFD97706, 'icon_key': 'coffee', 'is_default': 1},
    ];

    for (final seed in seeds) {
      batch.insert('categories', seed);
    }
  }

  /// Closes database connection.
  Future<void> close() => _db.close();
}
