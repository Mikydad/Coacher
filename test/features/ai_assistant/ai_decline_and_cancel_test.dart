import 'package:sidepal/features/ai_assistant/application/ai_action_executor.dart';
import 'package:sidepal/features/ai_assistant/application/ai_assistant_service.dart';
import 'package:sidepal/features/ai_assistant/application/ai_intent_parser.dart';
import 'package:sidepal/features/ai_assistant/data/ai_interaction_history_repository.dart';
import 'package:sidepal/features/ai_assistant/domain/models/ai_action.dart';
import 'package:sidepal/features/ai_assistant/domain/models/ai_chat_message.dart';
import 'package:sidepal/features/ai_assistant/domain/models/ai_planned_changes.dart';
import 'package:sidepal/features/ai_assistant/domain/models/ai_response_type.dart';
import 'package:flutter_test/flutter_test.dart';

/// 2026-08-22 bug batch: polite declines must resolve locally (never reach
/// the parser, which has misread them as delete-everything commands), and a
/// cancelled preview card must become inert instead of keeping a live
/// Confirm button.

class _CountingParser implements AiIntentParser {
  _CountingParser(this._results);
  final List<AiPlannedChanges> _results;
  int calls = 0;

  @override
  Future<AiPlannedChanges> parse(
    String userInput,
    String sessionId, {
    AiPlannedChanges? previousPlan,
    Map<String, dynamic>? proactiveContext,
    bool voiceMode = false,
    String? retryTurnId,
  }) async => _results[calls++];

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _RecordingExecutor implements AiActionExecutor {
  final List<List<AiAction>> executed = [];

  @override
  Future<ExecutionResult> execute(List<AiAction> actions) async {
    executed.add(actions);
    return const ExecutionResult(successes: ['done']);
  }

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

final _suggestPlan = AiPlannedChanges(
  sessionId: 's',
  responseType: AiResponseType.suggest,
  informationalMessage: 'Want me to schedule a study session at 14:00?',
  actions: const [
    AiAction(
      actionType: ActionType.createTask,
      parameters: {
        'title': 'Study',
        'time': '14:00',
        'duration': 30,
        'date': 'today',
      },
    ),
  ],
);

void main() {
  (AiAssistantService, _CountingParser, _RecordingExecutor) build(
    List<AiPlannedChanges> scripted,
  ) {
    final parser = _CountingParser(scripted);
    final executor = _RecordingExecutor();
    final service = AiAssistantService(
      intentParser: parser,
      actionExecutor: executor,
      historyRepository: _FakeHistory(),
    );
    return (service, parser, executor);
  }

  group('standalone decline', () {
    for (final phrase in [
      'No thank you',
      'no thanks',
      "no that's it",
      "that's all",
      'nothing else',
      "I'm good",
    ]) {
      test('"$phrase" resolves locally — the parser is never called',
          () async {
        final (service, parser, executor) = build([_suggestPlan]);
        // Park a suggestion first so the decline has something to decline.
        await service.sendMessage('help me plan today');
        expect(parser.calls, 1);

        await service.sendMessage(phrase);

        expect(parser.calls, 1, reason: 'decline must not reach the parser');
        expect(executor.executed, isEmpty);
        expect(service.hasPendingPlan, isFalse);
        expect(
          service.messages.last.content,
          contains('change your mind'),
        );
      });
    }
  });

  group('cancelled plan card', () {
    test('saying no to a pending plan stamps its card cancelled and inert',
        () async {
      final (service, parser, executor) = build([_mutatePlan]);
      await service.sendMessage('add workout at 2pm');
      expect(service.hasPendingPlan, isTrue);

      final card = service.messages.lastWhere(
        (m) => m.plannedChanges != null,
      );
      expect(card.isCurrentPlan, isTrue);

      await service.sendMessage('no thank you');

      expect(service.hasPendingPlan, isFalse);
      expect(executor.executed, isEmpty);
      final cancelled = service.messages.firstWhere((m) => m.id == card.id);
      expect(cancelled.isCancelled, isTrue);
      expect(cancelled.isCurrentPlan, isFalse);
      expect(cancelled.isExecuted, isFalse);
      expect(parser.calls, 1);
    });

    test('cancelPlan() from the button marks the card the same way', () async {
      final (service, _, _) = build([_mutatePlan]);
      await service.sendMessage('add workout at 2pm');
      final card = service.messages.lastWhere(
        (m) => m.plannedChanges != null,
      );

      service.cancelPlan();

      final cancelled = service.messages.firstWhere((m) => m.id == card.id);
      expect(cancelled.isCancelled, isTrue);
      expect(service.hasPendingPlan, isFalse);
    });
  });

  group('editPlan focus modes', () {
    test('voice edit (focusInput: false) never requests keyboard focus',
        () async {
      final (service, _, _) = build([_mutatePlan]);
      await service.sendMessage('add workout at 2pm');

      service.editPlan(focusInput: false);
      expect(service.inputFocusRequested, isFalse);

      service.editPlan();
      expect(service.inputFocusRequested, isTrue);
    });
  });

  group('copyWith isCancelled', () {
    test('round-trips through copyWith', () {
      final msg = AiChatMessage(
        id: 'm',
        role: ChatRole.assistant,
        content: 'x',
        timestamp: DateTime(2026),
      );
      expect(msg.isCancelled, isFalse);
      expect(msg.copyWith(isCancelled: true).isCancelled, isTrue);
    });
  });
}
