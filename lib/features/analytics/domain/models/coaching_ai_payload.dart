import '../../../coaching/domain/models/coaching_style.dart';
import 'current_coaching_focus.dart';
import 'generated_insight.dart';

/// Current prompt template version. Increment when prompts change materially.
/// Used to correlate AI responses with specific prompt logic in analytics.
const String kCoachingAiPromptVersion = 'v1.0.0';

// ─── Coaching framing ─────────────────────────────────────────────────────────

/// Psychological framing applied to AI-generated coaching summaries.
/// Derived deterministically from [CurrentCoachingFocus] — never chosen by AI.
/// Ensures tone consistency and prevents random oscillation between framings.
enum CoachingFraming {
  /// Positive momentum: user is in a strong behavioral streak.
  momentum,

  /// Recovery: user is bouncing back from a missed or degraded period.
  recovery,

  /// Protection: an active streak or goal is at risk and needs guarding.
  protection,

  /// Stabilization: volatility is high; consistency is the priority.
  stabilization,

  /// Consistency: routine is stable; reinforce and maintain the pattern.
  consistency,
}

CoachingFraming coachingFramingFromStorage(String? raw) {
  for (final v in CoachingFraming.values) {
    if (v.name == raw) return v;
  }
  return CoachingFraming.consistency;
}

/// Derive the appropriate [CoachingFraming] from the focus reason, scores,
/// and the user's global [CoachingStyle].
///
/// The matrix for style-sensitive reasons (FR-D-12):
///
/// | FocusReason                  | supportive     | balanced       | disciplined    | intense        |
/// |------------------------------|---------------|----------------|----------------|----------------|
/// | imminentStreakRisk           | recovery       | protection     | protection     | protection     |
/// | highestMomentumLeverage      | momentum       | momentum       | momentum       | momentum       |
/// | bestRecoveryOpportunity      | recovery       | recovery       | recovery       | stabilization  |
/// | goalDriftDetected            | recovery       | stabilization  | stabilization  | protection     |
/// | consistencyBreakdownAlert    | stabilization  | stabilization  | protection     | protection     |
///
/// All other reasons use the existing logic unchanged.
CoachingFraming deriveCoachingFraming({
  required FocusReason focusReason,
  required double focusScore,
  required double urgencyScore,
  CoachingStyle coachingStyle = CoachingStyle.balanced,
}) {
  switch (focusReason) {
    case FocusReason.imminentStreakRisk:
      return switch (coachingStyle) {
        CoachingStyle.supportive => CoachingFraming.recovery,
        _ => CoachingFraming.protection,
      };

    case FocusReason.highestMomentumLeverage:
    case FocusReason.reinforcingActiveStreak:
      return CoachingFraming.momentum;

    case FocusReason.bestRecoveryOpportunity:
      return switch (coachingStyle) {
        CoachingStyle.intense => CoachingFraming.stabilization,
        _ => CoachingFraming.recovery,
      };

    case FocusReason.goalDriftDetected:
      return switch (coachingStyle) {
        CoachingStyle.supportive => CoachingFraming.recovery,
        CoachingStyle.intense => CoachingFraming.protection,
        _ => CoachingFraming.stabilization,
      };

    case FocusReason.consistencyBreakdownAlert:
      return switch (coachingStyle) {
        CoachingStyle.disciplined ||
        CoachingStyle.intense => CoachingFraming.protection,
        _ => CoachingFraming.stabilization,
      };

    case FocusReason.globalOverloadSignal:
      return CoachingFraming.stabilization;

    case FocusReason.overdueItemCritical:
      return urgencyScore >= 0.6
          ? CoachingFraming.protection
          : CoachingFraming.recovery;

    case FocusReason.scheduledWindowActive:
    case FocusReason.timingOpportunity:
      return focusScore >= 0.65
          ? CoachingFraming.momentum
          : CoachingFraming.consistency;
  }
}

// ─── Summary type ─────────────────────────────────────────────────────────────

/// The functional category of the AI-generated summary.
/// Used for routing (notifications), rendering, analytics, and experimentation.
enum SummaryType {
  /// Daily behavioral overview tied to the primary focus.
  daily,

  /// Focus-specific deep summary explaining the coaching decision.
  focus,

