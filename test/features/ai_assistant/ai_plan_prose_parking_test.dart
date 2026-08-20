import 'package:sidepal/features/ai_assistant/application/ai_action_executor.dart';
import 'package:sidepal/features/ai_assistant/application/ai_assistant_service.dart';
import 'package:sidepal/features/ai_assistant/application/ai_intent_parser.dart';
import 'package:sidepal/features/ai_assistant/data/ai_interaction_history_repository.dart';
import 'package:sidepal/features/ai_assistant/domain/models/ai_action.dart';
import 'package:sidepal/features/ai_assistant/domain/models/ai_planned_changes.dart';
import 'package:sidepal/features/ai_assistant/domain/models/ai_response_type.dart';
import 'package:flutter_test/flutter_test.dart';

/// Dead-end removal (deep check 2026-08-20): a plan that lands WITHOUT
/// attachable actions must still leave refinable state, so the next
/// "confirm"/"Perfect" refines that plan instead of re-parsing bare and
/// restarting the "What time should I schedule it?" loop.

class _ScriptedParser implements AiIntentParser {
  _ScriptedParser(this._results);

  final List<AiPlannedChanges> _results;
  final List<AiPlannedChanges?> receivedPreviousPlans = [];
  int _next = 0;

  @override
  Future<AiPlannedChanges> parse(
    String userInput,
    String sessionId, {
    AiPlannedChanges? previousPlan,
    Map<String, dynamic>? proactiveContext,
    bool voiceMode = false,
  }) async {
    receivedPreviousPlans.add(previousPlan);
    return _results[_next++];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeExecutor implements AiActionExecutor {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeHistory implements AiInteractionHistoryRepository {
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

AiAssistantService _service(_ScriptedParser parser) => AiAssistantService(
  intentParser: parser,
  actionExecutor: _FakeExecutor(),
  historyRepository: _FakeHistory(),
);

const _planProse =
    "Here's the plan — confirm below:\n• Workout Session: 14:00–15:00\n"
    'Let me know if that works for you!';

void main() {
  test(
    'suggest with NO actions still parks refine context — "confirm" refines '
    'instead of re-parsing bare',
    () async {
      final parser = _ScriptedParser([
        AiPlannedChanges(
          sessionId: 's',
          responseType: AiResponseType.suggest,
          informationalMessage: _planProse,
        ),
        AiPlannedChanges(
          sessionId: 's',
          responseType: AiResponseType.mutate,
          actions: const [
            AiAction(
              actionType: ActionType.createTask,
              parameters: {
                'title': 'Workout Session',
                'time': '14:00',
                'duration': 60,
              },
            ),
          ],
        ),
      ]);
      final service = _service(parser);

      await service.sendMessage('plan a workout at 2 pm');
      await service.sendMessage('confirm');

      expect(parser.receivedPreviousPlans, hasLength(2));
      final refined = parser.receivedPreviousPlans[1];
      expect(refined, isNotNull,
          reason: '"confirm" must carry the parked plan into the parser');
      expect(refined!.isSuggest, isTrue);
      // And the refined turn produced a real confirmable plan.
      expect(service.hasPendingPlan, isTrue);
    },
  );

  test('plan-shaped INFORMATIONAL prose parks refine context too', () async {
    final parser = _ScriptedParser([
      AiPlannedChanges(
        sessionId: 's',
        responseType: AiResponseType.informational,
        informationalMessage: _planProse,
      ),
      AiPlannedChanges(
        sessionId: 's',
        responseType: AiResponseType.informational,
        informationalMessage: 'ok',
      ),
    ]);
    final service = _service(parser);

    await service.sendMessage('plan a workout at 2 pm');
    await service.sendMessage('Perfect');

    final refined = parser.receivedPreviousPlans[1];
    expect(refined, isNotNull);
    expect(refined!.isSuggest, isTrue,
        reason: 'parked prose plans refine with the suggest instruction');
  });

  test('ordinary informational answers park nothing', () async {
    final parser = _ScriptedParser([
      AiPlannedChanges(
        sessionId: 's',
        responseType: AiResponseType.informational,
        informationalMessage: 'You have a free evening ahead — enjoy it!',
      ),
      AiPlannedChanges(
        sessionId: 's',
        responseType: AiResponseType.informational,
        informationalMessage: 'ok',
      ),
    ]);
    final service = _service(parser);

    await service.sendMessage('how does my evening look?');
    await service.sendMessage('thanks!');

    expect(parser.receivedPreviousPlans[1], isNull);
  });
}
