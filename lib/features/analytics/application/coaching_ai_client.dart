import 'dart:convert';

import '../../../core/ai/ai_proxy_client.dart';
import '../../coaching/domain/models/coaching_style.dart';
import '../domain/models/ai_summary_response.dart';
import '../domain/models/coaching_ai_payload.dart';

// ─── Abstract client ──────────────────────────────────────────────────────────

/// Provider-agnostic AI coaching client.
///
/// Concrete implementations must:
/// - Send the payload to the underlying AI provider
/// - Parse the response into [AiSummaryResponse]
/// - Throw [AiClientException] on any unrecoverable failure
///
/// The abstraction ensures the rest of the codebase never depends on
/// OpenAI-specific types — swapping providers requires only a new impl.
abstract class CoachingAiClient {
  Future<AiSummaryResponse> generateSummary(CoachingAiPayload payload);
}

// ─── Exception ────────────────────────────────────────────────────────────────

class AiClientException implements Exception {
  const AiClientException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  bool get isRateLimit => statusCode == 429;
  bool get isServerError => statusCode != null && statusCode! >= 500;

  @override
  String toString() =>
      'AiClientException($message${statusCode != null ? ', status=$statusCode' : ''})';
}

// ─── Proxy implementation ─────────────────────────────────────────────────────

/// Coaching client backed by the `aiChat` Cloud Function proxy.
///
/// Configuration:
/// - The OpenAI key never reaches the client — it lives in Secret Manager
///   and only the Cloud Function can read it. The model is pinned server-side.
/// - Prompt is built deterministically from [CoachingAiPayload].
///
/// Response contract expected from the model:
/// ```json
/// {
///   "dailySummary": "...",
///   "mainRecommendation": "...",
///   "tone": "encouraging|informative|assertive|supportive",
///   "framing": "momentum|recovery|protection|stabilization|consistency"
/// }
/// ```
class ProxyCoachingAiClient implements CoachingAiClient {
  ProxyCoachingAiClient({
    AiProxyClient? proxy,
    this.timeoutSeconds = 15,
  }) : _proxy = proxy ?? AiProxyClient();

  final AiProxyClient _proxy;
  final int timeoutSeconds;

  @override
  Future<AiSummaryResponse> generateSummary(CoachingAiPayload payload) async {
    payload.validate();

    final systemPrompt = _buildSystemPrompt(payload);
    final userPrompt = _buildUserPrompt(payload);

    String content;
    try {
      content = await _proxy.chat(
        messages: [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': userPrompt},
        ],
        temperature: 0.3, // Low temperature for consistent, controlled output
        maxTokens: 300,
        purpose: 'coaching_summary',
        timeout: Duration(seconds: timeoutSeconds),
      );
    } on AiProxyException catch (e) {
      throw AiClientException(e.message, statusCode: e.statusCode);
    }

    return _parseResponse(content, payload);
  }

  // ─── Prompt builders ───────────────────────────────────────────────────────

  String _buildSystemPrompt(CoachingAiPayload payload) {
    final framingGuidance = _framingGuidance(payload.framing);
    final toneGuidance = _toneGuidance(expectedToneForFraming(payload.framing));
    final maxSummary = payload.deliveryContext.maxSummaryWords;
    final maxRec = payload.deliveryContext.maxRecommendationWords;
    final notifMode = payload.deliveryContext.isNotificationDelivery
        ? ' The output will be shown as a push notification — be very concise.'
        : '';

    final framingName = payload.framing.name;
    final toneName = expectedToneForFraming(payload.framing).name;
    final styleInstruction = _styleInstruction(payload.coachingStyle);

    return '''
You are a precision behavioral coaching assistant. Your role is to transform structured behavioral data into a brief, psychologically coherent coaching message.

FRAMING RULE: Apply "$framingName" framing.$framingGuidance
TONE RULE: Use "$toneName" tone.$toneGuidance$notifMode
STYLE RULE: $styleInstruction

OUTPUT RULES:
- dailySummary: max $maxSummary words. Factual, behavioral, no fluff.
- mainRecommendation: max $maxRec words. One concrete action only.
- Do NOT invent metrics, goals, or behaviors not mentioned in the data.
- Do NOT use motivational clichés ("you got this", "crush it", "amazing").
- Do NOT contradict the coaching focus reason.

Respond ONLY with valid JSON matching this schema:
{"dailySummary": "...", "mainRecommendation": "...", "tone": "...", "framing": "..."}
''';
  }