  /// Framed around helping the user recover from a lapse or setback.
  recovery,

  /// Positive reinforcement for a sustained behavior or streak.
  reinforcement,
}

SummaryType summaryTypeFromStorage(String? raw) {
  for (final v in SummaryType.values) {
    if (v.name == raw) return v;
  }
  return SummaryType.daily;
}

/// Derive the appropriate [SummaryType] from framing and insight type.
SummaryType deriveSummaryType({
  required CoachingFraming framing,
  required InsightType primaryInsightType,
}) {
  // Reinforcement insights always produce reinforcement summaries.
  const reinforcementInsightTypes = {
    InsightType.strongStreakPraise,
    InsightType.consistentBehaviorPraise,
    InsightType.goalProgressSuccess,
    InsightType.improvingConsistency,
  };
  if (reinforcementInsightTypes.contains(primaryInsightType)) {
    return SummaryType.reinforcement;
  }

  switch (framing) {
    case CoachingFraming.recovery:
      return SummaryType.recovery;
    case CoachingFraming.protection:
    case CoachingFraming.momentum:
      return SummaryType.focus;
    case CoachingFraming.stabilization:
    case CoachingFraming.consistency:
      return SummaryType.daily;
  }
}

// ─── Staleness policy ─────────────────────────────────────────────────────────

/// V1 base TTL values (ms). Structured to allow per-importance dynamic TTLs later.
const int kAiSummaryBaseTtlMs = 6 * 60 * 60 * 1000; // 6 h

/// Compute the staleness TTL for an AI summary based on focus importance.
/// V1: simple tier-based lookup. V2: continuous function over focusScore.
int computeAiSummaryTtlMs({
  required SummaryType summaryType,
  required double focusScore,
  required double urgencyScore,
}) {
  // High-urgency focuses go stale quickly — coach needs to be timely.
  if (urgencyScore >= 0.75 || focusScore >= 0.85) {
    return 1 * 60 * 60 * 1000; // 1 h
  }
  // Reinforcement and stable-routine summaries persist longer.
  if (summaryType == SummaryType.reinforcement) {
    return 12 * 60 * 60 * 1000; // 12 h
  }
  if (summaryType == SummaryType.daily && focusScore < 0.45) {
    return 18 * 60 * 60 * 1000; // 18 h — low-urgency routine
  }
  // Default mid-tier.
  return kAiSummaryBaseTtlMs; // 6 h
}

// ─── Delivery context ─────────────────────────────────────────────────────────

/// Lightweight delivery context embedded in the AI payload.
/// Helps the AI understand where/when the summary will appear.
class AiDeliveryContext {
  const AiDeliveryContext({
    required this.timingProfile,
    required this.localDateKey,
    this.isNotificationDelivery = false,
    this.maxSummaryWords = 80,
    this.maxRecommendationWords = 40,
  });

  /// Current time-of-day block (e.g. "morning", "evening").
  final String timingProfile;

  /// Calendar date key (YYYY-MM-DD) when the summary is generated.
  final String localDateKey;

  /// True when the summary will be delivered as a push notification.
  /// AI should produce shorter, punchier text in this mode.
  final bool isNotificationDelivery;

  /// Hard word-count ceiling for the daily summary text.
  final int maxSummaryWords;

  /// Hard word-count ceiling for the main recommendation.
  final int maxRecommendationWords;

  Map<String, dynamic> toMap() => {
    'timingProfile': timingProfile,
    'localDateKey': localDateKey,
    'isNotificationDelivery': isNotificationDelivery,
    'maxSummaryWords': maxSummaryWords,
    'maxRecommendationWords': maxRecommendationWords,
  };
}

// ─── Top-level AI payload ─────────────────────────────────────────────────────

/// Strict, token-efficient payload sent to the AI coaching summarizer.
///
/// Design rules:
/// - All behavioral truth comes from the deterministic engine — AI only
///   personalizes phrasing, never reinterprets the coaching decision.
/// - Fields are kept minimal. No raw insight lists — only focus + top context.
/// - [promptVersion] allows response attribution and regression detection.
class CoachingAiPayload {
  const CoachingAiPayload({
    required this.focusId,
    required this.focusReason,
    required this.framing,
    required this.summaryType,
    required this.primaryInsightType,
    required this.focusScore,
    required this.urgencyScore,
    required this.evaluationTrace,
    required this.keyPatternCodes,
    required this.topEvidence,
    required this.deliveryContext,
    required this.generatedAtMs,
    required this.promptVersion,
    this.coachingStyle = CoachingStyle.balanced,
    this.secondaryInsightType,
  });

