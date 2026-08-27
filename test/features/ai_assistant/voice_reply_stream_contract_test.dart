import 'dart:convert';

import 'package:sidepal/features/ai_assistant/application/voice_reply_stream.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// The honest stream-ending contract (fix-wave Phase 3, §8 H5/G18):
/// a reply is complete ONLY when the server says {"done":true,"finish":
/// "stop"}. An upstream error line, a token-cap finish, or a pipe that
/// dies without the marker all surface as [AiVoiceStreamTruncated] AFTER
/// the received deltas — half-sentence replies must never look finished.

http.Client Function() _serving(List<String> ndjsonLines) =>
    () => MockClient.streaming((request, bodyStream) async {
      final body = Stream<List<int>>.value(
        utf8.encode('${ndjsonLines.join('\n')}\n'),
      );
      return http.StreamedResponse(body, 200);
    });

Stream<String> _stream(List<String> lines) => streamCoachReply(
  endpoint: Uri.parse('https://example.com/aiChatStream'),
  idToken: () async => 'token',
  messages: const [
    {'role': 'user', 'content': 'hi'},
  ],
  clientFactory: _serving(lines),
);

void main() {
  test('a clean finish yields the deltas and closes without error', () async {
    final deltas = await _stream([
      '{"d":"Hello "}',
      '{"d":"there."}',
      '{"done":true,"finish":"stop"}',
    ]).toList();

    expect(deltas, ['Hello ', 'there.']);
  });

  test('a legacy done marker without finish still counts as clean',
      () async {
    final deltas = await _stream(['{"d":"Hi."}', '{"done":true}']).toList();
    expect(deltas, ['Hi.']);
  });

  Future<(List<String>, Object?)> collect(List<String> lines) async {
    final received = <String>[];
    Object? error;
    try {
      await for (final delta in _stream(lines)) {
        received.add(delta);
      }
    } catch (e) {
      error = e;
    }
    return (received, error);
  }

  test('stream ending WITHOUT the done marker errors after the deltas',
      () async {
    final (received, error) = await collect(['{"d":"Half a sen"}']);

    expect(received, ['Half a sen']);
    expect(error, isA<AiVoiceStreamTruncated>());
  });

  test('a token-cap finish ("length") errors — the reply was clipped',
      () async {
    final (received, error) = await collect([
      '{"d":"Long reply that got"}',
      '{"done":true,"finish":"length"}',
    ]);

    expect(received, ['Long reply that got']);
    expect(error, isA<AiVoiceStreamTruncated>());
  });

  test('an upstream error line errors after the deltas', () async {
    final (received, error) = await collect([
      '{"d":"Partial"}',
      '{"e":"upstream"}',
    ]);

    expect(received, ['Partial']);
    expect(error, isA<AiVoiceStreamTruncated>());
  });
}
