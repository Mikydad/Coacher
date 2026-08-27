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

/// Retired-verb guard (fix-wave Phase 0, AUDIT.md §8 E1/E2/E6): verbs whose
/// executors are stubs must never reach a preview card. A confirmed "Done"
/// for a write that never happened is the worst failure the coach has —
/// these tests pin the honest degradation until Phase 1 makes each verb
/// real and removes it from [AiIntentParser.kRetiredActionTypes].

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

AiPlannedChanges _plan(List<AiAction> actions) => AiPlannedChanges(
  sessionId: 's',
  responseType: AiResponseType.mutate,
  actions: actions,
);

void main() {
  test('the tool enum offers no retired verbs to the model', () {
    final enumValues =
        // ignore: avoid_dynamic_calls
        (((kCoachAgentTools.first['function']
                        as Map<String, dynamic>)['parameters']
                    as Map<String, dynamic>)['properties']
                as Map<String, dynamic>)['actions']['items']['properties']
            ['actionType']['enum'] as List;
    for (final retired in AiIntentParser.kRetiredActionTypes) {
      expect(
        enumValues,
        isNot(contains(retired.name)),
        reason: '${retired.name} has no working executor and must not be '
            'offered to the model',
      );
    }
    expect(enumValues, contains('createTask'));
    expect(enumValues, contains('rescheduleReminder'));
  });

  test('a move-only plan degrades to an honest refusal, not a card',
      () async {
    final result = await _parser(
      _plan(const [
        AiAction(
          actionType: ActionType.moveTask,
          parameters: {'taskTitle': 'Workout', 'destinationDate': 'tomorrow'},
        ),
      ]),
    ).parse('move my workout to tomorrow', 's1');

    expect(result.actions, isEmpty);
    expect(result.isInformational, isTrue);
    expect(
      result.informationalMessage,
      contains("can't move or edit existing tasks yet"),
    );
    expect(result.informationalMessage, contains("didn't change anything"));
  });

  test('an edit-only plan degrades to an honest refusal', () async {
    final result = await _parser(
      _plan(const [
        AiAction(
          actionType: ActionType.editTask,
          parameters: {'title': 'Gym', 'time': '19:00'},
        ),
      ]),
    ).parse('change my gym to 7pm', 's1');

    expect(result.actions, isEmpty);
    expect(result.isInformational, isTrue);
  });

  test('a mixed plan keeps the real work and notes the retired part',
      () async {
    final result = await _parser(
      _plan(const [
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
          actionType: ActionType.moveTask,
          parameters: {'taskTitle': 'Workout', 'destinationDate': 'tomorrow'},
        ),
      ]),
    ).parse('add study at 2pm and move my workout to tomorrow', 's1');

    expect(result.actions, hasLength(1));
    expect(result.actions.single.actionType, ActionType.createTask);
    expect(
      result.informationalMessage,
      contains("can't move or edit existing tasks yet"),
    );
  });

  test('decorative suggestFreeTimeBlock is silently dropped from a plan',
      () async {
    final result = await _parser(
      _plan(const [
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
          actionType: ActionType.suggestFreeTimeBlock,
          parameters: {},
        ),
      ]),
    ).parse('add study at 2pm', 's1');

    // The read-only kind used to throw during dispatch and poison the whole
    // confirmed batch into rollback (§8 E6) — now it never reaches the card,
    // and no note is needed (it promised nothing the user asked for).
    expect(result.actions, hasLength(1));
    expect(result.actions.single.actionType, ActionType.createTask);
    expect(result.informationalMessage ?? '', isNot(contains("can't")));
  });
}
