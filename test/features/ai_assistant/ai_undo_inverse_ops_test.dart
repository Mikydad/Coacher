import 'dart:convert';
import 'dart:io';

import 'package:sidepal/core/local_db/isar_collections/isar_ai_action_batch.dart';
import 'package:sidepal/core/offline/offline_store.dart';
import 'package:sidepal/core/utils/date_keys.dart';
import 'package:sidepal/features/ai_assistant/application/ai_action_batch_repository.dart';
import 'package:sidepal/features/ai_assistant/application/ai_action_batch_state.dart';
import 'package:sidepal/features/ai_assistant/application/ai_action_executor.dart';
import 'package:sidepal/features/ai_assistant/data/ai_interaction_history_repository.dart';
import 'package:sidepal/features/ai_assistant/domain/models/ai_action.dart';
import 'package:sidepal/features/context_override/application/context_override_service.dart';
import 'package:sidepal/features/goals/data/goals_repository.dart';
import 'package:sidepal/features/memory/data/memory_facts_repository.dart';
import 'package:sidepal/features/memory/domain/models/memory_fact.dart';
import 'package:sidepal/features/planning/data/planning_repository.dart';
import 'package:sidepal/features/planning/domain/models/block.dart';
import 'package:sidepal/features/planning/domain/models/routine.dart';
import 'package:sidepal/features/planning/domain/models/task_item.dart';
import 'package:sidepal/features/reminders/application/reminder_sync_service.dart';
import 'package:sidepal/features/reminders/data/reminder_repository.dart';
import 'package:sidepal/features/reminders/domain/models/reminder_config.dart';
import 'package:sidepal/features/time_blocks/application/time_block_sync_service.dart';
import 'package:sidepal/features/time_blocks/domain/models/scheduled_time_block.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';

import '../../support/isar_test_harness.dart';

/// Undo v2 — the inverse-operation log (fix-wave Phase 2).
///
/// The old rollback restored a DATE-WIDE task snapshot: undoing a
/// "remember this" re-upserted every task on today's plan, reverting
/// completions made since and LWW-pushing that to other devices (GPT-5.6
/// G3); created tasks survived their own "undone" (§8 E3); one failed
/// action rolled back its confirmed siblings (E6). These tests pin the new
/// contract: undo reverts exactly what the batch did — nothing more,
/// nothing less.

class _FakePlanningRepo implements PlanningRepository {
  final Map<String, List<PlannedTask>> tasksByDate = const {};
  final upserted = <PlannedTask>[];
  final deletedTaskIds = <String>[];
  String? _servingDate;

  @override
  Future<List<Routine>> getRoutinesForDate(String dateKey) async {
    _servingDate = dateKey;
    return [
      Routine(
        id: 'r-$dateKey',
        title: 'Day',
        dateKey: dateKey,
        orderIndex: 0,
        createdAtMs: 0,
        updatedAtMs: 0,
      ),
    ];
  }

  @override
  Future<List<TaskBlock>> getBlocks(String routineId) async => [
    TaskBlock(
      id: 'b-$routineId',
      routineId: routineId,
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
  }) async => tasksByDate[_servingDate] ?? const [];

  @override
  Future<void> upsertTask(PlannedTask task) async => upserted.add(task);

  @override
  Future<void> deleteTask({
    required String routineId,
    required String blockId,
    required String taskId,
  }) async => deletedTaskIds.add(taskId);

