import 'package:sidepal/features/ai_assistant/application/ai_action_executor.dart';
import 'package:sidepal/features/ai_assistant/application/ai_assistant_service.dart';
import 'package:sidepal/features/ai_assistant/application/ai_intent_parser.dart';
import 'package:sidepal/features/ai_assistant/application/voice_plan_speech.dart';
import 'package:sidepal/features/ai_assistant/data/ai_interaction_history_repository.dart';
import 'package:sidepal/features/ai_assistant/domain/models/ai_action.dart';
import 'package:sidepal/features/ai_assistant/domain/models/ai_planned_changes.dart';
import 'package:sidepal/features/ai_assistant/domain/models/ai_response_type.dart';
import 'package:flutter_test/flutter_test.dart';

/// Confirm-by-voice (2026-08-21): on the orb-only stage the card is
/// invisible, so the voice reads the plan and "confirm"/"no" IS the button.

class _ScriptedParser implements AiIntentParser {
  _ScriptedParser(this._results);
  final List<AiPlannedChanges> _results;
  int _next = 0;

  @override
  Future<AiPlannedChanges> parse(
    String userInput,
    String sessionId, {
    AiPlannedChanges? previousPlan,
    Map<String, dynamic>? proactiveContext,
    bool voiceMode = false,
    String? retryTurnId,
  }) async => _results[_next++];

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _RecordingExecutor implements AiActionExecutor {
  final List<List<AiAction>> executed = [];

  @override
  Future<ExecutionResult> execute(List<AiAction> actions) async {
    executed.add(actions);
    return const ExecutionResult(
      successes: ['Added "Workout Session" at 14:00'],
    );
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

final _workoutPlan = AiPlannedChanges(
  sessionId: 's',
  responseType: AiResponseType.mutate,
  actions: const [
    AiAction(
      actionType: ActionType.createTask,
      parameters: {
        'title': 'Workout Session',
        'time': '14:00',
        'duration': 60,
        'date': 'today',
      },
    ),
  ],
);

void main() {
  group('spoken plan preview', () {
    test('a pending preview is read aloud with the confirm ask', () async {
      final service = AiAssistantService(
        intentParser: _ScriptedParser([_workoutPlan]),
        actionExecutor: _RecordingExecutor(),
        historyRepository: _FakeHistory(),
      );

      await service.sendMessage('plan a workout at 2pm', voiceMode: true);

      final spoken = service.latestSpokenReplyText();
      expect(spoken, contains('Workout Session'));
      expect(spoken, contains('2 PM'));
      expect(spoken, contains('an hour'));
      expect(spoken, contains('Just say confirm'));
    });

    test('a suggested draft is offered for voice confirmation', () async {
      final service = AiAssistantService(
        intentParser: _ScriptedParser([
          AiPlannedChanges(
            sessionId: 's',
            responseType: AiResponseType.suggest,
            informationalMessage: 'How about a workout at 2 PM?',
            actions: _workoutPlan.actions,
          ),
        ]),
        actionExecutor: _RecordingExecutor(),
        historyRepository: _FakeHistory(),
      );

      await service.sendMessage('help me plan my afternoon', voiceMode: true);

      final spoken = service.latestSpokenReplyText();
      expect(spoken, contains('How about a workout at 2 PM?'));
      expect(spoken, contains('Want me to set it up?'));
    });
  });

  group('voice confirm / reject', () {
    test('"confirm" executes the pending plan and the OUTCOME is spoken',
        () async {
      final executor = _RecordingExecutor();
      final service = AiAssistantService(
        intentParser: _ScriptedParser([_workoutPlan]),
        actionExecutor: executor,
        historyRepository: _FakeHistory(),
      );
      await service.sendMessage('plan a workout at 2pm', voiceMode: true);
      expect(service.hasPendingPlan, isTrue);

      await service.sendMessage('confirm', voiceMode: true);

      // Awaited execution: by the time sendMessage returns, the outcome
      // bubble exists — the voice loop speaks it, not the stale preview.
      expect(executor.executed, hasLength(1));
      expect(service.hasPendingPlan, isFalse);
      expect(service.latestSpokenReplyText(), contains('Workout Session'));
      expect(service.latestSpokenReplyText(),
          isNot(contains('Just say confirm')));
    });

    test('STT-flavored affirmations confirm too', () async {
      for (final phrase in ['confirmed', 'go for it', 'yes confirm', 'do it']) {
        final executor = _RecordingExecutor();
        final service = AiAssistantService(
          intentParser: _ScriptedParser([_workoutPlan]),
          actionExecutor: executor,
          historyRepository: _FakeHistory(),
        );
        await service.sendMessage('plan a workout', voiceMode: true);

        await service.sendMessage(phrase, voiceMode: true);

        expect(executor.executed, hasLength(1), reason: 'phrase="$phrase"');
      }
    });

    test('"no" cancels and the cancellation is spoken', () async {
      final executor = _RecordingExecutor();
      final service = AiAssistantService(
        intentParser: _ScriptedParser([_workoutPlan]),
        actionExecutor: executor,
        historyRepository: _FakeHistory(),
      );
      await service.sendMessage('plan a workout at 2pm', voiceMode: true);

      await service.sendMessage('no', voiceMode: true);

      expect(executor.executed, isEmpty);
      expect(service.hasPendingPlan, isFalse);
      expect(service.latestSpokenReplyText(), contains('cancelled'));
    });
  });

  group('formatPlanForSpeech', () {
    test('single task reads naturally', () {
      expect(
        formatPlanForSpeech(_workoutPlan),
        "I'll add Workout Session at 2 PM for an hour today.",
      );
    });

    test('multiple actions list with "and"', () {
      final plan = AiPlannedChanges(
        sessionId: 's',
        responseType: AiResponseType.mutate,
        actions: const [
          AiAction(
            actionType: ActionType.createTask,
            parameters: {'title': 'Study', 'time': '18:30'},
          ),
          AiAction(
            actionType: ActionType.deleteTask,
            parameters: {'taskTitle': 'Old habit'},
          ),
        ],
      );
      expect(
        formatPlanForSpeech(plan),
        "I'll add Study at 6:30 PM and delete Old habit.",
      );
    });

    test('long plans cap at three items plus a count', () {
      final plan = AiPlannedChanges(
        sessionId: 's',
        responseType: AiResponseType.mutate,
        actions: List.generate(
          5,
          (i) => AiAction(
            actionType: ActionType.createTask,
            parameters: {'title': 'Task $i', 'time': '0$i:00'},
          ),
        ),
      );
      final spoken = formatPlanForSpeech(plan);
      expect(spoken, contains('and 2 more steps'));
      expect(spoken, isNot(contains('Task 4')));
    });

    test('speakableTime covers am/pm and midnight edges', () {
      expect(speakableTime('14:00'), '2 PM');
      expect(speakableTime('09:05'), '9:05 AM');
      expect(speakableTime('00:30'), '12:30 AM');
      expect(speakableTime('12:00'), '12 PM');
      expect(speakableTime('later'), 'later');
    });
  });
}
