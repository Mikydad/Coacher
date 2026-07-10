import 'package:coach_for_life/features/ai_assistant/application/ai_action_executor.dart';
import 'package:coach_for_life/features/ai_assistant/application/ai_assistant_service.dart';
import 'package:coach_for_life/features/ai_assistant/application/ai_assumption_engine.dart';
import 'package:coach_for_life/features/ai_assistant/application/ai_capability_registry.dart';
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
  int calls = 0;

  @override
  Future<AiPlannedChanges> parseIntent(AiOperatingLayerPayload payload) async {
    calls++;
    return _result;
  }
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
  Future<void> markConfirmed(String sessionId) async {}

  @override
  Future<void> markExecuted(String sessionId) async {}

  @override
  Future<void> saveAssistantSummary(String sessionId, String summary) async {}

  @override
  Future<void> updateResolvedCategory(String sessionId, String category) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakePlanningRepo implements PlanningRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _RecordingExecutor implements AiActionExecutor {
  int executeCalls = 0;

  @override
  Future<ExecutionResult> execute(List<AiAction> actions) async {
    executeCalls++;
    return ExecutionResult(
      successes: [for (final a in actions) 'Applied ${a.actionType.name}'],
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

AiIntentParser _parserWith(_FakeClient client) {
  return AiIntentParser(
    client: client,
    assembler: const _FakeAssembler(),
    assumptionEngine: AiAssumptionEngine(
      planningRepository: _FakePlanningRepo(),
      historyRepository: _RecordingHistory(),
      normaliser: const EntityNormaliser(),
    ),
  );
}

AiPlannedChanges _mutatePlan() => AiPlannedChanges(
      sessionId: 'x',
      actions: [
        AiAction(
          actionType: ActionType.createTask,
          parameters: {
            'title': 'Stay active',
            'time': '01:00',
            'duration': 30,
            'date': 'tomorrow',
          },
        ),
      ],
    );

void main() {
  group('capability questions', () {
    test('isCapabilityQuestion matches skill questions', () {
      expect(
        AiCapabilityRegistry.isCapabilityQuestion('what else can you do'),
        isTrue,
      );
      expect(
        AiCapabilityRegistry.isCapabilityQuestion('I asked for your skills'),
        isTrue,
      );
      expect(AiCapabilityRegistry.isCapabilityQuestion('help'), isTrue);
      expect(
        AiCapabilityRegistry.isCapabilityQuestion('How can you help me?'),
        isTrue,
      );
    });

    test('planning and schedule requests are NOT capability questions', () {
      expect(
        AiCapabilityRegistry.isCapabilityQuestion('help me plan tomorrow'),
        isFalse,
      );
      expect(
        AiCapabilityRegistry.isCapabilityQuestion('add workout at 6am'),
        isFalse,
      );
      expect(
        AiCapabilityRegistry.isCapabilityQuestion("what's my plan for today"),
        isFalse,
      );
    });

    test('capability question short-circuits the LLM with a real answer',
        () async {
      final client = _FakeClient(_mutatePlan());
      final parser = _parserWith(client);

      final result = await parser.parse('what else can you do', 's1');

      expect(client.calls, 0, reason: 'must not reach the LLM');
      expect(result.responseType, AiResponseType.informational);
      expect(result.informationalMessage, contains('plan'));
      expect(result.suggestedPrompts, isNotEmpty);
    });
  });

  group('pending-plan short replies', () {
    test('"no" cancels the pending plan instead of re-proposing it', () async {
      final client = _FakeClient(_mutatePlan());
      final executor = _RecordingExecutor();
      final service = AiAssistantService(
        intentParser: _parserWith(client),
        actionExecutor: executor,
        historyRepository: _RecordingHistory(),
      );

      await service.sendMessage('add stay active tomorrow at 1am');
      expect(service.hasPendingPlan, isTrue);
      final callsAfterPlan = client.calls;

      await service.sendMessage('noo');

      expect(service.hasPendingPlan, isFalse);
      expect(client.calls, callsAfterPlan,
          reason: 'rejection must not hit the parser');
      expect(executor.executeCalls, 0);
      expect(
        service.messages.last.content.toLowerCase(),
        contains('cancel'),
      );
    });

    test('"yes" confirms and executes the pending plan', () async {
      final client = _FakeClient(_mutatePlan());
      final executor = _RecordingExecutor();
      final service = AiAssistantService(
        intentParser: _parserWith(client),
        actionExecutor: executor,
        historyRepository: _RecordingHistory(),
      );

      await service.sendMessage('add stay active tomorrow at 1am');
      expect(service.hasPendingPlan, isTrue);

      await service.sendMessage('yes');
      // confirmPlan is fired unawaited from the short-reply path.
      await pumpEventQueue();

      expect(executor.executeCalls, 1);
      expect(service.hasPendingPlan, isFalse);
    });

    test('full sentences still reach the parser while a plan is pending',
        () async {
      final client = _FakeClient(_mutatePlan());
      final service = AiAssistantService(
        intentParser: _parserWith(client),
        actionExecutor: _RecordingExecutor(),
        historyRepository: _RecordingHistory(),
      );

      await service.sendMessage('add stay active tomorrow at 1am');
      final callsAfterPlan = client.calls;

      await service.sendMessage('no workout tomorrow, move it to friday');

      expect(client.calls, callsAfterPlan + 1,
          reason: 'real sentences are not short replies');
    });
  });

  group('free window computation', () {
    test('finds gaps between blocks inside the waking day', () {
      final windows = AiPayloadAssembler.computeFreeWindows([
        {'title': 'Workout', 'startTime': '07:00', 'endTime': '08:00'},
        {'title': 'Meeting', 'startTime': '12:00', 'endTime': '13:30'},
      ]);

      expect(windows, [
        '08:00–12:00 (4h)',
        '13:30–22:00 (8h 30m)',
      ]);
    });

    test('empty schedule yields the full waking day', () {
      expect(
        AiPayloadAssembler.computeFreeWindows(const []),
        ['07:00–22:00 (15h)'],
      );
    });

    test('fromMinuteOfDay drops windows already in the past', () {
      final windows = AiPayloadAssembler.computeFreeWindows(
        [
          {'title': 'Dinner', 'startTime': '19:00', 'endTime': '20:00'},
        ],
        fromMinuteOfDay: 18 * 60, // it is 18:00 now
      );

      expect(windows, ['18:00–19:00 (1h)', '20:00–22:00 (2h)']);
    });

    test('overlapping blocks are merged and short gaps dropped', () {
      final windows = AiPayloadAssembler.computeFreeWindows([
        {'title': 'A', 'startTime': '09:00', 'endTime': '10:00'},
        {'title': 'B', 'startTime': '09:30', 'endTime': '11:00'},
        // 20-minute gap — below the 30-minute floor.
        {'title': 'C', 'startTime': '11:20', 'endTime': '21:45'},
      ]);

      expect(windows, ['07:00–09:00 (2h)']);
    });

    test('midnight-hour blocks do not break the waking-day windows', () {
      final windows = AiPayloadAssembler.computeFreeWindows([
        {'title': 'Workout', 'startTime': '01:00', 'endTime': '01:30'},
        {'title': 'Eat healthy', 'startTime': '00:00', 'endTime': '00:00'},
      ]);

      expect(windows, ['07:00–22:00 (15h)']);
    });
  });
}
