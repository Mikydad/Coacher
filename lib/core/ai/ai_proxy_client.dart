import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart' show Uint8List;

/// Thrown when the AI proxy call fails.
///
/// [statusCode] is a best-effort HTTP-style code mapped from the Cloud
/// Functions error code so existing callers can keep their 429/5xx handling.
///
/// [isNetwork] tags connectivity failures (P2-13) so surfaces can say
/// "you're offline" instead of the misleading generic "something went
/// wrong" — network-inherent features get honesty, not fake blame.
class AiProxyException implements Exception {
  const AiProxyException(
    this.message, {
    this.statusCode,
    this.isNetwork = false,
    this.isTimeout = false,
  });

  final String message;
  final int? statusCode;
  final bool isNetwork;

  /// The request TOOK TOO LONG — distinct from [isNetwork] since fix-wave
  /// Phase 3 (§8 H3): 'deadline-exceeded' used to be classed as network,
  /// so slow-connection users were told "you're offline" while online.
  final bool isTimeout;

  bool get isRateLimit => statusCode == 429;

  @override
  String toString() =>
      'AiProxyException($message${statusCode != null ? ', status=$statusCode' : ''}'
      '${isNetwork ? ', network' : ''}${isTimeout ? ', timeout' : ''})';
}

/// Cloud Functions codes that mean "couldn't reach the server", as opposed
/// to "the server said no". 'deadline-exceeded' is deliberately NOT here —
/// it means SLOW, and belongs to [_isTimeoutFunctionsCode].
bool _isNetworkFunctionsCode(String code) => code == 'unavailable';

bool _isTimeoutFunctionsCode(String code) => code == 'deadline-exceeded';

bool _looksLikeNetworkError(Object e) =>
    e is SocketException || e is HttpException;

bool _looksLikeTimeoutError(Object e) => e is TimeoutException;

/// One tool invocation requested by the model during an agent turn.
class AiProxyToolCall {
  const AiProxyToolCall({
    required this.id,
    required this.name,
    required this.arguments,
  });

  final String id;
  final String name;

  /// Raw JSON-encoded arguments exactly as the model produced them.
  final String arguments;
}

/// Result of a tool-enabled chat call: natural-language [content], tool
/// calls to execute, or both.
class AiProxyChatResult {
  const AiProxyChatResult({this.content, this.toolCalls = const []});

  final String? content;
  final List<AiProxyToolCall> toolCalls;

  bool get hasToolCalls => toolCalls.isNotEmpty;
}

/// Client for the `aiChat` Cloud Function proxy.
///
/// All OpenAI traffic goes through this callable — the API key lives only in
/// Google Secret Manager on the server. The function authenticates the
/// Firebase user, pins the model server-side, and enforces per-user quotas.
///
/// Contract: send chat-completion `messages`, receive the assistant's
/// `content` string (JSON-mode output that callers parse themselves) — the
/// same contract the previous direct-OpenAI clients used.
class AiProxyClient {
  AiProxyClient({FirebaseFunctions? functions})
    : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;

