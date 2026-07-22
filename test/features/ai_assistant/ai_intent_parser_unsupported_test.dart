import 'package:sidepal/features/ai_assistant/application/ai_assumption_engine.dart';
import 'package:sidepal/features/ai_assistant/application/ai_intent_parser.dart';
import 'package:sidepal/features/ai_assistant/application/ai_operating_layer_client.dart';
import 'package:sidepal/features/ai_assistant/application/ai_payload_assembler.dart';
import 'package:sidepal/features/ai_assistant/application/entity_normaliser.dart';
import 'package:sidepal/features/ai_assistant/data/ai_interaction_history_repository.dart';
import 'package:sidepal/features/ai_assistant/domain/models/ai_operating_layer_payload.dart';
import 'package:sidepal/features/ai_assistant/domain/models/ai_planned_changes.dart';
import 'package:sidepal/features/ai_assistant/domain/models/ai_response_type.dart';
import 'package:sidepal/features/planning/data/planning_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _ThrowingClient implements AiOperatingLayerClient {
  @override
  Future<AiPlannedChanges> parseIntent(AiOperatingLayerPayload payload) async {
    throw StateError('LLM should not be called for unsupported queries');
  }
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
  }) async =>
      AiOperatingLayerPayload(userInput: userInput);

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

void main() {
  test('unsupported query returns registry message without calling LLM', () async {
    const normaliser = EntityNormaliser();
    final parser = AiIntentParser(
      client: _ThrowingClient(),
      assembler: const _FakeAssembler(),
      assumptionEngine: AiAssumptionEngine(
        planningRepository: _FakePlanningRepo(),
        historyRepository: _FakeHistory(),
        normaliser: normaliser,
      ),
    );

    final result = await parser.parse(
      'Post to my circle about workouts',
      'session-1',
    );

    expect(result.isUnsupported, isTrue);
    expect(result.responseType, AiResponseType.unsupported);
    expect(result.informationalMessage, contains('Circles'));
  });
}
