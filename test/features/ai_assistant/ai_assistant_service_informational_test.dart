import 'package:coach_for_life/features/ai_assistant/application/ai_action_executor.dart';
import 'package:coach_for_life/features/ai_assistant/application/ai_assistant_service.dart';
import 'package:coach_for_life/features/ai_assistant/application/ai_assumption_engine.dart';
import 'package:coach_for_life/features/ai_assistant/application/ai_intent_parser.dart';
import 'package:coach_for_life/features/ai_assistant/application/ai_operating_layer_client.dart';
import 'package:coach_for_life/features/ai_assistant/application/ai_payload_assembler.dart';
import 'package:coach_for_life/features/ai_assistant/application/entity_normaliser.dart';
import 'package:coach_for_life/features/ai_assistant/data/ai_interaction_history_repository.dart';
import 'package:coach_for_life/features/ai_assistant/domain/models/ai_action.dart';
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
    String? featureGuideText,
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
  _RecordingHistory();

  String? lastSummary;
  String? lastResponseType;

  @override
  Future<void> saveAssistantSummary(String sessionId, String summary) async {
    lastSummary = summary;
  }

  @override
  Future<void> save({
    required String sessionId,
    required String userInput,
    required List<AiAction> parsedActions,
    String? resolvedCategory,
    String? assistantSummary,
    String? responseType,
  }) async {
    lastSummary = assistantSummary;
    lastResponseType = responseType;
  }

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
  test('informational result renders text bubble without pending plan', () async {
    final history = _RecordingHistory();
    const normaliser = EntityNormaliser();
    final parser = AiIntentParser(
      client: _FakeClient(
        AiPlannedChanges(
          sessionId: 'x',
          responseType: AiResponseType.informational,
          informationalMessage: 'Tomorrow you have Study at 9:00.',
          suggestedPrompts: const ['Add a task tomorrow'],
        ),
      ),
      assembler: const _FakeAssembler(),
      assumptionEngine: AiAssumptionEngine(
        planningRepository: _FakePlanningRepo(),
        historyRepository: history,
        normaliser: normaliser,
      ),
    );

    final service = AiAssistantService(
      intentParser: parser,
      actionExecutor: _FakeExecutor(),
      historyRepository: history,
    );

    await service.sendMessage('What is my plan for tomorrow?');

    expect(service.hasPendingPlan, isFalse);
    expect(service.messages, hasLength(2));
    expect(service.messages.last.content, contains('Study'));
    expect(service.messages.last.suggestedPrompts, ['Add a task tomorrow']);
    expect(history.lastSummary, contains('Study'));
    expect(history.lastResponseType, 'informational');
  });
}
