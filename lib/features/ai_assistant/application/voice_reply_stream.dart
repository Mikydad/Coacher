import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// Client transport for the aiChatStream endpoint (voice Level 2).
///
/// POSTs the conversation and yields text deltas as the model writes them.
/// The response is NDJSON: {"d":"delta"} lines then {"done":true}.
/// Cancelling the returned stream closes the HTTP client, which aborts the
/// server's upstream OpenAI request (interrupts stop billing).
///
/// Errors surface as stream errors AFTER any received deltas — callers
/// (the voice pipeline, the live thread bubble) treat partial text as the
/// reply and show honest copy separately.
Stream<String> streamCoachReply({
  required Uri endpoint,
  required Future<String?> Function() idToken,
  required List<Map<String, String>> messages,
  Duration connectTimeout = const Duration(seconds: 10),
  Duration idleTimeout = const Duration(seconds: 30),
  http.Client Function()? clientFactory,
}) {
  final controller = StreamController<String>();
  final client = (clientFactory ?? http.Client.new)();
  var closed = false;

  Future<void> run() async {
    try {
      final token = await idToken().timeout(connectTimeout);
      if (token == null || token.isEmpty) {
        throw StateError('No auth token for chat streaming');
      }
      final request = http.Request('POST', endpoint)
        ..headers['authorization'] = 'Bearer $token'
        ..headers['content-type'] = 'application/json'
        ..body = jsonEncode({'messages': messages});
      final response = await client.send(request).timeout(connectTimeout);
      if (response.statusCode != 200) {
        unawaited(response.stream.drain<void>().catchError((_) {}));
        throw http.ClientException(
          'aiChatStream HTTP ${response.statusCode}',
          endpoint,
        );
      }
      var carry = '';
      await for (final chunk in response.stream
          .timeout(idleTimeout)
          .transform(utf8.decoder)) {
        carry += chunk;
        final lines = carry.split('\n');
        carry = lines.removeLast();
        for (final line in lines) {
          final trimmed = line.trim();
          if (trimmed.isEmpty) continue;
          try {
            final parsed = jsonDecode(trimmed);
            if (parsed is Map<String, dynamic>) {
              final delta = parsed['d'];
              if (delta is String && delta.isNotEmpty && !closed) {
                controller.add(delta);
              }
              if (parsed['done'] == true) return;
            }
          } catch (_) {
            // Torn line mid-flush — the carry buffer handles real splits;
            // anything else is skipped.
          }
        }
      }
    } catch (e) {
      if (!closed) controller.addError(e);
    }
  }

  controller.onListen = () {
    unawaited(
      run().whenComplete(() {
        closed = true;
        client.close();
        if (!controller.isClosed) controller.close();
      }),
    );
  };
  controller.onCancel = () {
    // Listener gone (interrupt): kill the socket so the server aborts
    // upstream OpenAI.
    closed = true;
    client.close();
  };
  return controller.stream;
}
