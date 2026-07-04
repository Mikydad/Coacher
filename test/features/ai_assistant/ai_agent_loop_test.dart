import 'package:coach_for_life/core/ai/ai_proxy_client.dart';
import 'package:coach_for_life/features/ai_assistant/application/ai_operating_layer_client.dart';
import 'package:coach_for_life/features/ai_assistant/domain/models/ai_action.dart';
import 'package:coach_for_life/features/ai_assistant/domain/models/ai_operating_layer_payload.dart';
import 'package:coach_for_life/features/ai_assistant/domain/models/ai_response_type.dart';
import 'package:flutter_test/flutter_test.dart';

/// Scripted proxy: returns the queued results in order and records the
/// message lists it was called with.
class _ScriptedProxy implements AiProxyClient {
  _ScriptedProxy(this._script);

  final List<AiProxyChatResult> _script;
  final List<List<Map<String, dynamic>>> calls = [];

  @override
  Future<AiProxyChatResult> chatWithTools({
    required List<Map<String, dynamic>> messages,
    required List<Map<String, dynamic>> tools,
    required String turnId,
    required int loopIndex,
    double temperature = 0.4,
    int maxTokens = 800,
    String? purpose,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    calls.add(List.of(messages));
    return _script[calls.length - 1];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

const _payload = AiOperatingLayerPayload(userInput: 'session-input');

void main() {
  test('plain text response becomes an informational reply', () async {
    final proxy = _ScriptedProxy([
      const AiProxyChatResult(content: "You're free until 19:00 — take 45 minutes of study."),
    ]);
    final client = ProxyAiOperatingLayerClient(proxy: proxy);

    final result = await client.parseIntent(_payload);

    expect(result.responseType, AiResponseType.informational);
    expect(result.informationalMessage, contains('19:00'));
    expect(proxy.calls, hasLength(1));
  });

  test('propose_changes with presentation=preview maps to mutate', () async {
    final proxy = _ScriptedProxy([
      const AiProxyChatResult(
        content: "Adding your workout — confirm below.",
        toolCalls: [
          AiProxyToolCall(
            id: 'call_1',
            name: 'propose_changes',
            arguments:
                '{"presentation":"preview","actions":[{"actionType":"createTask",'
                '"parameters":{"title":"Workout","time":"06:00","duration":30,'
                '"date":"tomorrow"},"confidence":0.9}]}',
          ),
        ],
      ),
    ]);
    final client = ProxyAiOperatingLayerClient(proxy: proxy);

    final result = await client.parseIntent(_payload);

    expect(result.responseType, AiResponseType.mutate);
    expect(result.actions, hasLength(1));
    expect(result.actions.first.actionType, ActionType.createTask);
    expect(result.informationalMessage, contains('confirm'));
  });

  test('propose_changes with presentation=suggestion maps to suggest',
      () async {
    final proxy = _ScriptedProxy([
      const AiProxyChatResult(
        content: 'Your Study goal is behind — how about 14:00?',
        toolCalls: [
          AiProxyToolCall(
            id: 'call_1',
            name: 'propose_changes',
            arguments:
                '{"presentation":"suggestion","actions":[{"actionType":"createTask",'
                '"parameters":{"title":"Study","time":"14:00","duration":45,'
                '"date":"tomorrow"}}]}',
          ),
        ],
      ),
    ]);
    final client = ProxyAiOperatingLayerClient(proxy: proxy);

    final result = await client.parseIntent(_payload);

    expect(result.responseType, AiResponseType.suggest);
    expect(result.actions, hasLength(1));
    expect(result.informationalMessage, contains('Study goal'));
  });

  test('read tool is executed and its result fed back to the model',
      () async {
    final proxy = _ScriptedProxy([
      const AiProxyChatResult(
        toolCalls: [
          AiProxyToolCall(
            id: 'call_r1',
            name: 'get_day_schedule',
            arguments: '{"date":"2026-07-10"}',
          ),
        ],
      ),
      const AiProxyChatResult(content: 'July 10 is wide open.'),
    ]);
    final lookups = <String>[];
    final client = ProxyAiOperatingLayerClient(
      proxy: proxy,
      toolRunner: AiCoachToolRunner(
        dayScheduleLookup: (dateKey) async {
          lookups.add(dateKey);
          return 'Nothing scheduled on $dateKey.';
        },
      ),
    );

    final result = await client.parseIntent(_payload);

    expect(lookups, ['2026-07-10']);
    expect(result.responseType, AiResponseType.informational);
    expect(result.informationalMessage, contains('wide open'));

    // Second call must carry the assistant tool_calls echo + tool result.
    expect(proxy.calls, hasLength(2));
    final second = proxy.calls[1];
    final assistantEcho = second.firstWhere(
      (m) => m['role'] == 'assistant' && m.containsKey('tool_calls'),
    );
    expect(assistantEcho['tool_calls'], isNotEmpty);
    final toolMsg = second.firstWhere((m) => m['role'] == 'tool');
    expect(toolMsg['tool_call_id'], 'call_r1');
    expect(toolMsg['content'], contains('Nothing scheduled'));
  });

  test('malformed propose_changes arguments produce a friendly follow-up',
      () async {
    final proxy = _ScriptedProxy([
      const AiProxyChatResult(
        toolCalls: [
          AiProxyToolCall(
            id: 'call_bad',
            name: 'propose_changes',
            arguments: 'not-json',
          ),
        ],
      ),
    ]);
    final client = ProxyAiOperatingLayerClient(proxy: proxy);

    final result = await client.parseIntent(_payload);

    expect(result.requiresFollowUp, isTrue);
    expect(result.followUpQuestion, contains('rephrase'));
  });

  test('invalid tool date argument returns an error string, not a crash',
      () async {
    final runner = AiCoachToolRunner(
      dayScheduleLookup: (_) async => 'unused',
    );

    expect(
      await runner.run('get_day_schedule', {'date': 'tomorrow'}),
      contains('YYYY-MM-DD'),
    );
    expect(
      await runner.run('unknown_tool', {}),
      contains('unknown tool'),
    );
  });
}
