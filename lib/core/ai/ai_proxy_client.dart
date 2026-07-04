import 'package:cloud_functions/cloud_functions.dart';

/// Thrown when the AI proxy call fails.
///
/// [statusCode] is a best-effort HTTP-style code mapped from the Cloud
/// Functions error code so existing callers can keep their 429/5xx handling.
class AiProxyException implements Exception {
  const AiProxyException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  bool get isRateLimit => statusCode == 429;

  @override
  String toString() =>
      'AiProxyException($message${statusCode != null ? ', status=$statusCode' : ''})';
}

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
      );
    } on AiProxyException {
      rethrow;
    } catch (e) {
      throw AiProxyException('Network error: $e');
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
          toolCalls.add(AiProxyToolCall(
            id: id,
            name: name,
            arguments: entry['arguments'] is String
                ? entry['arguments'] as String
                : '{}',
          ));
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
      );
    } on AiProxyException {
      rethrow;
    } catch (e) {
      throw AiProxyException('Network error: $e');
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