  final String focusId;
  final String focusReason;

  /// The user's global coaching style — shapes AI tone and framing language.
  final CoachingStyle coachingStyle;

  /// Deterministic framing — defines the psychological lens the AI must use.
  final CoachingFraming framing;

  /// What kind of summary is expected in the response.
  final SummaryType summaryType;

  final String primaryInsightType;
  final String? secondaryInsightType;

  /// 0–1 composite focus score (for AI to gauge strength of the signal).
  final double focusScore;

  /// 0–1 urgency score (drives tone urgency in the summary).
  final double urgencyScore;

  /// Ordered evidence trace from focus selection engine (max 5 entries).
  final List<String> evaluationTrace;

  /// Key behavioral pattern codes supporting this focus (max 3).
  final List<String> keyPatternCodes;

  /// Flat key→value evidence metrics (max 6 entries).
  final Map<String, dynamic> topEvidence;

  final AiDeliveryContext deliveryContext;
  final int generatedAtMs;

  /// Prompt template version — must be updated when prompts change materially.
  final String promptVersion;

  void validate() {
    assert(
      focusId.trim().isNotEmpty,
      'CoachingAiPayload: focusId must not be blank',
    );
    assert(
      promptVersion.trim().isNotEmpty,
      'CoachingAiPayload: promptVersion must not be blank',
    );
  }

  Map<String, dynamic> toMap() => {
    'focusId': focusId,
    'focusReason': focusReason,
    'framing': framing.name,
    'summaryType': summaryType.name,
    'coachingStyle': coachingStyle.toStorage(),
    'primaryInsightType': primaryInsightType,
    if (secondaryInsightType != null)
      'secondaryInsightType': secondaryInsightType,
    'focusScore': focusScore.clamp(0.0, 1.0),
    'urgencyScore': urgencyScore.clamp(0.0, 1.0),
    'evaluationTrace': evaluationTrace.take(5).toList(growable: false),
    'keyPatternCodes': keyPatternCodes.take(3).toList(growable: false),
    'topEvidence': Map.fromEntries(topEvidence.entries.take(6)),
    'deliveryContext': deliveryContext.toMap(),
    'generatedAtMs': generatedAtMs,
    'promptVersion': promptVersion,
  };

  /// Assemble a [CoachingAiPayload] from a [CurrentCoachingFocus] and
  /// optional primary insight type. All framing is derived deterministically.
  factory CoachingAiPayload.fromFocus({
    required CurrentCoachingFocus focus,
    required InsightType primaryInsightType,
    required AiDeliveryContext deliveryContext,
    CoachingStyle coachingStyle = CoachingStyle.balanced,
    InsightType? secondaryInsightType,
    String promptVersion = kCoachingAiPromptVersion,
  }) {
    final framing = deriveCoachingFraming(
      focusReason: focus.focusReason,
      focusScore: focus.focusScore,
      urgencyScore: focus.scoreBreakdown.urgencyScore,
      coachingStyle: coachingStyle,
    );
    final summaryType = deriveSummaryType(
      framing: framing,
      primaryInsightType: primaryInsightType,
    );
    return CoachingAiPayload(
      focusId: focus.focusId,
      focusReason: focus.focusReason.name,
      framing: framing,
      summaryType: summaryType,
      coachingStyle: coachingStyle,
      primaryInsightType: primaryInsightType.name,
      secondaryInsightType: secondaryInsightType?.name,
      focusScore: focus.focusScore,
      urgencyScore: focus.scoreBreakdown.urgencyScore,
      evaluationTrace: focus.evaluationTrace,
      keyPatternCodes: focus.contextSnapshot.keyPatternCodes,
      topEvidence: focus.contextSnapshot.topEvidence,
      deliveryContext: deliveryContext,
      generatedAtMs: DateTime.now().millisecondsSinceEpoch,
      promptVersion: promptVersion,
    );
  }
}
