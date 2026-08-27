import 'dart:convert';
import 'dart:io';

import 'package:sidepal/features/ai_assistant/application/ai_action_batch_repository.dart';
import 'package:sidepal/features/ai_assistant/application/ai_action_batch_state.dart';
import 'package:sidepal/features/ai_assistant/application/ai_action_executor.dart';
import 'package:sidepal/core/local_db/isar_collections/isar_ai_action_batch.dart';
import 'package:sidepal/features/context_override/application/context_override_service.dart';
import 'package:sidepal/features/goals/data/goals_repository.dart';
import 'package:sidepal/features/planning/data/planning_repository.dart';
import 'package:sidepal/features/planning/domain/models/block.dart';
import 'package:sidepal/features/planning/domain/models/routine.dart';
import 'package:sidepal/features/planning/domain/models/task_item.dart';
import 'package:sidepal/features/reminders/data/reminder_repository.dart';
import 'package:sidepal/features/reminders/application/reminder_sync_service.dart';
import 'package:sidepal/features/time_blocks/application/time_block_sync_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';

import '../../support/isar_test_harness.dart';

/// Undo dry-run gate (fix-wave Phase 0, AUDIT.md §8 E4/G4):
///
/// The old shape rolled back BEFORE returning the completed-tasks warning,
/// which made the dialog's Cancel button a lie — the user's completions were
/// already reverted whatever they pressed. These tests pin the honest order:
/// warning first, nothing mutated; rollback only on force; rollback failure
/// reported as [UndoFailed], never [UndoSuccess].

const _day = '2026-08-27';

class _FakePlanningRepo implements PlanningRepository {
  List<PlannedTask> currentTasks = const [];
  final upserted = <PlannedTask>[];

  @override
  Future<List<Routine>> getRoutinesForDate(String dateKey) async => [
    Routine(
      id: 'r1',
      title: 'Day',
      dateKey: dateKey,
      orderIndex: 0,
      createdAtMs: 0,
      updatedAtMs: 0,
    ),
  ];

  @override
  Future<List<TaskBlock>> getBlocks(String routineId) async => const [
    TaskBlock(
      id: 'b1',
      routineId: 'r1',
      title: 'Block',
      orderIndex: 0,
      createdAtMs: 0,
      updatedAtMs: 0,
    ),
  ];

  @override
  Future<List<PlannedTask>> getTasks({
    required String routineId,
    required String blockId,
  }) async => currentTasks;

