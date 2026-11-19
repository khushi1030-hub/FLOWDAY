import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flow_day/core/database/app_database.dart';
import 'package:flow_day/core/time/app_clock.dart';
import 'package:flow_day/features/rescheduling/data/repositories/sqlite_reschedule_repository.dart';
import 'package:flow_day/features/rescheduling/domain/entities/reschedule_proposal.dart';
import 'package:flow_day/features/rescheduling/domain/repositories/reschedule_repository.dart';
import 'package:flow_day/features/tasks/data/repositories/sqlite_task_repository.dart';
import 'package:flow_day/features/tasks/domain/entities/task.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('SqliteRescheduleRepository - Transactional Apply & Undo (Phase 9 Exit Checks)', () {
    late Database db;
    late SqliteTaskRepository taskRepo;
    late SqliteRescheduleRepository rescheduleRepo;
    late FakeClock clock;

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

      clock = FakeClock(DateTime(2026, 11, 20, 10, 0));
      taskRepo = SqliteTaskRepository(db, clock);
      rescheduleRepo = SqliteRescheduleRepository(db, clock);
    });

    tearDown(() async {
      await db.close();
    });

    Task makeTask({
      required String id,
      required String title,
      required int startMin,
      required int endMin,
      String dateKey = '2026-11-20',
      int priority = 1,
      bool isFixed = false,
    }) {
      final nowMs = clock.now().millisecondsSinceEpoch;
      return Task(
        id: id,
        title: title,
        dateKey: dateKey,
        startMin: startMin,
        endMin: endMin,
        priority: priority,
        categoryId: 1,
        kind: 'task',
        isFixed: isFixed,
        status: 'pending',
        createdAt: nowMs,
        updatedAt: nowMs,
      );
    }

    test('Exit Check: Transaction failure (forced error) leaves DB completely unchanged', () async {
      final t1 = makeTask(id: 't1', title: 'Task 1', startMin: 540, endMin: 600);
      final t2 = makeTask(id: 't2', title: 'Task 2', startMin: 600, endMin: 660);
      await taskRepo.insertTask(t1);
      await taskRepo.insertTask(t2);

      final proposal = RescheduleProposal(
        id: 'A',
        strategy: ProposalStrategy.shiftFlexible,
        title: 'Plan A',
        subtitle: 'Shift t2',
        moves: [
          TaskMove(
            taskId: 't1',
            taskTitle: 'Task 1',
            oldDateKey: '2026-11-20',
            oldStartMin: 540,
            oldEndMin: 600,
            newDateKey: '2026-11-20',
            newStartMin: 540,
            newEndMin: 630,
          ),
          TaskMove(
            taskId: 't2',
            taskTitle: 'Task 2',
            oldDateKey: '2026-11-20',
            oldStartMin: 600,
            oldEndMin: 660,
            newDateKey: '2026-11-20',
            newStartMin: 630,
            newEndMin: 690,
          ),
        ],
        resultingDayTasks: [
          t1.copyWith(endMin: 630),
          t2.copyWith(startMin: 630, endMin: 690),
        ],
        impactSummary: 'Simulated failure test',
      );

      // Attempt apply with forced failure step 1
      expect(
        () => rescheduleRepo.applyProposal(
          proposal: proposal,
          reason: 'extra_time',
          simulatedFailureStep: 1,
        ),
        throwsA(isA<Exception>()),
      );

      // Verify DB remains 100% unchanged: original times preserved
      final currentT1 = await taskRepo.getTaskById('t1');
      final currentT2 = await taskRepo.getTaskById('t2');
      expect(currentT1!.endMin, equals(600));
      expect(currentT2!.startMin, equals(600));

      // Verify no batches or changes were committed
      final batches = await rescheduleRepo.getAllBatches();
      expect(batches, isEmpty);
    });

    test('Exit Check: Undo restores original schedule exactly', () async {
      final t1 = makeTask(id: 't1', title: 'Task 1', startMin: 540, endMin: 600);
      final t2 = makeTask(id: 't2', title: 'Task 2', startMin: 600, endMin: 660);
      await taskRepo.insertTask(t1);
      await taskRepo.insertTask(t2);

      final proposal = RescheduleProposal(
        id: 'A',
        strategy: ProposalStrategy.shiftFlexible,
        title: 'Plan A',
        subtitle: 'Shift t2',
        moves: [
          TaskMove(
            taskId: 't1',
            taskTitle: 'Task 1',
            oldDateKey: '2026-11-20',
            oldStartMin: 540,
            oldEndMin: 600,
            newDateKey: '2026-11-20',
            newStartMin: 540,
            newEndMin: 630,
          ),
          TaskMove(
            taskId: 't2',
            taskTitle: 'Task 2',
            oldDateKey: '2026-11-20',
            oldStartMin: 600,
            oldEndMin: 660,
            newDateKey: '2026-11-20',
            newStartMin: 630,
            newEndMin: 690,
          ),
        ],
        resultingDayTasks: [
          t1.copyWith(endMin: 630),
          t2.copyWith(startMin: 630, endMin: 690),
        ],
        impactSummary: 'Successful apply',
      );

      // Apply the proposal
      final batch = await rescheduleRepo.applyProposal(
        proposal: proposal,
        reason: 'extra_time',
      );

      // Verify tasks were shifted
      var updatedT1 = await taskRepo.getTaskById('t1');
      var updatedT2 = await taskRepo.getTaskById('t2');
      expect(updatedT1!.endMin, equals(630));
      expect(updatedT2!.startMin, equals(630));
      expect(updatedT2.endMin, equals(690));

      // Perform undo
      clock.advance(const Duration(minutes: 5));
      await rescheduleRepo.undoLatestBatch();

      // Verify tasks restored exactly to original values
      updatedT1 = await taskRepo.getTaskById('t1');
      updatedT2 = await taskRepo.getTaskById('t2');
      expect(updatedT1!.startMin, equals(540));
      expect(updatedT1.endMin, equals(600));
      expect(updatedT2!.startMin, equals(600));
      expect(updatedT2.endMin, equals(660));

      // Verify batch is marked undone
      final retrievedBatch = await rescheduleRepo.getBatchById(batch.id);
      expect(retrievedBatch!.isUndone, isTrue);
    });

    test('Exit Check: Undo is blocked after later manual edits to affected tasks', () async {
      final t1 = makeTask(id: 't1', title: 'Task 1', startMin: 540, endMin: 600);
      final t2 = makeTask(id: 't2', title: 'Task 2', startMin: 600, endMin: 660);
      await taskRepo.insertTask(t1);
      await taskRepo.insertTask(t2);

      final proposal = RescheduleProposal(
        id: 'A',
        strategy: ProposalStrategy.shiftFlexible,
        title: 'Plan A',
        subtitle: 'Shift t2',
        moves: [
          TaskMove(
            taskId: 't2',
            taskTitle: 'Task 2',
            oldDateKey: '2026-11-20',
            oldStartMin: 600,
            oldEndMin: 660,
            newDateKey: '2026-11-20',
            newStartMin: 630,
            newEndMin: 690,
          ),
        ],
        resultingDayTasks: [
          t1,
          t2.copyWith(startMin: 630, endMin: 690),
        ],
        impactSummary: 'Apply',
      );

      final batch = await rescheduleRepo.applyProposal(
        proposal: proposal,
        reason: 'delay',
      );

      // Simulate a later manual edit to Task 2
      clock.advance(const Duration(minutes: 10));
      final currentT2 = await taskRepo.getTaskById('t2');
      await taskRepo.updateTask(currentT2!.copyWith(title: 'Task 2 Edited After Reschedule'));

      // Undo must be blocked!
      expect(
        () => rescheduleRepo.undoBatch(batch.id),
        throwsA(isA<UndoBlockedException>()),
      );
    });

    test('Stale detection: Proposal apply is rejected if task changed before confirmation', () async {
      final t1 = makeTask(id: 't1', title: 'Task 1', startMin: 540, endMin: 600);
      await taskRepo.insertTask(t1);

      // Proposal generated based on start: 540, end: 600
      final proposal = RescheduleProposal(
        id: 'A',
        strategy: ProposalStrategy.shiftFlexible,
        title: 'Plan A',
        subtitle: 'Shift',
        moves: [
          TaskMove(
            taskId: 't1',
            taskTitle: 'Task 1',
            oldDateKey: '2026-11-20',
            oldStartMin: 540,
            oldEndMin: 600,
            newDateKey: '2026-11-20',
            newStartMin: 540,
            newEndMin: 660,
          ),
        ],
        resultingDayTasks: [t1.copyWith(endMin: 660)],
        impactSummary: 'Apply',
      );

      // Task 1 gets modified in DB while proposal was on screen
      await taskRepo.updateTask(t1.copyWith(endMin: 615));

      // Applying stale proposal must throw RescheduleStaleException
      expect(
        () => rescheduleRepo.applyProposal(
          proposal: proposal,
          reason: 'delay',
        ),
        throwsA(isA<RescheduleStaleException>()),
      );
    });
  });
}
