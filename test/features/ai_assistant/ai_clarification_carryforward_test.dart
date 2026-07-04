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
import 'package:coach_for_life/features/planning/data/planning_repository.dart';
import 'package:flutter_test/flutter_test.dart';

/// Records the previousPlanSummary the service passes through on each turn.
class _RecordingAssembler implements AiPayloadAssembler {
  final List<String?> previousSummaries = [];

  @override
  Future<AiOperatingLayerPayload> assemble(
    String userInput,
    String sessionId, {
    String? previousPlanSummary,
    intentRoute,
    proactiveContext,
  }) async {
    previousSummaries.add(previousPlanSummary);
    return AiOperatingLayerPayload(userInput: userInput);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

/// Returns queued results in order.
class _ScriptedClient implements AiOperatingLayerClient {
  _ScriptedClient(this._results);
  final List<AiPlannedChanges> _results;
  int _i = 0;

  @override
  Future<AiPlannedChanges> parseIntent(AiOperatingLayerPayload payload) async =>
      _results[_i++];
}

class _NoopHistory implements AiInteractionHistoryRepository {
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

class _NoopExecutor implements AiActionExecutor {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  test(
      'answering the missing-detail question refines the pending plan '
      'instead of restarting', () async {
    // Turn 1: model proposes a task with no time → missing-field follow-up.
    // Turn 2: model returns a complete task → preview card.
    final client = _ScriptedClient([
      AiPlannedChanges(
        sessionId: 'x',
        actions: [
          AiAction(
            actionType: ActionType.createTask,
            parameters: {'title': 'piano practice'}, // missing time
          ),
        ],
      ),
      AiPlannedChanges(
        sessionId: 'x',
        actions: [
          AiAction(
            actionType: ActionType.createTask,
            parameters: {
              'title': 'piano practice',
              'time': '21:00',
              'duration': 30,
              'date': 'today',
            },
          ),
        ],
      ),
    ]);
    final assembler = _RecordingAssembler();
    final parser = AiIntentParser(
      client: client,
      assembler: assembler,
      assumptionEngine: AiAssumptionEngine(
        planningRepository: _FakePlanningRepo(),
        historyRepository: _NoopHistory(),
        normaliser: const EntityNormaliser(),
      ),
    );
    final service = AiAssistantService(
      intentParser: parser,
      actionExecutor: _NoopExecutor(),
      historyRepository: _NoopHistory(),
    );

    await service.sendMessage('add piano practice');
    // Turn 1 asked a follow-up, nothing pending yet, and no previous summary.
    expect(service.hasPendingPlan, isFalse);
    expect(assembler.previousSummaries[0], isNull);
    expect(service.messages.last.content, contains('time'));

    await service.sendMessage('at 9pm');
    // Turn 2 must have carried the partial plan forward as context…
    expect(assembler.previousSummaries[1], isNotNull);
    expect(assembler.previousSummaries[1], contains('createTask'));
    // …and resolved to a real preview card.
    expect(service.hasPendingPlan, isTrue);
  });
}
