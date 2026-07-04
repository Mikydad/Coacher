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
