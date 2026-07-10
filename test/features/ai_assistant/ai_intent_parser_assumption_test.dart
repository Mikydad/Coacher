import 'package:coach_for_life/features/ai_assistant/application/ai_assumption_engine.dart';
import 'package:coach_for_life/features/ai_assistant/application/ai_intent_parser.dart';
import 'package:coach_for_life/features/ai_assistant/application/ai_operating_layer_client.dart';
import 'package:coach_for_life/features/ai_assistant/application/ai_payload_assembler.dart';
import 'package:coach_for_life/features/ai_assistant/application/entity_normaliser.dart';
import 'package:coach_for_life/features/ai_assistant/data/ai_interaction_history_repository.dart';
import 'package:coach_for_life/features/ai_assistant/domain/models/ai_action.dart';
import 'package:coach_for_life/features/ai_assistant/domain/models/ai_operating_layer_payload.dart';
import 'package:coach_for_life/features/ai_assistant/domain/models/ai_planned_changes.dart';
import 'package:coach_for_life/features/planning/data/planning_repository.dart';
import 'package:coach_for_life/features/planning/domain/models/block.dart';
import 'package:coach_for_life/features/planning/domain/models/routine.dart';
import 'package:coach_for_life/features/planning/domain/models/task_item.dart';
import 'package:flutter_test/flutter_test.dart';

// ─── Fakes ────────────────────────────────────────────────────────────────────

final _stubPayload = AiOperatingLayerPayload(userInput: 'test');

class _FakeAssembler implements AiPayloadAssembler {
  const _FakeAssembler();

  @override
  Future<AiOperatingLayerPayload> assemble(
    String userInput,
    String sessionId, {
    String? previousPlanSummary,
    intentRoute,
    proactiveContext,
    String? featureGuideText,
  }) async =>
      _stubPayload;

  @override
  dynamic noSuchMethod(Invocation i) => null;
}

class _FakeClient implements AiOperatingLayerClient {
  _FakeClient(this._result);
  final AiPlannedChanges _result;

  @override
  Future<AiPlannedChanges> parseIntent(AiOperatingLayerPayload payload) async => _result;
}

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
  }) async => tasks;

  @override
  dynamic noSuchMethod(Invocation i) => throw UnimplementedError('${i.memberName}');
}

class _FakeHistoryRepo implements AiInteractionHistoryRepository {
  @override
  dynamic noSuchMethod(Invocation i) => null;
}

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  const normaliser = EntityNormaliser();

  group('AiIntentParser assumption integration', () {
    test(
      'incomplete action + matching history → time is pre-filled, no follow-up',
      () async {
        // AI returns an action with title but missing time and duration
        final aiResult = AiPlannedChanges(
          sessionId: 'sess1',
          actions: [
            AiAction(
              actionType: ActionType.createTask,
              parameters: {'title': 'workout'}, // missing time + duration
            ),
          ],
        );

        // Build a fake completed workout task in today's history
        final today = DateTime.now().toLocal();
        final dateKey =
            '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
        final routine = Routine(
          id: 'r1',
          title: 'Daily plan',
          dateKey: dateKey,
          orderIndex: 0,
          createdAtMs: 0,
          updatedAtMs: 0,
        );
        final block = TaskBlock(
          id: 'b1',
          routineId: 'r1',
          title: 'Morning',
          orderIndex: 0,
          createdAtMs: 0,
          updatedAtMs: 0,
        );
        final task = PlannedTask(
          id: 't1',
          routineId: 'r1',
          blockId: 'b1',
          title: 'gym session',
          durationMinutes: 60,
          priority: 3,
          orderIndex: 0,
          reminderEnabled: true,
          reminderTimeIso: today.copyWith(hour: 6, minute: 0).toIso8601String(),
          status: TaskStatus.completed,
          createdAtMs: 0,
          updatedAtMs: 0,
        );

        final engine = AiAssumptionEngine(
          planningRepository: _FakePlanningRepo(
            routines: [routine],
            blocks: [block],
            tasks: [task],
          ),
          historyRepository: _FakeHistoryRepo(),
          normaliser: normaliser,
        );

        final parser = AiIntentParser(
          client: _FakeClient(aiResult),
          assembler: const _FakeAssembler(),
          assumptionEngine: engine,
        );

        final result = await parser.parse('schedule workout', 'sess1');

        // Should have a plan (not a follow-up question)
        expect(result.requiresFollowUp, isFalse,
            reason: 'Should pre-fill from history instead of asking');
        expect(result.actions, isNotEmpty);
        final action = result.actions.first;
        expect(action.parameters['time'], isNotNull,
            reason: 'Time should be pre-filled from history');
        expect(action.reasonLabel, isNotNull);
        expect(action.reasonLabel, contains('fitness'));
      },
    );

    test('incomplete action + no history → follow-up question is returned', () async {
      // AI returns an action with unknown category, no history available
      final aiResult = AiPlannedChanges(
        sessionId: 'sess2',
        actions: [
          AiAction(
            actionType: ActionType.createTask,
            parameters: {'title': 'piano practice'}, // unknown, no history
          ),
        ],
      );

      final engine = AiAssumptionEngine(
        planningRepository: _FakePlanningRepo(), // empty
        historyRepository: _FakeHistoryRepo(),
        normaliser: normaliser,
      );

      final parser = AiIntentParser(
        client: _FakeClient(aiResult),
        assembler: const _FakeAssembler(),
        assumptionEngine: engine,
      );

      final result = await parser.parse('add piano practice', 'sess2');

      // Should ask a follow-up question because time is missing
      expect(result.requiresFollowUp, isTrue);
      expect(result.followUpQuestion, isNotNull);
    });
  });
}
