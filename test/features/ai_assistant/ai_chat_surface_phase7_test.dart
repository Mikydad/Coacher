import 'dart:async';

import 'package:sidepal/core/local_db/isar_collections/isar_ai_interaction_history.dart';
import 'package:sidepal/features/ai_assistant/application/ai_action_executor.dart';
import 'package:sidepal/features/ai_assistant/application/ai_assistant_service.dart';
import 'package:sidepal/features/ai_assistant/application/ai_intent_parser.dart';
import 'package:sidepal/features/ai_assistant/application/voice_reply_stream.dart';
import 'package:sidepal/features/ai_assistant/data/ai_interaction_history_repository.dart';
import 'package:sidepal/features/ai_assistant/domain/models/ai_action.dart';
import 'package:sidepal/features/ai_assistant/domain/models/ai_chat_message.dart';
import 'package:sidepal/features/ai_assistant/domain/models/ai_intent_kind.dart';
import 'package:sidepal/features/ai_assistant/domain/models/ai_planned_changes.dart';
import 'package:sidepal/features/ai_assistant/domain/models/ai_response_type.dart';
import 'package:flutter_test/flutter_test.dart';

/// Chat-surface warmth (fix-wave Phase 7, AUDIT.md §8 U1/U6/U10 + settled
/// Q7): typed turns stream with an agent fallback, an in-flight turn can be
/// stopped, a closed conversation survives its 10-minute restore window,
/// and a relaunch rehydrates the last same-day session as marked history.

