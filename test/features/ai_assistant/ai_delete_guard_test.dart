import 'package:sidepal/features/ai_assistant/application/ai_assumption_engine.dart';
import 'package:sidepal/features/ai_assistant/application/ai_intent_parser.dart';
import 'package:sidepal/features/ai_assistant/application/ai_operating_layer_client.dart';
import 'package:sidepal/features/ai_assistant/application/ai_payload_assembler.dart';
import 'package:sidepal/features/ai_assistant/application/entity_normaliser.dart';
import 'package:sidepal/features/ai_assistant/data/ai_interaction_history_repository.dart';
import 'package:sidepal/features/ai_assistant/domain/models/ai_action.dart';
import 'package:sidepal/features/ai_assistant/domain/models/ai_operating_layer_payload.dart';
import 'package:sidepal/features/ai_assistant/domain/models/ai_planned_changes.dart';
import 'package:sidepal/features/ai_assistant/domain/models/ai_response_type.dart';
import 'package:sidepal/features/planning/data/planning_repository.dart';
import 'package:flutter_test/flutter_test.dart';

/// Destructive-action guard (2026-08-22 bug batch): the model answered
/// "No thank you" with a delete-4-items plan. Deletions must only survive
/// the pipeline when the user's own words asked for one.

class _ScriptedClient implements AiOperatingLayerClient {
  _ScriptedClient(this.result);
  final AiPlannedChanges result;

  @override
  Future<AiPlannedChanges> parseIntent(AiOperatingLayerPayload payload) async =>
      result;
}

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
    bool voiceMode = false,
  }) async => AiOperatingLayerPayload(userInput: userInput);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeHistory implements AiInteractionHistoryRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakePlanningRepo implements PlanningRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

final _deletePlan = AiPlannedChanges(
  sessionId: 's',
  responseType: AiResponseType.mutate,
  actions: const [
    AiAction(
      actionType: ActionType.deleteTask,
      parameters: {'taskTitle': 'Wake up at 06:30'},
    ),
    AiAction(
      actionType: ActionType.deleteTask,
      parameters: {'taskTitle': 'Create Flutter to-do list'},
    ),
  ],
);

AiIntentParser _parser(AiPlannedChanges scripted) {
  const normaliser = EntityNormaliser();
  return AiIntentParser(
    client: _ScriptedClient(scripted),
    assembler: const _FakeAssembler(),
    assumptionEngine: AiAssumptionEngine(
      planningRepository: _FakePlanningRepo(),
      historyRepository: _FakeHistory(),
      normaliser: normaliser,
    ),
  );
}

void main() {
  test('a decline that reached the model cannot produce a delete plan',
      () async {
    final result = await _parser(_deletePlan).parse('No thank you', 's1');

    expect(result.actions, isEmpty);
    expect(result.isInformational, isTrue);
    expect(result.informationalMessage, contains("didn't change anything"));
  });

  test(
      'an explicit delete request degrades to an honest refusal while '
      'deleteTask is retired (fix-wave Phase 0; Phase 1 restores the plan)',
      () async {
    final result = await _parser(
      _deletePlan,
    ).parse('delete the wake up task and the flutter list', 's1');

    // The unrequested-delete guard lets an explicit request through, but the
    // retired-verb strip must still catch it: the executor cannot delete yet,
    // so a preview card would be a confirmed no-op.
    expect(result.actions, isEmpty);
    expect(result.isInformational, isTrue);
    expect(result.informationalMessage, contains("can't delete tasks yet"));
  });

  test('mixed plan keeps non-delete actions when deletes were unrequested',
      () async {
    final mixed = AiPlannedChanges(
      sessionId: 's',
      responseType: AiResponseType.mutate,
      actions: const [
        AiAction(
          actionType: ActionType.createTask,
          parameters: {
            'title': 'Study',
            'time': '14:00',
            'duration': 30,
            'date': 'today',
          },
        ),
        AiAction(
          actionType: ActionType.deleteTask,
          parameters: {'taskTitle': 'Wake up at 06:30'},
        ),
      ],
    );
    final result = await _parser(
      mixed,
    ).parse('schedule a study session at 2pm', 's1');

    expect(result.actions, hasLength(1));
    expect(result.actions.single.actionType, ActionType.createTask);
  });

  test(
      'refining a plan that already had deletes still cannot revive a '
      'retired verb (fix-wave Phase 0)', () async {
    final result = await _parser(_deletePlan).parse(
      'yes those two',
      's1',
      previousPlan: _deletePlan,
    );

    expect(result.actions, isEmpty);
    expect(result.isInformational, isTrue);
  });
}