  /// Sends [messages] to the proxy and returns the assistant content string.
  ///
  /// Throws [AiProxyException] on any failure.
  Future<String> chat({
    required List<Map<String, dynamic>> messages,
    double temperature = 0.2,
    int maxTokens = 800,
    String? purpose,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    try {
      final callable = _functions.httpsCallable(
        'aiChat',
        options: HttpsCallableOptions(timeout: timeout),
      );
      final result = await callable.call<Map<dynamic, dynamic>>({
        'messages': messages,
        'temperature': temperature,
        'maxTokens': maxTokens,
        if (purpose != null) 'purpose': purpose,
      });
      final content = result.data['content'];
      if (content is! String || content.isEmpty) {
        throw const AiProxyException('Empty AI response');
      }
      return content;
    } on FirebaseFunctionsException catch (e) {
      throw AiProxyException(
        e.message ?? e.code,
        statusCode: _statusCodeForFunctionsError(e.code),
        isNetwork: _isNetworkFunctionsCode(e.code),
        isTimeout: _isTimeoutFunctionsCode(e.code),
      );
    } on AiProxyException {
      rethrow;
    } catch (e) {
      throw AiProxyException(
        'Network error: $e',
        isNetwork: _looksLikeNetworkError(e),
        isTimeout: _looksLikeTimeoutError(e),
      );
    }
  }

  /// Tool-enabled variant for the Coach agent loop.
  ///
  /// [turnId] identifies one user turn; follow-up calls within the same turn
  /// (incrementing [loopIndex]) do not consume server quota. Messages may
  /// include `assistant` entries carrying `tool_calls` and `tool` entries
  /// carrying results.
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
    try {
      final callable = _functions.httpsCallable(
        'aiChat',
        options: HttpsCallableOptions(timeout: timeout),
      );
      final result = await callable.call<Map<dynamic, dynamic>>({
        'messages': messages,
        'tools': tools,
        'turnId': turnId,
        'loopIndex': loopIndex,
        'temperature': temperature,
        'maxTokens': maxTokens,
        if (purpose != null) 'purpose': purpose,
      });

      final content = result.data['content'];
      final rawCalls = result.data['toolCalls'];
      final toolCalls = <AiProxyToolCall>[];
      if (rawCalls is List) {
        for (final entry in rawCalls) {
          if (entry is! Map) continue;
          final id = entry['id'];
          final name = entry['name'];
          if (id is! String || name is! String) continue;
          toolCalls.add(
            AiProxyToolCall(
              id: id,
              name: name,
              arguments: entry['arguments'] is String
                  ? entry['arguments'] as String
                  : '{}',
            ),
          );
        }
      }

      if ((content is! String || content.isEmpty) && toolCalls.isEmpty) {
        throw const AiProxyException('Empty AI response');
      }
      return AiProxyChatResult(
        content: content is String && content.isNotEmpty ? content : null,
        toolCalls: toolCalls,
      );
    } on FirebaseFunctionsException catch (e) {
      throw AiProxyException(
        e.message ?? e.code,
        statusCode: _statusCodeForFunctionsError(e.code),
        isNetwork: _isNetworkFunctionsCode(e.code),
        isTimeout: _isTimeoutFunctionsCode(e.code),
      );
    } on AiProxyException {
      rethrow;
    } catch (e) {
      throw AiProxyException(
        'Network error: $e',
        isNetwork: _looksLikeNetworkError(e),
        isTimeout: _looksLikeTimeoutError(e),
      );
    }
  }

  /// Synthesizes [text] into audio bytes (mp3) via the `aiSpeech` proxy.
  ///
  /// Voice Mode's OpenAI voice. The voice itself is pinned server-side
  /// (Remote Config); the caller only sends the sanitized reply text.
  /// Throws [AiProxyException] on any failure — the voice stack treats
  /// every failure as "use the on-device voice", so no failure here is
  /// user-visible.
  Future<Uint8List> speak(
    String text, {
    Duration timeout = const Duration(seconds: 20),
  }) async {
    try {
      final callable = _functions.httpsCallable(
        'aiSpeech',
        options: HttpsCallableOptions(timeout: timeout),
      );
      final result = await callable.call<Map<dynamic, dynamic>>({'text': text});
      final audioB64 = result.data['audioB64'];
      if (audioB64 is! String || audioB64.isEmpty) {
        throw const AiProxyException('Empty speech response');
      }
      return base64Decode(audioB64);
    } on FirebaseFunctionsException catch (e) {
      throw AiProxyException(
        e.message ?? e.code,
        statusCode: _statusCodeForFunctionsError(e.code),
        isNetwork: _isNetworkFunctionsCode(e.code),
        isTimeout: _isTimeoutFunctionsCode(e.code),
      );
    } on AiProxyException {
      rethrow;
    } catch (e) {
      throw AiProxyException(
        'Network error: $e',
        isNetwork: _looksLikeNetworkError(e),
        isTimeout: _looksLikeTimeoutError(e),
      );
    }
  }

  static int? _statusCodeForFunctionsError(String code) {
    switch (code) {
      case 'resource-exhausted':
        return 429;
      case 'unauthenticated':
        return 401;
      case 'invalid-argument':
        return 400;
      case 'unavailable':
      case 'deadline-exceeded':
        return 503;
      case 'internal':
        return 500;
      default:
        return null;
    }
  }
}