class _ScriptedParser implements AiIntentParser {
  _ScriptedParser(this._results);
  final List<AiPlannedChanges Function()> _results;
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
    final pending = gate;
    if (pending != null) await pending.future;
    return _results[(seenInputs.length - 1).clamp(0, _results.length - 1)]();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _NoopExecutor implements AiActionExecutor {
  @override
  Future<ExecutionResult> execute(List<AiAction> actions) async =>
      ExecutionResult(successes: ['done'], batchId: 'b1');

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeHistory implements AiInteractionHistoryRepository {
  final savedInputs = <String>[];
  List<IsarAiInteractionHistory> recentRows = [];

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
  Future<List<IsarAiInteractionHistory>> getRecent({int limit = 10}) async =>
      recentRows.take(limit).toList();

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

AiPlannedChanges _info(String message) => AiPlannedChanges(
  sessionId: 's',
  responseType: AiResponseType.informational,
  informationalMessage: message,
);

IsarAiInteractionHistory _row({
  required String sessionId,
  required String input,
  String? summary,
  required int timestampMs,
}) {
  return IsarAiInteractionHistory()
    ..sessionId = sessionId
    ..userInput = input
    ..parsedActionsJson = '[]'
    ..confirmed = false
    ..executed = false
    ..assistantSummary = summary
    ..timestampMs = timestampMs;
}

void main() {
  (AiAssistantService, _ScriptedParser, _FakeHistory) build(
    List<AiPlannedChanges Function()> scripted, {
    VoiceReplyStreamer? streamer,
  }) {
    final parser = _ScriptedParser(scripted);
    final history = _FakeHistory();
    final service = AiAssistantService(
      intentParser: parser,
      actionExecutor: _NoopExecutor(),
      historyRepository: history,
      voiceReplyStreamer: streamer,
    );
    return (service, parser, history);
  }

  group('U1 — typed streaming with agent fallback', () {
    test('a query turn streams deltas into one live assistant bubble',
        () async {
      final typedFlags = <bool>[];
      Stream<String> streamer(
        String input,
        String sessionId, {
        AiIntentRoute? route,
        Map<String, dynamic>? proactiveContext,
        bool typed = false,
      }) async* {
        typedFlags.add(typed);
        yield 'You have ';
        yield 'two tasks today.';
      }

      final (service, parser, history) = build(const [], streamer: streamer);
      await service.sendMessage("what's on my schedule today?");

      // The streamed path answered — the agent parser never ran.
      expect(parser.seenInputs, isEmpty);
      expect(typedFlags, [true]);
      expect(service.messages.last.role, ChatRole.assistant);
      expect(service.messages.last.content, 'You have two tasks today.');
      expect(service.messages.last.isLoading, isFalse);
      expect(service.isLoading, isFalse);
      // Streamed answers persist to history like any informational turn.
      expect(history.savedInputs, ["what's on my schedule today?"]);
    });

    test('a stream that dies before any delta falls back to the agent path',
        () async {
      Stream<String> streamer(
        String input,
        String sessionId, {
        AiIntentRoute? route,
        Map<String, dynamic>? proactiveContext,
        bool typed = false,
      }) async* {
        throw Exception('upstream dead');
      }

      final (service, parser, _) = build([
        () => _info('Agent answer.'),
      ], streamer: streamer);
      await service.sendMessage("what's on my schedule today?");

      expect(parser.seenInputs, ["what's on my schedule today?"]);
      expect(service.messages.last.content, 'Agent answer.');
      expect(service.isLoading, isFalse);
    });

    test('a mutate-shaped turn never takes the streaming path', () async {
      var streamCalls = 0;
      Stream<String> streamer(
        String input,
        String sessionId, {
        AiIntentRoute? route,
        Map<String, dynamic>? proactiveContext,
        bool typed = false,
      }) async* {
        streamCalls++;
      }

      final (service, parser, _) = build([
        () => _info('Planned.'),
      ], streamer: streamer);
      await service.sendMessage('add a workout at 6am tomorrow');

      expect(streamCalls, 0);
      expect(parser.seenInputs, ['add a workout at 6am tomorrow']);
    });
  });

  group('U1 — Stop on a thinking turn', () {
    test('cancelCurrentTurn frees the composer and abandons the late reply',
        () async {
      final (service, parser, history) = build([() => _info('late reply')]);
      parser.gate = Completer<void>();

      final turn = service.sendMessage('slow question');
      await Future<void>.delayed(Duration.zero);
      expect(service.isLoading, isTrue);

      service.cancelCurrentTurn();
      expect(service.isLoading, isFalse);
      expect(service.messages.where((m) => m.isLoading), isEmpty);

      parser.gate!.complete();
      await turn;
      // The abandoned reply never lands, and the turn is not persisted.
      expect(service.messages.where((m) => m.role == ChatRole.assistant),
          isEmpty);
      expect(history.savedInputs, isEmpty);
    });

    test('cancel is a no-op when nothing is in flight', () {
      final (service, _, _) = build(const []);
      service.cancelCurrentTurn();
      expect(service.isLoading, isFalse);
      expect(service.messages, isEmpty);
    });
  });

  group('U6 — deferred session end and restore', () {
    test('startNewSession stashes the thread; restore brings it back whole',
        () async {
      final (service, _, _) = build([() => _info('Sure thing.')]);
      await service.sendMessage('hello coach');
      final oldSessionId = service.sessionId;
      final oldCount = service.messages.length;

      service.startNewSession();
      expect(service.messages, isEmpty);
      expect(service.canRestoreConversation, isTrue);

      service.restoreConversation();
      expect(service.messages.length, oldCount);
      expect(service.messages.first.content, 'hello coach');
      // Same sessionId — the session boundary never happened.
      expect(service.sessionId, oldSessionId);
      expect(service.canRestoreConversation, isFalse);
    });

    test('a message in the NEW session finalizes the stash', () async {
      final (service, _, _) = build([
        () => _info('First session.'),
        () => _info('Second session.'),
      ]);
      await service.sendMessage('first');
      service.startNewSession();
      expect(service.canRestoreConversation, isTrue);

      await service.sendMessage('second');
      // Moving on forfeits the restore — the old thread is gone for good.
      expect(service.canRestoreConversation, isFalse);
      expect(service.messages.first.content, 'second');
    });

    test('an empty thread stashes nothing', () {
      final (service, _, _) = build(const []);
      service.startNewSession();
      expect(service.canRestoreConversation, isFalse);
    });
  });

  group('U10 — launch rehydration', () {
    test('the last same-day session comes back as marked history', () async {
      final (service, _, history) = build(const []);
      final now = DateTime.now().millisecondsSinceEpoch;
      history.recentRows = [
        // getRecent is newest-first.
        _row(
          sessionId: 's2',
          input: 'and tomorrow?',
          summary: 'Tomorrow is free.',
          timestampMs: now - 1000,
        ),
        _row(
          sessionId: 's2',
          input: 'what did I plan today?',
          summary: 'Two tasks this afternoon.',
          timestampMs: now - 2000,
        ),
        // Older session — must not ride along.
        _row(
          sessionId: 's1',
          input: 'old question',
          summary: 'old answer',
          timestampMs: now - 3000,
        ),
      ];

      await service.hydrateFromHistory();

      expect(service.messages, hasLength(4));
      expect(service.messages.every((m) => m.isHistorical), isTrue);
      // Chronological order: oldest row of the latest session first.
      expect(service.messages.first.content, 'what did I plan today?');
      expect(service.messages.last.content, 'Tomorrow is free.');
      expect(
        service.messages.map((m) => m.content),
        isNot(contains('old question')),
      );
    });

    test('rows from a previous day never rehydrate', () async {
      final (service, _, history) = build(const []);
      history.recentRows = [
        _row(
          sessionId: 's1',
          input: 'yesterday question',
          summary: 'yesterday answer',
          timestampMs: DateTime.now()
              .subtract(const Duration(days: 1))
              .millisecondsSinceEpoch,
        ),
      ];

      await service.hydrateFromHistory();
      expect(service.messages, isEmpty);
    });

    test('hydration is idempotent and never touches a live thread', () async {
      final (service, _, history) = build([() => _info('Live answer.')]);
      await service.sendMessage('live question');
      history.recentRows = [
        _row(
          sessionId: 's9',
          input: 'stale',
          summary: 'stale',
          timestampMs: DateTime.now().millisecondsSinceEpoch,
        ),
      ];

      await service.hydrateFromHistory();
      expect(
        service.messages.map((m) => m.content),
        isNot(contains('stale')),
      );
    });
  });
}
