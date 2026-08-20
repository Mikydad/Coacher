import 'package:sidepal/core/ai/ai_proxy_client.dart';
import 'package:sidepal/features/ai_assistant/application/ai_operating_layer_client.dart';
import 'package:sidepal/features/ai_assistant/domain/models/ai_action.dart';
import 'package:sidepal/features/ai_assistant/domain/models/ai_operating_layer_payload.dart';
import 'package:sidepal/features/ai_assistant/domain/models/ai_response_type.dart';
import 'package:flutter_test/flutter_test.dart';

/// Hardening from the 2026-08-20 deep check: plan-bearing model turns must
/// never degrade to text-only informational bubbles — split tool calls
/// merge, malformed calls get a repair round, alias params normalize, and
/// prose plans are nudged back into the tool call.

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

const _validCall = AiProxyToolCall(
  id: 'call_ok',
  name: 'propose_changes',
  arguments:
      '{"presentation":"preview","actions":[{"actionType":"createTask",'
      '"parameters":{"title":"Workout Session","time":"14:00","duration":60}}]}',
);

void main() {
  test('two propose_changes calls in one round merge their actions', () async {
    final proxy = _ScriptedProxy([
      const AiProxyChatResult(
        content: 'Here is the plan — confirm below.',
        toolCalls: [
          AiProxyToolCall(
            id: 'c1',
            name: 'propose_changes',
            arguments:
                '{"presentation":"preview","actions":[{"actionType":"createTask",'
                '"parameters":{"title":"Study","time":"18:30","duration":60}}]}',
          ),
          AiProxyToolCall(
            id: 'c2',
            name: 'propose_changes',
            arguments:
                '{"presentation":"preview","actions":[{"actionType":"createTask",'
                '"parameters":{"title":"Call Mulu","time":"21:00","duration":15}}]}',
          ),
        ],
      ),
    ]);
    final client = ProxyAiOperatingLayerClient(proxy: proxy);

    final result = await client.parseIntent(_payload);

    expect(result.responseType, AiResponseType.mutate);
    expect(result.actions, hasLength(2));
    expect(result.actions.map((a) => a.parameters['title']),
        containsAll(['Study', 'Call Mulu']));
  });

  test('alias keys and 12-hour times normalize at ingestion', () async {
    final proxy = _ScriptedProxy([
      const AiProxyChatResult(
        toolCalls: [
          AiProxyToolCall(
            id: 'c1',
            name: 'propose_changes',
            arguments:
                '{"presentation":"preview","actions":[{"actionType":"createTask",'
                '"parameters":{"title":"Workout Session","startTime":"2 pm",'
                '"durationMinutes":60}}]}',
          ),
        ],
      ),
    ]);
    final client = ProxyAiOperatingLayerClient(proxy: proxy);

    final result = await client.parseIntent(_payload);

    final params = result.actions.single.parameters;
    expect(params['time'], '14:00');
    expect(params['duration'], 60);
  });

  test('a double-encoded actions array still parses', () async {
    final proxy = _ScriptedProxy([
      const AiProxyChatResult(
        toolCalls: [
          AiProxyToolCall(
            id: 'c1',
            name: 'propose_changes',
            arguments:
                '{"presentation":"preview","actions":"[{\\"actionType\\":\\"createTask\\",'
                '\\"parameters\\":{\\"title\\":\\"Workout\\",\\"time\\":\\"14:00\\",'
                '\\"duration\\":30}}]"}',
          ),
        ],
      ),
    ]);
    final client = ProxyAiOperatingLayerClient(proxy: proxy);

    final result = await client.parseIntent(_payload);

    expect(result.actions.single.parameters['title'], 'Workout');
  });

  test(
    'empty-actions propose_changes gets a tool-error repair round, then maps '
    'the retry',
    () async {
      final proxy = _ScriptedProxy([
        const AiProxyChatResult(
          content: "Here's the plan — confirm below.",
          toolCalls: [
            AiProxyToolCall(
              id: 'c_bad',
              name: 'propose_changes',
              arguments: '{"presentation":"preview","actions":[]}',
            ),
          ],
        ),
        const AiProxyChatResult(content: 'Retrying.', toolCalls: [_validCall]),
      ]);
      final client = ProxyAiOperatingLayerClient(proxy: proxy);

      final result = await client.parseIntent(_payload);

      expect(proxy.calls, hasLength(2));
      final repairMessages = proxy.calls[1];
      expect(
        repairMessages.any(
          (m) =>
              m['role'] == 'tool' &&
              (m['content'] as String).contains('empty or malformed'),
        ),
        isTrue,
      );
      expect(result.responseType, AiResponseType.mutate);
      expect(result.actions.single.parameters['title'], 'Workout Session');
    },
  );

  test('exhausted repairs end in a follow-up question, never a prose plan',
      () async {
    final bad = AiProxyChatResult(
      content: "Here's the plan — confirm below.",
      toolCalls: const [
        AiProxyToolCall(
          id: 'c_bad',
          name: 'propose_changes',
          arguments: '{"presentation":"preview","actions":[]}',
        ),
      ],
    );
    final proxy = _ScriptedProxy([bad, bad, bad, bad, bad]);
    final client = ProxyAiOperatingLayerClient(proxy: proxy);

    final result = await client.parseIntent(_payload);

    expect(result.requiresFollowUp, isTrue);
    expect(result.actions, isEmpty);
    // The dead-end informational-with-plan-prose degrade is gone.
    expect(result.informationalMessage, isNull);
  });

  test('a prose plan on a mutate turn is nudged into the tool call', () async {
    final proxy = _ScriptedProxy([
      const AiProxyChatResult(
        content:
            "Here's the plan — confirm below:\n• Workout Session: 14:00–15:00",
      ),
      const AiProxyChatResult(content: 'Confirm below.', toolCalls: [_validCall]),
    ]);
    final client = ProxyAiOperatingLayerClient(proxy: proxy);

    final result = await client.parseIntent(
      const AiOperatingLayerPayload(userInput: 'x', intentKind: 'mutate'),
    );

    expect(proxy.calls, hasLength(2));
    expect(
      proxy.calls[1].any(
        (m) =>
            m['role'] == 'user' &&
            (m['content'] as String).contains('without calling propose_changes'),
      ),
      isTrue,
    );
    expect(result.responseType, AiResponseType.mutate);
    expect(result.actions, hasLength(1));
  });

  test('plan-shaped prose on a QUERY turn stays informational (no nudge)',
      () async {
    final proxy = _ScriptedProxy([
      const AiProxyChatResult(
        content:
            "Here's the plan — confirm below:\n• Workout Session: 14:00–15:00",
      ),
    ]);
    final client = ProxyAiOperatingLayerClient(proxy: proxy);

    final result = await client.parseIntent(
      const AiOperatingLayerPayload(userInput: 'x', intentKind: 'query'),
    );

    expect(proxy.calls, hasLength(1));
    expect(result.responseType, AiResponseType.informational);
  });
}
