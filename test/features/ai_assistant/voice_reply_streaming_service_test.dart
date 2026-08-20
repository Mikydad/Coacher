import 'dart:async';

import 'package:sidepal/features/ai_assistant/application/ai_action_executor.dart';
import 'package:sidepal/features/ai_assistant/application/ai_assistant_service.dart';
import 'package:sidepal/features/ai_assistant/application/ai_assumption_engine.dart';
import 'package:sidepal/features/ai_assistant/application/ai_intent_parser.dart';
import 'package:sidepal/features/ai_assistant/application/ai_operating_layer_client.dart';
import 'package:sidepal/features/ai_assistant/application/ai_payload_assembler.dart';
import 'package:sidepal/features/ai_assistant/application/entity_normaliser.dart';
import 'package:sidepal/features/ai_assistant/data/ai_interaction_history_repository.dart';
import 'package:sidepal/features/ai_assistant/domain/models/ai_action.dart';
import 'package:sidepal/features/ai_assistant/domain/models/ai_chat_message.dart';
import 'package:sidepal/features/ai_assistant/domain/models/ai_intent_kind.dart';
import 'package:sidepal/features/ai_assistant/domain/models/ai_operating_layer_payload.dart';
import 'package:sidepal/features/ai_assistant/domain/models/ai_planned_changes.dart';
import 'package:sidepal/features/ai_assistant/domain/models/ai_response_type.dart';
import 'package:sidepal/features/planning/data/planning_repository.dart';
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
    bool voiceMode = false,
  }) async => _stubPayload;

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
  int saveCount = 0;

  @override
  Future<void> save({
    required String sessionId,
    required String userInput,
    required List<AiAction> parsedActions,
    String? resolvedCategory,
    String? assistantSummary,
    String? responseType,
  }) async {
    saveCount++;
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

AiAssistantService _makeService({
  required _RecordingHistory history,
  Stream<String> Function()? streamedReply,
  AiPlannedChanges? agentResult,
}) {
  final parser = AiIntentParser(
    client: _FakeClient(
      agentResult ??
          AiPlannedChanges(
            sessionId: 'x',
            responseType: AiResponseType.informational,
            informationalMessage: 'Buffered agent reply.',
          ),
    ),
    assembler: const _FakeAssembler(),
    assumptionEngine: AiAssumptionEngine(
      planningRepository: _FakePlanningRepo(),
      historyRepository: history,
      normaliser: const EntityNormaliser(),
    ),
  );
  return AiAssistantService(
    intentParser: parser,
    actionExecutor: _FakeExecutor(),
    historyRepository: history,
    voiceReplyStreamer: streamedReply == null
        ? null
        : (
            String userInput,
            String sessionId, {
            AiIntentRoute? route,
            Map<String, dynamic>? proactiveContext,
          }) => streamedReply(),
  );
}

void main() {
  const streamableQuery = "what's my plan for today?";

  group('tryStreamVoiceReply routing', () {
    test('null without an injected streamer', () {
      final service = _makeService(history: _RecordingHistory());
      expect(service.tryStreamVoiceReply(streamableQuery), isNull);
    });

    test('mutate-classified turns keep the agent path', () {
      final service = _makeService(
        history: _RecordingHistory(),
        streamedReply: () => Stream.value('hi'),
      );
      expect(service.tryStreamVoiceReply('add workout at 6am tomorrow'), isNull);
    });

    test('capability questions keep the canned fast path', () {
      final service = _makeService(
        history: _RecordingHistory(),
        streamedReply: () => Stream.value('hi'),
      );
      expect(service.tryStreamVoiceReply('what can you do?'), isNull);
    });

    test('other-day references need the get_day_schedule tool', () {
      final service = _makeService(
        history: _RecordingHistory(),
        streamedReply: () => Stream.value('hi'),
      );
      expect(service.tryStreamVoiceReply("what's my plan on friday?"), isNull);
    });

    test('query turns stream', () {
      final service = _makeService(
        history: _RecordingHistory(),
        streamedReply: () => Stream.value('hi'),
      );
      expect(service.tryStreamVoiceReply(streamableQuery), isNotNull);
    });
  });

  group('streamed voice turn', () {
    test('deltas grow the live bubble and finalize into history', () async {
      final history = _RecordingHistory();
      final service = _makeService(
        history: history,
        streamedReply: () =>
            Stream.fromIterable(['You have ', 'Study at 9:00 ', 'today.']),
      );

      final stream = service.tryStreamVoiceReply(streamableQuery)!;
      final deltas = await stream.toList();
      await Future<void>.delayed(Duration.zero);

      expect(deltas.join(), 'You have Study at 9:00 today.');
      expect(service.messages, hasLength(2));
      expect(service.messages.first.role, ChatRole.user);
      final bubble = service.messages.last;
      expect(bubble.role, ChatRole.assistant);
      expect(bubble.isLoading, isFalse);
      expect(bubble.content, 'You have Study at 9:00 today.');
      expect(service.isLoading, isFalse);
      expect(history.lastSummary, contains('Study'));
      expect(history.lastResponseType, 'informational');
    });

    test('zero-delta failure falls back to the agent path', () async {
      final history = _RecordingHistory();
      final service = _makeService(
        history: history,
        streamedReply: () => Stream.error(StateError('offline')),
      );

      final stream = service.tryStreamVoiceReply(streamableQuery)!;
      final deltas = await stream.toList();

      // The fallback reply arrives as ONE chunk so the voice loop speaks it.
      expect(deltas, ['Buffered agent reply.']);
      // The agent path rendered its own bubbles: user + assistant.
      expect(service.messages, hasLength(2));
      expect(service.messages.last.content, 'Buffered agent reply.');
      expect(service.isLoading, isFalse);
    });

    test('interrupt keeps the partial text as the reply', () async {
      final history = _RecordingHistory();
      final source = StreamController<String>();
      final service = _makeService(
        history: history,
        streamedReply: () => source.stream,
      );

      final stream = service.tryStreamVoiceReply(streamableQuery)!;
      final received = <String>[];
      final sub = stream.listen(received.add);
      source.add('First sentence.');
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();
      await Future<void>.delayed(Duration.zero);

      expect(received, ['First sentence.']);
      expect(service.messages.last.content, 'First sentence.');
      expect(service.messages.last.isLoading, isFalse);
      expect(service.isLoading, isFalse);
      await source.close();
    });
  });

  group('buildConversationalStreamMessages', () {
    test('system prompt is answer-only, history rides along, user prompt last',
        () {
      final payload = AiOperatingLayerPayload(
        userInput: 'how am i doing today?',
        sessionHistory: [
          {'role': 'user', 'content': 'earlier question'},
          {'role': 'assistant', 'content': 'earlier answer'},
          // tool_calls-shaped entry (no plain text content) must be skipped.
          {
            'role': 'assistant',
            'tool_calls': [
              {'id': 't1'},
            ],
          },
        ],
      );

      final messages = buildConversationalStreamMessages(payload);

      expect(messages.first['role'], 'system');
      expect(messages.first['content'], contains('answer-only'));
      expect(messages.first['content'], isNot(contains('propose_changes work')));
      expect(messages[1]['content'], 'earlier question');
      expect(messages[2]['content'], 'earlier answer');
      expect(messages, hasLength(4));
      expect(messages.last['role'], 'user');
      expect(messages.last['content'], contains('how am i doing today?'));
    });
  });
}
