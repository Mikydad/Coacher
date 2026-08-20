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

/// The deterministic clarify escape (deep check 2026-08-20): a follow-up
/// answer like "2 pm" must complete the pending plan — locally when it can,
/// via overlay after the model when it must — and may NEVER re-trigger the
/// identical missing-field question.

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
    bool voiceMode = false,
  }) async => _stubPayload;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _RecordingClient implements AiOperatingLayerClient {
  _RecordingClient(this._result);
  final AiPlannedChanges _result;
  int calls = 0;

  @override
  Future<AiPlannedChanges> parseIntent(AiOperatingLayerPayload payload) async {
    calls++;
    return _result;
  }
}

class _ThrowingClient implements AiOperatingLayerClient {
  @override
  Future<AiPlannedChanges> parseIntent(AiOperatingLayerPayload payload) async {
    throw StateError('model must not be called on a local clarify merge');
  }
}

class _FakeHistory implements AiInteractionHistoryRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakePlanningRepo implements PlanningRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

AiIntentParser _parser(AiOperatingLayerClient client) => AiIntentParser(
  client: client,
  assembler: const _FakeAssembler(),
  assumptionEngine: AiAssumptionEngine(
    planningRepository: _FakePlanningRepo(),
    historyRepository: _FakeHistory(),
    normaliser: const EntityNormaliser(),
  ),
);

AiPlannedChanges _pendingTimeQuestion({Map<String, dynamic>? params}) =>
    AiPlannedChanges(
      sessionId: 's1',
      followUpQuestion: 'What time should I schedule it?',
      actions: [
        AiAction(
          actionType: ActionType.createTask,
          parameters:
              params ?? {'title': 'Workout Session', 'duration': 60},
        ),
      ],
    );

void main() {
  test('a time answer completes the pending plan locally — no model call',
      () async {
    final parser = _parser(_ThrowingClient());

    final result = await parser.parse(
      '2 pm',
      's1',
      previousPlan: _pendingTimeQuestion(),
    );

    expect(result.requiresFollowUp, isFalse);
    expect(result.responseType, AiResponseType.mutate);
    expect(result.actions.single.parameters['time'], '14:00');
    expect(result.actions.single.parameters['title'], 'Workout Session');
  });

  test('"At 2 pm" phrasing also merges locally', () async {
    final parser = _parser(_ThrowingClient());

    final result = await parser.parse(
      'At 2 pm',
      's1',
      previousPlan: _pendingTimeQuestion(),
    );

    expect(result.requiresFollowUp, isFalse);
    expect(result.actions.single.parameters['time'], '14:00');
  });

  test(
    'when the model STILL drops the answered field, the overlay fills it '
    'before the detector can re-ask',
    () async {
      // Pending plan misses time AND duration, so "2 pm" cannot complete it
      // locally — the model runs, returns duration but AGAIN no time.
      final client = _RecordingClient(
        AiPlannedChanges(
          sessionId: 'raw',
          responseType: AiResponseType.mutate,
          actions: const [
            AiAction(
              actionType: ActionType.createTask,
              parameters: {'title': 'Workout Session', 'duration': 45},
            ),
          ],
        ),
      );
      final parser = _parser(client);

      final result = await parser.parse(
        '2 pm',
        's1',
        previousPlan: _pendingTimeQuestion(
          params: {'title': 'Workout Session'},
        ),
      );

      expect(client.calls, 1);
      expect(result.requiresFollowUp, isFalse,
          reason: 'the identical question must never repeat');
      expect(result.actions.single.parameters['time'], '14:00');
      expect(result.actions.single.parameters['duration'], 45);
    },
  );

  test('a name reply answers the title question verbatim', () async {
    final parser = _parser(_ThrowingClient());

    final result = await parser.parse(
      'Deep work block',
      's1',
      previousPlan: AiPlannedChanges(
        sessionId: 's1',
        followUpQuestion: 'What should I call this task?',
        actions: const [
          AiAction(
            actionType: ActionType.createTask,
            parameters: {'time': '14:00', 'duration': 30},
          ),
        ],
      ),
    );

    expect(result.requiresFollowUp, isFalse);
    expect(result.actions.single.parameters['title'], 'Deep work block');
  });

  test('affirmations are never taken as field answers', () async {
    final client = _RecordingClient(
      AiPlannedChanges(
        sessionId: 'raw',
        responseType: AiResponseType.informational,
        informationalMessage: 'Sure — what should I call it?',
      ),
    );
    final parser = _parser(client);

    await parser.parse(
      'perfect',
      's1',
      previousPlan: AiPlannedChanges(
        sessionId: 's1',
        followUpQuestion: 'What should I call this task?',
        actions: const [
          AiAction(
            actionType: ActionType.createTask,
            parameters: {'time': '14:00', 'duration': 30},
          ),
        ],
      ),
    );

    // "perfect" fills nothing, so the model path runs.
    expect(client.calls, 1);
  });
}
