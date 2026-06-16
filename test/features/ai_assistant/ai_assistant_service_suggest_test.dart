import 'package:coach_for_life/features/ai_assistant/application/ai_action_executor.dart';
import 'package:coach_for_life/features/ai_assistant/application/ai_assistant_service.dart';
import 'package:coach_for_life/features/ai_assistant/application/ai_assumption_engine.dart';
import 'package:coach_for_life/features/ai_assistant/application/ai_intent_parser.dart';
import 'package:coach_for_life/features/ai_assistant/application/ai_operating_layer_client.dart';
import 'package:coach_for_life/features/ai_assistant/application/ai_payload_assembler.dart';
import 'package:coach_for_life/features/ai_assistant/application/entity_normaliser.dart';
import 'package:coach_for_life/features/ai_assistant/data/ai_interaction_history_repository.dart';
import 'package:coach_for_life/features/ai_assistant/domain/models/ai_action.dart';
import 'package:coach_for_life/features/ai_assistant/domain/models/ai_intent_kind.dart';
import 'package:coach_for_life/features/ai_assistant/domain/models/ai_operating_layer_payload.dart';
import 'package:coach_for_life/features/ai_assistant/domain/models/ai_planned_changes.dart';
import 'package:coach_for_life/features/ai_assistant/domain/models/ai_response_type.dart';
import 'package:coach_for_life/features/planning/data/planning_repository.dart';
import 'package:flutter_test/flutter_test.dart';

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
  }) async =>
      _stubPayload;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeClient implements AiOperatingLayerClient {
  _FakeClient(this._result);
  final AiPlannedChanges _result;

  @override
  Future<AiPlannedChanges> parseIntent(AiOperatingLayerPayload payload) async =>
      _result;
}

class _RecordingHistory implements AiInteractionHistoryRepository {
  @override
  Future<void> save({
    required String sessionId,
    required String userInput,
    required List<AiAction> parsedActions,
    String? resolvedCategory,
    String? assistantSummary,
    String? responseType,
  }) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakePlanningRepo implements PlanningRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _FakeExecutor implements AiActionExecutor {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  test('suggest result shows narrative and draft plan without pending preview', () async {
    const normaliser = EntityNormaliser();
    final parser = AiIntentParser(
      client: _FakeClient(
        AiPlannedChanges(
          sessionId: 'x',
          responseType: AiResponseType.suggest,
          informationalMessage: 'Tomorrow morning is open. I\'d add Study at 9.',
          actions: [
            AiAction(
              actionType: ActionType.createTask,
              parameters: {
                'title': 'Study',
                'time': '09:00',
                'duration': 45,
                'date': 'tomorrow',
              },
            ),
          ],
        ),
      ),
      assembler: const _FakeAssembler(),
      assumptionEngine: AiAssumptionEngine(
        planningRepository: _FakePlanningRepo(),
        historyRepository: _RecordingHistory(),
        normaliser: normaliser,
      ),
    );

    final service = AiAssistantService(
      intentParser: parser,
      actionExecutor: _FakeExecutor(),
      historyRepository: _RecordingHistory(),
    );

    await service.sendMessage('Help me plan tomorrow');

    expect(service.hasPendingPlan, isFalse);
    expect(service.messages, hasLength(2));
    expect(service.messages.last.content, contains('Study'));
    expect(service.messages.last.hasDraftPlan, isTrue);
    expect(service.messages.last.plannedChanges, isNull);
  });

  test('applySuggestedPlan reveals preview card and sets pending plan', () async {
    const normaliser = EntityNormaliser();
    final suggestPlan = AiPlannedChanges(
      sessionId: 'x',
      responseType: AiResponseType.suggest,
      informationalMessage: 'I\'d add Study at 9.',
      actions: [
        AiAction(
          actionType: ActionType.createTask,
          parameters: {
            'title': 'Study',
            'time': '09:00',
            'duration': 45,
            'date': 'tomorrow',
          },
        ),
      ],
    );

    final parser = AiIntentParser(
      client: _FakeClient(suggestPlan),
      assembler: const _FakeAssembler(),
      assumptionEngine: AiAssumptionEngine(
        planningRepository: _FakePlanningRepo(),
        historyRepository: _RecordingHistory(),
        normaliser: normaliser,
      ),
    );

    final service = AiAssistantService(
      intentParser: parser,
      actionExecutor: _FakeExecutor(),
      historyRepository: _RecordingHistory(),
    );

    await service.sendMessage('Help me plan tomorrow');
    final messageId = service.messages.last.id;

    service.applySuggestedPlan(messageId);

    expect(service.hasPendingPlan, isTrue);
    expect(service.messages.last.hasPreviewCard, isTrue);
    expect(service.messages.last.isCurrentPlan, isTrue);
    expect(service.messages.last.hasDraftPlan, isFalse);
  });
}
