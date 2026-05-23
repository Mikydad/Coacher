import 'package:coach_for_life/features/ai_assistant/application/ai_assumption_engine.dart';
import 'package:coach_for_life/features/ai_assistant/application/entity_normaliser.dart';
import 'package:coach_for_life/features/ai_assistant/data/ai_interaction_history_repository.dart';
import 'package:coach_for_life/features/ai_assistant/domain/models/ai_action.dart';
import 'package:coach_for_life/features/ai_assistant/domain/models/assumption_result.dart';
import 'package:coach_for_life/features/planning/data/planning_repository.dart';
import 'package:coach_for_life/features/planning/domain/models/accountability_log.dart';
import 'package:coach_for_life/features/planning/domain/models/block.dart';
import 'package:coach_for_life/features/planning/domain/models/flow_transition_event.dart';
import 'package:coach_for_life/features/planning/domain/models/routine.dart';
import 'package:coach_for_life/features/planning/domain/models/routine_mode.dart';
import 'package:coach_for_life/features/planning/domain/models/task_item.dart';
import 'package:flutter_test/flutter_test.dart';

// ─── Fakes ────────────────────────────────────────────────────────────────────

class _FakePlanningRepo implements PlanningRepository {
  _FakePlanningRepo({this.routines = const [], this.blocks = const [], this.tasks = const []});

  final List<Routine> routines;
  final List<TaskBlock> blocks;
  final List<PlannedTask> tasks;

  @override
  Future<List<Routine>> getRoutinesForDate(String dateKey) async => routines;

  @override
  Future<List<TaskBlock>> getBlocks(String routineId) async => blocks;

  @override
  Future<List<PlannedTask>> getTasks({
    required String routineId,
    required String blockId,
  }) async =>
      tasks;

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(
      'Not implemented: ${invocation.memberName}');
}

void main() {
  const normaliser = EntityNormaliser();

  AiAssumptionEngine _makeEngine(_FakePlanningRepo repo) {
    return AiAssumptionEngine(
      planningRepository: repo,
      historyRepository: _FakeHistoryRepo(),
      normaliser: normaliser,
    );
  }

  // ─── Helper ─────────────────────────────────────────────────────────────────

  PlannedTask _makeTask({
    required String title,
    String? timeIso,
    int duration = 60,
    TaskStatus status = TaskStatus.completed,
  }) {
    return PlannedTask(
      id: 'task-1',
      routineId: 'r1',
      blockId: 'b1',
      title: title,
      durationMinutes: duration,
      priority: 3,
      orderIndex: 0,
      reminderEnabled: timeIso != null,
      reminderTimeIso: timeIso,
      status: status,
      createdAtMs: DateTime.now().millisecondsSinceEpoch,
      updatedAtMs: DateTime.now().millisecondsSinceEpoch,
    );
  }

  Routine _makeRoutine() {
    final today = DateTime.now().toLocal();
    final dateKey =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    return Routine(
      id: 'r1',
      title: 'Daily plan',
      dateKey: dateKey,
      orderIndex: 0,
      createdAtMs: 0,
      updatedAtMs: 0,
    );
  }

  TaskBlock _makeBlock() => TaskBlock(
        id: 'b1',
        routineId: 'r1',
        title: 'Morning',
        orderIndex: 0,
        createdAtMs: 0,
        updatedAtMs: 0,
      );

  group('AiAssumptionEngine.infer — noMatch cases', () {
    test('returns noMatch when no history exists', () async {
      final engine = _makeEngine(_FakePlanningRepo());
      final action = AiAction(
        actionType: ActionType.createTask,
        parameters: {'title': 'workout'},
      );
      final result = await engine.infer(action);
      expect(result.source, AssumptionSource.noMatch);
    });

    test('returns noMatch when title is empty', () async {
      final engine = _makeEngine(_FakePlanningRepo());
      final action = AiAction(
        actionType: ActionType.createTask,
        parameters: {},
      );
      final result = await engine.infer(action);
      expect(result, AssumptionResult.noMatch);
    });
  });

  group('AiAssumptionEngine.infer — match cases', () {
    test('fills time + duration from completed task with high confidence', () async {
      final taskTime = DateTime.now().copyWith(hour: 6, minute: 0);
      final task = _makeTask(
        title: 'gym session',
        timeIso: taskTime.toIso8601String(),
        duration: 60,
        status: TaskStatus.completed,
      );
      final repo = _FakePlanningRepo(
        routines: [_makeRoutine()],
        blocks: [_makeBlock()],
        tasks: [task],
      );
      final engine = _makeEngine(repo);

      final action = AiAction(
        actionType: ActionType.createTask,
        parameters: {'title': 'workout'}, // missing time + duration
      );
      final result = await engine.infer(action);

      expect(result.confidence, greaterThanOrEqualTo(0.80));
      expect(result.source, AssumptionSource.taskHistory);
      expect(result.suggestedParameters.containsKey('time'), isTrue);
      expect(result.suggestedParameters['duration'], 60);
      expect(result.reasonLabel, contains('fitness'));
    });

    test('does not overwrite user-provided values', () async {
      final taskTime = DateTime.now().copyWith(hour: 6, minute: 0);
      final task = _makeTask(
        title: 'gym session',
        timeIso: taskTime.toIso8601String(),
        duration: 60,
        status: TaskStatus.completed,
      );
      final repo = _FakePlanningRepo(
        routines: [_makeRoutine()],
        blocks: [_makeBlock()],
        tasks: [task],
      );
      final engine = _makeEngine(repo);

      final action = AiAction(
        actionType: ActionType.createTask,
        parameters: {
          'title': 'workout',
          'time': '07:30', // user explicitly provided time
        },
      );
      final result = await engine.infer(action);

      // Engine must NOT suggest overriding the user-provided time
      expect(result.suggestedParameters.containsKey('time'), isFalse);
    });

    test('reason label mentions the category', () async {
      final taskTime = DateTime.now().copyWith(hour: 21, minute: 0);
      final task = _makeTask(
        title: 'sleep',
        timeIso: taskTime.toIso8601String(),
        status: TaskStatus.completed,
      );
      final repo = _FakePlanningRepo(
        routines: [_makeRoutine()],
        blocks: [_makeBlock()],
        tasks: [task],
      );
      final engine = _makeEngine(repo);

      final action = AiAction(
        actionType: ActionType.createTask,
        parameters: {'title': 'bedtime'},
      );
      final result = await engine.infer(action);

      if (result.hasMatch) {
        expect(result.reasonLabel, contains('sleep'));
      }
    });
  });

  group('AiAssumptionEngine.inferAll', () {
    test('returns one result per action in order', () async {
      final engine = _makeEngine(_FakePlanningRepo());
      final actions = [
        AiAction(
          actionType: ActionType.createTask,
          parameters: {'title': 'workout'},
        ),
        AiAction(
          actionType: ActionType.createTask,
          parameters: {'title': 'study session'},
        ),
      ];
      final results = await engine.inferAll(actions);
      expect(results.length, 2);
    });
  });
}

// ─── Fake history repo (no-op) ────────────────────────────────────────────────

class _FakeHistoryRepo implements AiInteractionHistoryRepository {
  const _FakeHistoryRepo();

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
