import 'dart:convert';
import 'dart:io';

import 'package:sidepal/features/ai_assistant/application/ai_action_batch_repository.dart';
import 'package:sidepal/features/ai_assistant/application/ai_action_executor.dart';
import 'package:sidepal/core/utils/date_keys.dart';
import 'package:sidepal/features/ai_assistant/domain/models/ai_action.dart';
import 'package:sidepal/features/context_override/application/context_override_service.dart';
import 'package:sidepal/features/goals/data/goals_repository.dart';
import 'package:sidepal/features/goals/domain/models/goal_enums.dart';
import 'package:sidepal/features/goals/domain/models/user_goal.dart';
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

/// The six re-enabled verbs must produce their REAL Isar mutations
/// (fix-wave Phase 1, closing §8 E1/E2 — the fake-success stubs and the
/// duplicate-creating edit). Every action here carries the resolver stamps
/// the parser adds at preview time.

class _FakePlanningRepo implements PlanningRepository {
  _FakePlanningRepo(this.tasksByDate);

  final Map<String, List<PlannedTask>> tasksByDate;
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

class _FakeGoalsRepo implements GoalsRepository {
  _FakeGoalsRepo(this.goals);
  final List<UserGoal> goals;
  final upserted = <UserGoal>[];
  final deletedIds = <String>[];

  @override
  Future<List<UserGoal>> fetchGoalsOnce() async => goals;

  @override
  Future<void> upsertGoal(UserGoal goal) async => upserted.add(goal);

  @override
  Future<void> deleteGoal(String goalId) async => deletedIds.add(goalId);

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

  // null = no derived block; syncBlock is then never called.
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

class _NoopFake {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _FakeReminderRepo extends _NoopFake implements ReminderRepository {
  final upsertedReminders = <Object>[];

  @override
  Future<List<ReminderConfig>> getRemindersForTasks(
    List<String> taskIds,
  ) async => const [];

