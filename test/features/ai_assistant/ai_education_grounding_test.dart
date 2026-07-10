import 'package:coach_for_life/features/ai_assistant/application/ai_assumption_engine.dart';
import 'package:coach_for_life/features/ai_assistant/application/ai_intent_parser.dart';
import 'package:coach_for_life/features/ai_assistant/application/ai_operating_layer_client.dart';
import 'package:coach_for_life/features/ai_assistant/application/ai_payload_assembler.dart';
import 'package:coach_for_life/features/ai_assistant/application/entity_normaliser.dart';
import 'package:coach_for_life/features/ai_assistant/data/ai_interaction_history_repository.dart';
import 'package:coach_for_life/features/ai_assistant/domain/models/ai_operating_layer_payload.dart';
import 'package:coach_for_life/features/ai_assistant/domain/models/ai_planned_changes.dart';
import 'package:coach_for_life/features/ai_assistant/domain/models/ai_response_type.dart';
import 'package:coach_for_life/features/planning/data/planning_repository.dart';
import 'package:flutter_test/flutter_test.dart';

/// Captures the payload the parser sends and answers informationally.
class _CapturingClient implements AiOperatingLayerClient {
  AiOperatingLayerPayload? lastPayload;

  @override
  Future<AiPlannedChanges> parseIntent(AiOperatingLayerPayload payload) async {
    lastPayload = payload;
    return AiPlannedChanges(
      sessionId: payload.userInput,
      responseType: AiResponseType.informational,
      informationalMessage: 'Here is how that works…',
    );
  }
}

/// Passes featureGuideText through like the real assembler, minus the IO.
class _PassthroughAssembler implements AiPayloadAssembler {
  const _PassthroughAssembler();

  @override
  Future<AiOperatingLayerPayload> assemble(
    String userInput,
    String sessionId, {
    String? previousPlanSummary,
    intentRoute,
    proactiveContext,
    String? featureGuideText,
  }) async => AiOperatingLayerPayload(
    userInput: userInput,
    featureGuide: featureGuideText,
  );

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
  late _CapturingClient client;
  late AiIntentParser parser;

  setUp(() {
    client = _CapturingClient();
    parser = AiIntentParser(
      client: client,
      assembler: const _PassthroughAssembler(),
      assumptionEngine: AiAssumptionEngine(
        planningRepository: _FakePlanningRepo(),
        historyRepository: _FakeHistory(),
        normaliser: const EntityNormaliser(),
      ),
    );
  });

  test('education question ships the matched guide to the model', () async {
    final result = await parser.parse('What is Discipline Mode?', 's1');

    expect(client.lastPayload, isNotNull);
    expect(client.lastPayload!.featureGuide, contains('Discipline Modes'));
    expect(result.isInformational, isTrue);
    // The guide's own follow-up prompts lead the suggestions.
    expect(result.suggestedPrompts, isNotEmpty);
    expect(
      result.suggestedPrompts.first,
      'Which discipline mode fits a busy week?',
    );
  });

  test('"What are Circles?" bypasses the unsupported fast-path', () async {
    final result = await parser.parse('What are Circles?', 's1');

    expect(result.responseType, isNot(AiResponseType.unsupported));
    expect(client.lastPayload!.featureGuide, contains('Circles'));
  });

  test('circle COMMANDS still hit the unsupported fast-path', () async {
    final result = await parser.parse('add me to a circle', 's1');

    expect(result.responseType, AiResponseType.unsupported);
    expect(client.lastPayload, isNull); // LLM never called
  });

  test('plain commands carry no feature guide', () async {
    await parser.parse('add a workout at 6am tomorrow', 's1');

    expect(client.lastPayload, isNotNull);
    expect(client.lastPayload!.featureGuide, isNull);
  });

  test('prompt builder emits the FEATURE GUIDE block', () {
    final prompt = ProxyAiOperatingLayerClient.debugBuildUserPrompt(
      const AiOperatingLayerPayload(
        userInput: 'What is Focus?',
        featureGuide: 'Focus Sessions — timer for one task.',
      ),
    );
    expect(prompt, contains('FEATURE GUIDE'));
    expect(prompt, contains('Focus Sessions — timer for one task.'));
  });
}
