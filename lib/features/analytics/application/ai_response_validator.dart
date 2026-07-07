import '../domain/models/ai_summary_response.dart';
import '../domain/models/coaching_ai_payload.dart';
import '../domain/models/current_coaching_focus.dart';

/// Maximum word counts for AI-generated text fields.
const int kAiSummaryMaxSummaryWords = 100;
const int kAiSummaryMinSummaryWords = 5;
const int kAiSummaryMaxRecommendationWords = 60;
const int kAiSummaryMinRecommendationWords = 3;

/// Lightweight semantic validator for AI coaching summaries.
///
/// V1 scope: obvious contradiction protection only.
/// Does NOT build an AI judge, LLM verifier, or moderation pipeline.
///
/// Checks in order:
///   1. Required fields present
///   2. Length constraints (too short / too long)
///   3. Tone matches expected framing
///   4. Response does not obviously contradict the focus reason
class AiResponseValidator {
  const AiResponseValidator();

  /// Validate [response] against the [payload] that requested it.
  /// Returns a [AiSummaryResponse] with [validationOutcome] set.
  AiSummaryResponse validate({
    required AiSummaryResponse response,
    required CoachingAiPayload payload,
  }) {
    // 1. Required fields
    if (response.focusId.trim().isEmpty ||
        response.dailySummary.trim().isEmpty ||
        response.mainRecommendation.trim().isEmpty) {
      return response.withValidationOutcome(
        AiSummaryValidationOutcome.missingRequiredField,
      );
    }

    // 2. Length constraints
    final summaryWords = _wordCount(response.dailySummary);
    if (summaryWords < kAiSummaryMinSummaryWords) {
      return response.withValidationOutcome(
        AiSummaryValidationOutcome.tooVague,
      );
    }
    if (summaryWords > kAiSummaryMaxSummaryWords) {
      return response.withValidationOutcome(AiSummaryValidationOutcome.tooLong);
    }
    final recommendationWords = _wordCount(response.mainRecommendation);
    if (recommendationWords > kAiSummaryMaxRecommendationWords) {
      return response.withValidationOutcome(AiSummaryValidationOutcome.tooLong);
    }

    // 3. Tone must match expected framing tone
    final expectedTone = expectedToneForFraming(payload.framing);
    if (response.tone != expectedTone) {
      return response.withValidationOutcome(
        AiSummaryValidationOutcome.toneMismatch,
      );
    }

    // 4. Obvious contradiction check
    final contradiction = _detectContradiction(
      response: response,
      focusReason: focusReasonFromStorage(payload.focusReason),
    );
    if (contradiction != null) {
      return response.withValidationOutcome(contradiction);
    }

    return response.withValidationOutcome(AiSummaryValidationOutcome.passed);
  }

  // ─── Internal helpers ────────────────────────────────────────────────────────

  int _wordCount(String text) =>
      text.trim().isEmpty ? 0 : text.trim().split(RegExp(r'\s+')).length;

  /// V1 contradiction detection: check for rest/passive phrases when the focus
  /// demands action, and check for urgent phrases when the focus is reinforcement.
  ///
  /// Deliberately conservative — false negatives acceptable; false positives not.
  AiSummaryValidationOutcome? _detectContradiction({
    required AiSummaryResponse response,
    required FocusReason focusReason,
  }) {
    final combinedText =
        '${response.dailySummary} ${response.mainRecommendation}'.toLowerCase();

    // Risk/protection reasons must not recommend passive rest.
    const passivePhrases = [
      'take a rest',
      'rest day',
      'skip today',
      'take it easy',
      'don\'t worry about',
      'take the day off',
    ];

    const activeReasons = {
      FocusReason.imminentStreakRisk,
      FocusReason.overdueItemCritical,
      FocusReason.consistencyBreakdownAlert,
      FocusReason.goalDriftDetected,
    };

    if (activeReasons.contains(focusReason)) {
      for (final phrase in passivePhrases) {
        if (combinedText.contains(phrase)) {
          return AiSummaryValidationOutcome.contradictsFocus;
        }
      }
    }

    // Reinforcement reasons should not use alarmist / crisis language.
    const alarmPhrases = [
      'at risk',
      'about to fail',
      'losing streak',
      'falling behind',
      'critical warning',
    ];

    const positiveReasons = {
      FocusReason.reinforcingActiveStreak,
      FocusReason.highestMomentumLeverage,
    };

    if (positiveReasons.contains(focusReason)) {
      for (final phrase in alarmPhrases) {
        if (combinedText.contains(phrase)) {
          return AiSummaryValidationOutcome.contradictsFocus;
        }
      }
    }

    return null;
  }
}