  @override
  Future<void> upsertReminder(ReminderConfig reminder) async =>
      upsertedReminders.add(reminder);
}

class _FakeContextOverride extends _NoopFake
    implements ContextOverrideService {}

void main() {
  final today = DateKeys.todayKey();
  final tomorrow = DateKeys.tomorrowKey();

  Isar? isar;
  Directory? dir;
  late AiActionBatchRepository batchRepo;

  setUp(() async {
    final opened = await openTempIsar();
    isar = opened.isar;
    dir = opened.dir;
    batchRepo = AiActionBatchRepository(isar!);
  });

  tearDown(() async => closeTempIsar(isar!, dir!));

  PlannedTask task({
    String id = 't1',
    String title = 'Workout',
    String? dateKey,
    TaskStatus status = TaskStatus.inProgress,
    String? reminderIso,
  }) {
    final day = dateKey ?? today;
    return PlannedTask(
      id: id,
      routineId: 'r-$day',
      blockId: 'b-r-$day',
      title: title,
      durationMinutes: 45,
      priority: 2,
      orderIndex: 3,
      reminderEnabled: reminderIso != null,
      reminderTimeIso: reminderIso,
      status: status,
      createdAtMs: 111,
      updatedAtMs: 222,
      category: 'Fitness',
      planDateKey: day,
      notes: 'bring shoes',
      modeRefId: 'disciplined',
    );
  }

  ({
    AiActionExecutor executor,
    _FakePlanningRepo planning,
    _FakeGoalsRepo goalsRepo,
    _FakeReminderSync reminderSync,
    _FakeTimeBlockSync timeBlockSync,
  }) build({
    Map<String, List<PlannedTask>> tasks = const {},
    List<UserGoal> goals = const [],
  }) {
    final planning = _FakePlanningRepo(tasks);
    final goalsRepo = _FakeGoalsRepo(goals);
    final reminderSync = _FakeReminderSync();
    final timeBlockSync = _FakeTimeBlockSync();
    return (
      executor: AiActionExecutor(
        planningRepository: planning,
        goalsRepository: goalsRepo,
        reminderRepository: _FakeReminderRepo(),
        reminderSyncService: reminderSync,
        timeBlockSyncService: timeBlockSync,
        contextOverrideService: _FakeContextOverride(),
        batchRepository: batchRepo,
      ),
      planning: planning,
      goalsRepo: goalsRepo,
      reminderSync: reminderSync,
      timeBlockSync: timeBlockSync,
    );
  }

  Map<String, dynamic> stamps({String id = 't1', String? dateKey}) => {
    '_resolvedTaskId': id,
    '_resolvedRoutineId': 'r-${dateKey ?? today}',
    '_resolvedBlockId': 'b-r-${dateKey ?? today}',
    '_resolvedDateKey': dateKey ?? today,
  };

  test('editTask updates the SAME row and preserves untouched fields',
      () async {
    final t = task();
    final h = build(tasks: {today: [t]});

    final result = await h.executor.execute([
      AiAction(
        actionType: ActionType.editTask,
        parameters: {'title': 'Workout', 'duration': 60, ...stamps()},
      ),
    ]);

    expect(result.failures, isEmpty);
    final updated = h.planning.upserted.single;
    // Same id — the old handler minted a StableId and DUPLICATED the task.
    expect(updated.id, 't1');
    expect(updated.durationMinutes, 60);
    // Untouched fields survive: the old handler reset all of these.
    expect(updated.status, TaskStatus.inProgress);
    expect(updated.notes, 'bring shoes');
    expect(updated.category, 'Fitness');
    expect(updated.priority, 2);
    expect(updated.orderIndex, 3);
    expect(updated.modeRefId, 'disciplined');
  });

  test('moveTask lands the same id on the destination day, reminder follows',
      () async {
    final t = task(
      reminderIso: DateTime(2026, 8, 27, 9, 0).toIso8601String(),
    );
    final h = build(tasks: {today: [t]});

    final result = await h.executor.execute([
      AiAction(
        actionType: ActionType.moveTask,
        parameters: {
          'taskTitle': 'Workout',
          'destinationDate': tomorrow,
          ...stamps(),
        },
      ),
    ]);

    expect(result.failures, isEmpty);
    final moved = h.planning.upserted.single;
    expect(moved.id, 't1');
    expect(moved.planDateKey, tomorrow);
    // The reminder keeps its 09:00 clock time on the new day.
    final reminder = DateTime.parse(moved.reminderTimeIso!);
    expect(DateKeys.yyyymmdd(reminder), tomorrow);
    expect(reminder.hour, 9);
  });

  test('deleteTask removes the row, its reminders, and its time block',
      () async {
    final h = build(tasks: {today: [task()]});

    final result = await h.executor.execute([
      AiAction(
        actionType: ActionType.deleteTask,
        parameters: {'taskTitle': 'Workout', ...stamps()},
      ),
    ]);

    expect(result.failures, isEmpty);
    expect(result.successes.single, contains('Deleted "Workout"'));
    expect(h.planning.deletedTaskIds, ['t1']);
    expect(h.reminderSync.removedForTaskIds, ['t1']);
    expect(h.timeBlockSync.removedEntityIds, ['t1']);
  });

  test('removeReminder cancels configs and clears the task reminder fields',
      () async {
    final t = task(
      reminderIso: DateTime(2026, 8, 27, 19, 0).toIso8601String(),
    );
    final h = build(tasks: {today: [t]});

    final result = await h.executor.execute([
      AiAction(
        actionType: ActionType.removeReminder,
        parameters: {'taskTitle': 'Workout', ...stamps()},
      ),
    ]);

    expect(result.failures, isEmpty);
    expect(h.reminderSync.removedForTaskIds, ['t1']);
    final updated = h.planning.upserted.single;
    expect(updated.reminderEnabled, isFalse);
    expect(updated.reminderTimeIso, isNull);
    expect(updated.id, 't1');
  });

  test('an unresolved targeting action fails loudly — never guesses',
      () async {
    final h = build(tasks: {today: [task()]});

    final result = await h.executor.execute([
      const AiAction(
        actionType: ActionType.deleteTask,
        parameters: {'taskTitle': 'Workout'}, // no resolver stamps
      ),
    ]);

    expect(result.failures, isNotEmpty);
    expect(h.planning.deletedTaskIds, isEmpty);
  });

  group('goals', () {
    final goal = UserGoal(
      id: 'g1',
      title: 'Read books',
      categoryId: 'study',
      status: GoalStatus.active,
      measurementKind: MeasurementKind.count,
      targetValue: 5,
      intensity: 3,
      periodStartMs: 0,
      periodEndMs: 1,
      createdAtMs: 0,
      updatedAtMs: 0,
    );

    test('modifyGoal changes the named field on the same goal id', () async {
      final h = build(goals: [goal]);

      final result = await h.executor.execute([
        const AiAction(
          actionType: ActionType.modifyGoal,
          parameters: {
            'goalTitle': 'Read books',
            'field': 'target',
            'newValue': '12',
            '_resolvedGoalId': 'g1',
          },
        ),
      ]);

      expect(result.failures, isEmpty);
      final updated = h.goalsRepo.upserted.single;
      expect(updated.id, 'g1');
      expect(updated.targetValue, 12);
      expect(updated.title, 'Read books');
    });

    test('an unsupported field fails loudly instead of pretending', () async {
      final h = build(goals: [goal]);

      final result = await h.executor.execute([
        const AiAction(
          actionType: ActionType.modifyGoal,
          parameters: {
            'goalTitle': 'Read books',
            'field': 'color',
            'newValue': 'blue',
            '_resolvedGoalId': 'g1',
          },
        ),
      ]);

      expect(result.failures, isNotEmpty);
      // The only permissible upsert is the rollback's restore of the
      // stashed pre-mutation goal — never a goal with the bogus field
      // applied.
      for (final g in h.goalsRepo.upserted) {
        expect(g.targetValue, 5);
        expect(g.title, 'Read books');
      }
    });

    test('deleteGoal deletes, and rollback restores from _prevGoalJson',
        () async {
      final h = build(goals: [goal]);

      final result = await h.executor.execute([
        const AiAction(
          actionType: ActionType.deleteGoal,
          parameters: {'goalTitle': 'Read books', '_resolvedGoalId': 'g1'},
        ),
      ]);

      expect(result.failures, isEmpty);
      expect(h.goalsRepo.deletedIds, ['g1']);
      // The pre-mutation goal was stashed for undo.
      final batch = await batchRepo.findByBatchId(result.batchId!);
      final actions = (jsonDecode(batch!.actionsJson) as List)
          .cast<Map<String, dynamic>>();
      final prevJson = (actions.single['params'] as Map)['_prevGoalJson'];
      expect(prevJson, isNotNull);

      final undo = await h.executor.undoBatchById(result.batchId!);
      expect(undo, isA<UndoSuccess>());
      expect(h.goalsRepo.upserted.map((g) => g.id), contains('g1'));
    });
  });
}