  String _buildUserPrompt(CoachingAiPayload payload) {
    final evidenceLines = payload.topEvidence.entries
        .map((e) => '  - ${e.key}: ${e.value}')
        .join('\n');
    final traceLine = payload.evaluationTrace.take(3).join('; ');
    final patterns = payload.keyPatternCodes.join(', ');
    final timing = payload.deliveryContext.timingProfile;

    return '''
COACHING CONTEXT:
- Focus reason: ${payload.focusReason}
- Primary insight type: ${payload.primaryInsightType}
${payload.secondaryInsightType != null ? '- Secondary insight: ${payload.secondaryInsightType}' : ''}
- Focus score: ${(payload.focusScore * 100).toStringAsFixed(0)}%
- Urgency: ${(payload.urgencyScore * 100).toStringAsFixed(0)}%
- Time of day: $timing
- Key patterns: ${patterns.isEmpty ? 'none' : patterns}
- Evidence:
$evidenceLines
- Evaluation trace: $traceLine

Generate the coaching summary.
''';
  }

  // ─── Response parser ───────────────────────────────────────────────────────

  AiSummaryResponse _parseResponse(String content, CoachingAiPayload payload) {
    try {
      final inner = jsonDecode(content) as Map<String, dynamic>;

      return AiSummaryResponse(
        focusId: payload.focusId,
        summaryType: payload.summaryType,
        framing: coachingFramingFromStorage(inner['framing'] as String?),
        tone: coachingToneFromStorage(inner['tone'] as String?),
        dailySummary: inner['dailySummary'] as String? ?? '',
        mainRecommendation: inner['mainRecommendation'] as String? ?? '',
        generatedAtMs: DateTime.now().millisecondsSinceEpoch,
        promptVersion: payload.promptVersion,
        isFallback: false,
      );
    } catch (e) {
      throw AiClientException('Failed to parse AI response: $e');
    }
  }

  // ─── Framing/tone guidance strings ────────────────────────────────────────

  String _framingGuidance(CoachingFraming framing) {
    switch (framing) {
      case CoachingFraming.momentum:
        return ' Highlight forward motion and active progress.';
      case CoachingFraming.recovery:
        return ' Acknowledge the lapse without judgment and focus on re-engagement.';
      case CoachingFraming.protection:
        return ' Emphasize what\'s at stake and the concrete action needed to protect it.';
      case CoachingFraming.stabilization:
        return ' Calm the overload by focusing on the single most important action.';
      case CoachingFraming.consistency:
        return ' Reinforce the value of steady, predictable progress.';
    }
  }

  String _toneGuidance(CoachingTone tone) {
    switch (tone) {
      case CoachingTone.encouraging:
        return ' Energetic and positive without hype.';
      case CoachingTone.supportive:
        return ' Warm and empathetic without being sentimental.';
      case CoachingTone.assertive:
        return ' Direct and clear without being alarming.';
      case CoachingTone.informative:
        return ' Calm, factual, matter-of-fact.';
    }
  }

  /// Returns the style instruction appended to the system prompt (FR-D-14).
  String _styleInstruction(CoachingStyle style) {
    return switch (style) {
      CoachingStyle.supportive =>
        'Be warm and encouraging. Avoid guilt framing. Focus on small wins.',
      CoachingStyle.balanced =>
        'Be clear and friendly. Present facts and suggest action without pressure.',
      CoachingStyle.disciplined =>
        'Be direct. The user values accountability. State what\'s expected clearly.',
      CoachingStyle.intense =>
        'Be assertive. The user has high standards for themselves. Don\'t soften the message.',
    };
  }
}

// ─── Mock client ──────────────────────────────────────────────────────────────

/// Deterministic mock client for tests and offline mode.
/// Returns a predictable [AiSummaryResponse] without any network calls.
class MockCoachingAiClient implements CoachingAiClient {
  const MockCoachingAiClient({this.shouldFail = false});

  final bool shouldFail;

  @override
  Future<AiSummaryResponse> generateSummary(CoachingAiPayload payload) async {
    if (shouldFail) {
      throw const AiClientException('MockCoachingAiClient: forced failure');
    }
    return AiSummaryResponse(
      focusId: payload.focusId,
      summaryType: payload.summaryType,
      tone: expectedToneForFraming(payload.framing),
      dailySummary: '[mock] Coaching summary for focus: ${payload.focusReason}.',
      mainRecommendation: '[mock] Take the next planned action.',
      framing: payload.framing,
      generatedAtMs: payload.generatedAtMs,
      promptVersion: payload.promptVersion,
      isFallback: false,
    );
  }
}
