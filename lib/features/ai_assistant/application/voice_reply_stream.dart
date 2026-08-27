import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../domain/models/ai_intent_kind.dart';
import 'ai_operating_layer_client.dart';
import 'ai_payload_assembler.dart';

/// One process-lifetime keep-alive HTTP client for the voice streaming
/// endpoints (fix-wave Phase 4, §8 V4). Dart's keep-alive sockets belong
/// to their Client and die with close() — the old per-stream client paid a
/// fresh TCP+TLS handshake before EVERY first token, and the warmup's
/// "leaves the connection warm" claim was void because its client closed
/// immediately (the TTS adapter measured exactly this on device and moved
/// to a session-lifetime client; the chat transport never followed).
/// Interrupts abort the REQUEST (subscription cancel), not the client.
http.Client? _sharedVoiceClient;

http.Client sharedVoiceHttpClient() => _sharedVoiceClient ??= http.Client();

/// Test hook / recovery: drop the shared client so the next stream builds
/// a fresh one.
void resetSharedVoiceHttpClient() {
  _sharedVoiceClient?.close();
  _sharedVoiceClient = null;
}

/// The reply stream ended without a clean finish: an upstream error, a
/// token-cap truncation, or a dead pipe. Deltas received before it are
/// real; the reply as a whole is INCOMPLETE (fix-wave Phase 3, §8 H5).
class AiVoiceStreamTruncated implements Exception {
  const AiVoiceStreamTruncated(this.reason);
  final String reason;

  @override
  String toString() => 'AiVoiceStreamTruncated($reason)';
}

/// Client transport for the aiChatStream endpoint (voice Level 2).
///
/// POSTs the conversation and yields text deltas as the model writes them.
/// The response is NDJSON: {"d":"delta"} lines then a {"done":true,
/// "finish": …} terminator (or an {"e": …} error line).
/// Cancelling the returned stream aborts the in-flight REQUEST, which
/// aborts the server's upstream OpenAI request (interrupts stop billing) —
/// the shared keep-alive client itself survives.
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
  // The shared keep-alive client by default (§8 V4); a test-provided
  // factory gets a private client that closes with the stream.
  final ownsClient = clientFactory != null;
  final client = ownsClient ? clientFactory() : sharedVoiceHttpClient();
  var closed = false;
  StreamSubscription<String>? bodySub;

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
      // A broadcast-free single subscription we can cancel from onCancel:
      // cancelling aborts THIS response (and its socket) without killing
      // the shared client's keep-alive pool.
      final bodyStream = response.stream
          .timeout(idleTimeout)
          .transform(utf8.decoder);
      final done = Completer<void>();
      late final StreamSubscription<String> sub;
      var finished = false;
      void finish([Object? error]) {
        if (finished) return;
        finished = true;
        if (error != null && !closed) controller.addError(error);
        if (!done.isCompleted) done.complete();
      }

      void handleLine(String line) {
        final trimmed = line.trim();
        if (trimmed.isEmpty) return;
        try {
          final parsed = jsonDecode(trimmed);
          if (parsed is Map<String, dynamic>) {
            final delta = parsed['d'];
            if (delta is String && delta.isNotEmpty && !closed) {
              controller.add(delta);
            }
            // Honest ending contract (fix-wave Phase 3, §8 H5): the
            // server names how the reply ended. An explicit upstream
            // error — or a token-cap truncation — surfaces as a stream
            // error after the received deltas, never as a clean finish.
            if (parsed['e'] != null) {
              finish(const AiVoiceStreamTruncated('upstream error'));
              unawaited(sub.cancel());
              return;
            }
            if (parsed['done'] == true) {
              if (parsed['finish'] == 'length') {
                finish(const AiVoiceStreamTruncated('token cap'));
              } else {
                finish();
              }
              unawaited(sub.cancel());
              return;
            }
          }
        } catch (_) {
          // Torn line mid-flush — the carry buffer handles real splits;
          // anything else is skipped.
        }
      }

      sub = bodyStream.listen(
        (chunk) {
          carry += chunk;
          final lines = carry.split('\n');
          carry = lines.removeLast();
          for (final line in lines) {
            handleLine(line);
            if (finished) return;
          }
        },
        onError: (Object e) => finish(e),
        onDone: () {
          // Stream ended WITHOUT the done marker: the pipe died mid-reply.
          // Treating this as success is how half-sentence replies were
          // spoken and persisted as complete (§8 H5/G18).
          finish(const AiVoiceStreamTruncated('stream ended without done'));
        },
        cancelOnError: true,
      );
      bodySub = sub;
      await done.future;
    } catch (e) {
      if (!closed) controller.addError(e);
    }
  }

  controller.onListen = () {
    unawaited(
      run().whenComplete(() {
        closed = true;
        if (ownsClient) client.close();
        if (!controller.isClosed) controller.close();
      }),
    );
  };
  controller.onCancel = () {
    // Listener gone (interrupt): abort THIS request so the server aborts
    // upstream OpenAI — the shared client (and its keep-alive pool) lives.
    closed = true;
    final sub = bodySub;
    if (sub != null) {
      unawaited(sub.cancel());
    } else if (ownsClient) {
      client.close();
    } else {
      // No response yet on the shared client: recycle it so the pending
      // request cannot outlive the interrupt.
      resetSharedVoiceHttpClient();
    }
  };
  return controller.stream;
}

/// The shape [AiVoiceReplyStreamer.stream] exposes — a plain function type so
/// the service (and its tests) never touch the transport or Firebase.
typedef VoiceReplyStreamer =
    Stream<String> Function(
      String userInput,
      String sessionId, {
      AiIntentRoute? route,
      Map<String, dynamic>? proactiveContext,
    });

/// Payload → messages → NDJSON deltas for one streamed voice turn.
///
/// [endpoint] is a closure so Firebase is only touched at stream time —
/// providers construct this in VM tests where Firebase never initialized.
/// Cancellation propagates: `async*` forwards the listener's cancel into
/// [streamCoachReply], which aborts the HTTP request.
class AiVoiceReplyStreamer {
  AiVoiceReplyStreamer({
    required AiPayloadAssembler assembler,
    required Uri Function() endpoint,
    required Future<String?> Function() idToken,
    Stream<String> Function(List<Map<String, String>> messages)? transport,
  }) : _assembler = assembler,
       _endpoint = endpoint,
       _idToken = idToken,
       _transport = transport;

  final AiPayloadAssembler _assembler;
  final Uri Function() _endpoint;
  final Future<String?> Function() _idToken;
  final Stream<String> Function(List<Map<String, String>> messages)?
  _transport;

  Stream<String> stream(
    String userInput,
    String sessionId, {
    AiIntentRoute? route,
    Map<String, dynamic>? proactiveContext,
  }) async* {
    final assembleSw = Stopwatch()..start();
    final payload = await _assembler.assemble(
      userInput,
      sessionId,
      intentRoute: route,
      proactiveContext: proactiveContext,
      voiceMode: true,
    );
    final messages = buildConversationalStreamMessages(payload);
    if (kDebugMode) {
      debugPrint(
        '[ai-timing] assemble=${assembleSw.elapsedMilliseconds}ms '
        'stream=true voice=true',
      );
    }
    final transport = _transport;
    yield* transport != null
        ? transport(messages)
        : streamCoachReply(
            endpoint: _endpoint(),
            idToken: _idToken,
            messages: messages,
          );
  }
}
