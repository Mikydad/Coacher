import 'dart:async';

import 'package:sidepal/features/ai_assistant/application/ai_action_executor.dart';
import 'package:sidepal/features/ai_assistant/application/ai_assistant_service.dart';
import 'package:sidepal/features/ai_assistant/application/ai_intent_parser.dart';
import 'package:sidepal/features/ai_assistant/data/ai_interaction_history_repository.dart';
import 'package:sidepal/features/ai_assistant/domain/models/ai_action.dart';
import 'package:sidepal/features/ai_assistant/domain/models/ai_chat_message.dart';
import 'package:sidepal/features/ai_assistant/domain/models/ai_planned_changes.dart';
import 'package:sidepal/features/ai_assistant/domain/models/ai_response_type.dart';
import 'package:flutter_test/flutter_test.dart';

/// Honest failure & race guards (fix-wave Phase 3, AUDIT.md §8 H1/H10/R1/
/// R2/R3 + settled Q6): failed turns are retryable error bubbles that ride
/// the failed turn's quota window; a session rotation abandons in-flight
/// replies; Confirm cannot double-fire; typing during a turn queues.

class _ScriptedParser implements AiIntentParser {
  _ScriptedParser(this._results);
  final List<AiPlannedChanges Function()> _results;
  final List<String?> seenRetryTurnIds = [];
  final List<String> seenInputs = [];
  Completer<void>? gate;

  @override
  Future<AiPlannedChanges> parse(
    String userInput,
    String sessionId, {
    AiPlannedChanges? previousPlan,
    Map<String, dynamic>? proactiveContext,
    bool voiceMode = false,
    String? retryTurnId,
  }) async {
    seenInputs.add(userInput);
    seenRetryTurnIds.add(retryTurnId);
    final pending = gate;
    if (pending != null) await pending.future;
    return _results[(seenInputs.length - 1).clamp(0, _results.length - 1)]();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _SlowExecutor implements AiActionExecutor {
  int executeCalls = 0;

  @override
  Future<ExecutionResult> execute(List<AiAction> actions) async {
    executeCalls++;
    await Future<void>.delayed(const Duration(milliseconds: 20));
    return ExecutionResult(successes: ['done'], batchId: 'b$executeCalls');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeHistory implements AiInteractionHistoryRepository {
  final savedInputs = <String>[];

  @override
  Future<void> save({
    required String sessionId,
    required String userInput,
    required List<AiAction> parsedActions,
    String? resolvedCategory,
    String? assistantSummary,
    String? responseType,
  }) async {
    savedInputs.add(userInput);
  }

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

AiPlannedChanges _error({String? retryTurnId, String message = 'boom'}) =>
    AiPlannedChanges(
      sessionId: 's',
      responseType: AiResponseType.informational,
      isError: true,
      informationalMessage: message,
      retryTurnId: retryTurnId,
    );

AiPlannedChanges _info(String message) => AiPlannedChanges(
  sessionId: 's',
  responseType: AiResponseType.informational,
  informationalMessage: message,
);

final _mutatePlan = AiPlannedChanges(
  sessionId: 's',
  responseType: AiResponseType.mutate,
  actions: const [
    AiAction(
      actionType: ActionType.createTask,
      parameters: {
        'title': 'Workout',
        'time': '14:00',
        'duration': 30,
        'date': 'today',
      },
    ),
  ],
);

void main() {
  (AiAssistantService, _ScriptedParser, _SlowExecutor, _FakeHistory) build(
    List<AiPlannedChanges Function()> scripted,
  ) {
    final parser = _ScriptedParser(scripted);
    final executor = _SlowExecutor();
    final history = _FakeHistory();
    final service = AiAssistantService(
      intentParser: parser,
      actionExecutor: executor,
      historyRepository: history,
    );
    return (service, parser, executor, history);
  }

  group('H1 — retryable error bubbles', () {
    test('a failed turn renders an isError bubble carrying its retry state',
        () async {
      final (service, _, _, history) = build([
        () => _error(retryTurnId: 'turn_42', message: "You're offline."),
      ]);

      await service.sendMessage('plan my day');

      final bubble = service.messages.last;
      expect(bubble.isError, isTrue);
      expect(bubble.content, contains('offline'));
      expect(bubble.retryInput, 'plan my day');
      expect(bubble.retryTurnId, 'turn_42');
      // Error turns never persist to history — the turn didn't happen.
      expect(history.savedInputs, isEmpty);
      // And never arm a clarification (§8 H10 — the old followUpQuestion
      // shape told the model it had asked the user about being offline).
      expect(service.messages.where((m) => m.isLoading), isEmpty);
    });

    test('Retry re-runs the input and rides the failed turn\'s id', () async {
      final (service, parser, _, _) = build([
        () => _error(retryTurnId: 'turn_42'),
        () => _info('All good now.'),
      ]);

      await service.sendMessage('plan my day');
      final errorBubble = service.messages.last;
      await service.retryTurn(errorBubble.id);

      expect(parser.seenRetryTurnIds, [null, 'turn_42']);
      expect(parser.seenInputs, ['plan my day', 'plan my day']);
      // The error bubble is gone; the real answer stands.
      expect(service.messages.where((m) => m.isError), isEmpty);
      expect(service.messages.last.content, 'All good now.');
    });
  });

  group('R1 — session generation guard', () {
    test('a reply arriving after startNewSession is abandoned entirely',
        () async {
      final (service, parser, _, history) = build([() => _info('late reply')]);
      parser.gate = Completer<void>();

      final turn = service.sendMessage('slow question');
      await Future<void>.delayed(Duration.zero);
      service.startNewSession();
      parser.gate!.complete();
      await turn;

      // The late reply must not seed the new session's empty thread, and
      // the turn must not be persisted (it belonged to a dead session).
      expect(service.messages, isEmpty);
      expect(history.savedInputs, isEmpty);
      expect(service.isLoading, isFalse);
    });
  });

  group('R2 — confirm re-entrancy', () {
    test('a double-tap on Confirm executes the plan exactly once', () async {
      final (service, _, executor, _) = build([() => _mutatePlan]);
      await service.sendMessage('add workout at 2pm');
      final plan = service.pendingPlan;
      expect(plan, isNotNull);

      final first = service.confirmPlan(plan);
      final second = service.confirmPlan(plan);
      await Future.wait([first, second]);

      expect(executor.executeCalls, 1);
    });
  });

  group('Q6 — send queue', () {
    test('typing during a turn queues; the queued turn runs after settle',
        () async {
      final (service, parser, _, _) = build([
        () => _info('first answer'),
        () => _info('second answer'),
      ]);
      parser.gate = Completer<void>();

      final first = service.sendMessage('first question');
      await Future<void>.delayed(Duration.zero);
      // In flight → this queues (bubble now, parse later).
      await service.sendMessage('second question');
      expect(parser.seenInputs, ['first question']);
      expect(
        service.messages.where((m) => m.role == ChatRole.user),
        hasLength(2),
      );

      parser.gate!.complete();
      parser.gate = null;
      await first;
      // Let the microtask drain run the queued turn.
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(parser.seenInputs, ['first question', 'second question']);
      expect(service.messages.last.content, 'second answer');
    });
  });
}