  @override
  Future<void> upsertTask(PlannedTask task) async => upserted.add(task);

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _NoopFake {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _FakeGoalsRepo extends _NoopFake implements GoalsRepository {}

class _FakeReminderRepo extends _NoopFake implements ReminderRepository {}

class _FakeReminderSync extends _NoopFake implements ReminderSyncService {}

class _FakeTimeBlockSync extends _NoopFake implements TimeBlockSyncService {}

class _FakeContextOverride extends _NoopFake implements ContextOverrideService {}

PlannedTask _task({required TaskStatus status}) => PlannedTask(
  id: 't1',
  routineId: 'r1',
  blockId: 'b1',
  title: 'Workout',
  durationMinutes: 30,
  priority: 3,
  orderIndex: 0,
  reminderEnabled: false,
  reminderTimeIso: null,
  status: status,
  createdAtMs: 0,
  updatedAtMs: 0,
  planDateKey: _day,
);

String _snapshotWith(PlannedTask t) => jsonEncode({
  'tasks': [
    {
      'id': t.id,
      'routineId': t.routineId,
      'blockId': t.blockId,
      'title': t.title,
      'durationMinutes': t.durationMinutes,
      'priority': t.priority,
      'orderIndex': t.orderIndex,
      'reminderEnabled': t.reminderEnabled,
      'reminderTimeIso': t.reminderTimeIso,
      'status': t.status.name,
      'planDateKey': t.planDateKey,
      'modeRefId': t.modeRefId,
      'notes': t.notes,
      'category': t.category,
      'createdAtMs': t.createdAtMs,
      'updatedAtMs': t.updatedAtMs,
    },
  ],
});

void main() {
  Isar? isar;
  Directory? dir;
  late AiActionBatchRepository batchRepo;
  late _FakePlanningRepo planningRepo;
  late AiActionExecutor executor;

  setUp(() async {
    final opened = await openTempIsar();
    isar = opened.isar;
    dir = opened.dir;
    batchRepo = AiActionBatchRepository(isar!);
    planningRepo = _FakePlanningRepo();
    executor = AiActionExecutor(
      planningRepository: planningRepo,
      goalsRepository: _FakeGoalsRepo(),
      reminderRepository: _FakeReminderRepo(),
      reminderSyncService: _FakeReminderSync(),
      timeBlockSyncService: _FakeTimeBlockSync(),
      contextOverrideService: _FakeContextOverride(),
      batchRepository: batchRepo,
    );
  });

  tearDown(() async => closeTempIsar(isar!, dir!));

  Future<void> seedBatch({required String snapshotJson}) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await batchRepo.createBatch(
      IsarAiActionBatch()
        ..batchId = 'batch-1'
        ..state = AiActionBatchState.completed.name
        ..actionsJson = '[]'
        ..snapshotJson = snapshotJson
        ..succeededActionIds = []
        ..failedActionIds = []
        ..createdAtMs = now
        ..updatedAtMs = now,
    );
  }

  test(
      'completed-since task returns UndoNeedsConfirmation and rolls back '
      'NOTHING — Cancel genuinely cancels', () async {
    await seedBatch(
      snapshotJson: _snapshotWith(_task(status: TaskStatus.notStarted)),
    );
    planningRepo.currentTasks = [_task(status: TaskStatus.completed)];

    final result = await executor.undoLastAiBatch();

    expect(result, isA<UndoNeedsConfirmation>());
    final confirmation = result as UndoNeedsConfirmation;
    expect(confirmation.batchId, 'batch-1');
    expect(confirmation.completedTitles, ['Workout']);
    // The load-bearing assertions: no task was touched and the batch is
    // still undoable — the user has not consented yet.
    expect(planningRepo.upserted, isEmpty);
    final batch = await batchRepo.findByBatchId('batch-1');
    expect(batch!.state, AiActionBatchState.completed.name);
  });

  test('force performs the rollback the confirmation was about', () async {
    await seedBatch(
      snapshotJson: _snapshotWith(_task(status: TaskStatus.notStarted)),
    );
    planningRepo.currentTasks = [_task(status: TaskStatus.completed)];

    final result =
        await executor.undoBatchById('batch-1', force: true);

    expect(result, isA<UndoSuccess>());
    expect(planningRepo.upserted, hasLength(1));
    expect(planningRepo.upserted.single.status, TaskStatus.notStarted);
    final batch = await batchRepo.findByBatchId('batch-1');
    expect(batch!.state, AiActionBatchState.rolledBack.name);
  });

  test('no completed-since tasks → undo proceeds without confirmation',
      () async {
    await seedBatch(
      snapshotJson: _snapshotWith(_task(status: TaskStatus.notStarted)),
    );
    planningRepo.currentTasks = [_task(status: TaskStatus.notStarted)];

    final result = await executor.undoLastAiBatch();

    expect(result, isA<UndoSuccess>());
    expect(planningRepo.upserted, hasLength(1));
  });

  test('a failed rollback reports UndoFailed, never UndoSuccess', () async {
    await seedBatch(snapshotJson: 'not valid json {');
    planningRepo.currentTasks = [];

    final result = await executor.undoLastAiBatch();

    expect(result, isA<UndoFailed>());
    final batch = await batchRepo.findByBatchId('batch-1');
    expect(batch!.state, isNot(AiActionBatchState.rolledBack.name));
  });
}