  @override
  Future<({String routineId, String blockId})> ensureDefaultDayPlan(
    String dateKey,
  ) async => (routineId: 'r-$dateKey', blockId: 'b-r-$dateKey');

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _FakeReminderSync implements ReminderSyncService {
  final removedForTaskIds = <String>[];
  final syncedTaskIds = <String>[];

  @override
  Future<void> removeForDeletedTask(String taskId) async =>
      removedForTaskIds.add(taskId);

  @override
  Future<void> syncForTaskIds(List<String> taskIds) async =>
      syncedTaskIds.addAll(taskIds);

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _FakeTimeBlockSync implements TimeBlockSyncService {
  final removedEntityIds = <String>[];

  @override
  Future<void> removeBlockForEntity(String entityId) async =>
      removedEntityIds.add(entityId);

  @override
  ScheduledTimeBlock? deriveBlock({
    required String entityId,
    required String entityKind,
    required DateTime? startAt,
    required int? durationMinutes,
    String? modeRefId,
    bool isRigid = false,
    bool allowOverlapOverride = false,
  }) => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _FakeMemoryRepo implements MemoryFactsRepository {
  final facts = <String, MemoryFact>{};
  final deletedIds = <String>[];

  @override
  Future<void> upsertFact(MemoryFact fact) async => facts[fact.id] = fact;

  @override
  Future<void> deleteFact(String factId) async => deletedIds.add(factId);

  @override
  Future<MemoryFact?> getFact(String factId) async => facts[factId];

  @override
  Future<List<MemoryFact>> fetchFactsOnce() async => facts.values.toList();

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _NoopFake {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _FakeGoalsRepo extends _NoopFake implements GoalsRepository {}

class _FakeReminderRepo extends _NoopFake implements ReminderRepository {
  @override
  Future<List<ReminderConfig>> getRemindersForTasks(
    List<String> taskIds,
  ) async => const [];

  @override
  Future<void> upsertReminder(ReminderConfig reminder) async {}
}

class _FakeContextOverride extends _NoopFake
    implements ContextOverrideService {}

void main() {
  final today = DateKeys.todayKey();

  Isar? isar;
  Directory? dir;
  late AiActionBatchRepository batchRepo;
  late _FakePlanningRepo planning;
  late _FakeReminderSync reminderSync;
  late _FakeTimeBlockSync timeBlockSync;
  late _FakeMemoryRepo memoryRepo;
  late AiActionExecutor executor;

  setUp(() async {
    final opened = await openTempIsar();
    isar = opened.isar;
    dir = opened.dir;
    batchRepo = AiActionBatchRepository(isar!);
    planning = _FakePlanningRepo();
    reminderSync = _FakeReminderSync();
    timeBlockSync = _FakeTimeBlockSync();
    memoryRepo = _FakeMemoryRepo();
    executor = AiActionExecutor(
      planningRepository: planning,
      goalsRepository: _FakeGoalsRepo(),
      reminderRepository: _FakeReminderRepo(),
      reminderSyncService: reminderSync,
      timeBlockSyncService: timeBlockSync,
      contextOverrideService: _FakeContextOverride(),
      batchRepository: batchRepo,
      memoryFactsRepository: memoryRepo,
    );
  });

  tearDown(() async {
    OfflineStore.debugIsarOverride = null;
    await closeTempIsar(isar!, dir!);
  });

  test(
      'G3 regression: undoing a memory-only batch touches ZERO schedule '
      'tasks', () async {
    final result = await executor.execute([
      const AiAction(
        actionType: ActionType.rememberFact,
        parameters: {
          'content': 'Prefers morning workouts',
          'rawUtterance': 'remember I prefer morning workouts',
        },
      ),
    ]);
    expect(result.failures, isEmpty);
    expect(memoryRepo.facts, hasLength(1));

    final undo = await executor.undoBatchById(result.batchId!, force: true);

    expect(undo, isA<UndoSuccess>());
    expect(memoryRepo.deletedIds, hasLength(1));
    // The load-bearing assertion: the old date-wide snapshot re-upserted
    // every task on today's plan here.
    expect(planning.upserted, isEmpty);
    expect(planning.deletedTaskIds, isEmpty);
  });

  test('E3 regression: undo DELETES the task the batch created', () async {
    final result = await executor.execute([
      const AiAction(
        actionType: ActionType.createTask,
        parameters: {
          'title': 'Morning run',
          'time': '07:00',
          'duration': 30,
          'date': 'today',
        },
      ),
    ]);
    expect(result.failures, isEmpty);
    final createdId = planning.upserted.single.id;

    final undo = await executor.undoBatchById(result.batchId!, force: true);

    expect(undo, isA<UndoSuccess>());
    expect(planning.deletedTaskIds, [createdId]);
    // The created task's reminder machinery and derived block go with it.
    expect(reminderSync.removedForTaskIds, contains(createdId));
    expect(timeBlockSync.removedEntityIds, contains(createdId));
  });

  test(
      'Q4: one failed action keeps its siblings applied — no all-or-nothing '
      'rollback — and undo reverts exactly the survivors', () async {
    final result = await executor.execute([
      const AiAction(
        actionType: ActionType.createTask,
        parameters: {
          'title': 'Study',
          'time': '14:00',
          'duration': 30,
          'date': 'today',
        },
      ),
      // No resolver stamps → _requireResolvedTaskRow throws.
      const AiAction(
        actionType: ActionType.deleteTask,
        parameters: {'taskTitle': 'Ghost'},
      ),
    ]);

    expect(result.successes, hasLength(1));
    expect(result.failures, hasLength(1));
    expect(result.wasRolledBack, isFalse);
    // The created task survived its sibling's failure.
    expect(planning.upserted, hasLength(1));
    expect(planning.deletedTaskIds, isEmpty);
    final batch = await batchRepo.findByBatchId(result.batchId!);
    expect(batch!.state, AiActionBatchState.partialFailure.name);

    // Undo reverts only what succeeded: the created task is deleted.
    final undo = await executor.undoBatchById(result.batchId!, force: true);
    expect(undo, isA<UndoSuccess>());
    expect(planning.deletedTaskIds, [planning.upserted.single.id]);
  });

  test('E8: the boot sweep rolls back a batch stranded mid-execution',
      () async {
    final staleMs = DateTime.now()
        .subtract(const Duration(minutes: 10))
        .millisecondsSinceEpoch;
    await batchRepo.createBatch(
      IsarAiActionBatch()
        ..batchId = 'stranded-1'
        ..state = AiActionBatchState.executing.name
        ..actionsJson = '[]'
        ..snapshotJson = jsonEncode({
          'inverseOps': [
            {
              'op': 'deleteTask',
              'taskId': 't-crash',
              'routineId': 'r-$today',
              'blockId': 'b-r-$today',
              'dateKey': today,
              'title': 'Half-applied',
            },
          ],
        })
        ..succeededActionIds = []
        ..failedActionIds = []
        ..createdAtMs = staleMs
        ..updatedAtMs = staleMs,
    );

    await executor.sweepStrandedBatches();

    expect(planning.deletedTaskIds, ['t-crash']);
    final swept = await batchRepo.findByBatchId('stranded-1');
    expect(swept!.state, AiActionBatchState.rolledBack.name);
  });

  test(
      'M1/G8: markConfirmed/markExecuted flag ONLY the newest session entry',
      () async {
    OfflineStore.debugIsarOverride = isar;
    final history = AiInteractionHistoryRepository(OfflineStore.instance);

    await history.save(
      sessionId: 's1',
      userInput: 'suggest a study plan',
      parsedActions: const [],
    );
    await Future<void>.delayed(const Duration(milliseconds: 5));
    await history.save(
      sessionId: 's1',
      userInput: 'add a workout at 6',
      parsedActions: const [],
    );

    await history.markConfirmed('s1');
    await history.markExecuted('s1');

    final entries = await history.getRecentForSession('s1');
    final newest = entries.first;
    final older = entries.last;
    expect(newest.userInput, 'add a workout at 6');
    expect(newest.executed, isTrue);
    expect(newest.confirmed, isTrue);
    // The declined/informational earlier turn must never be flagged — it
    // used to feed the model "Already applied this session (do NOT
    // repeat)" for things that never happened.
    expect(older.executed, isFalse);
    expect(older.confirmed, isFalse);
  });
}
