import 'coaching_ai_payload.dart';
import 'current_coaching_focus.dart';

const int kAiSummaryResponseSchemaVersion = 1;

// ─── Tone ─────────────────────────────────────────────────────────────────────

/// Tone of the AI-generated coaching message.
/// Derived from framing — the AI declares the tone it applied, which is
/// cross-checked against the expected tone for lightweight validation.
enum CoachingTone {
  /// Motivational, energetic — used with momentum framing.
  encouraging,

  /// Calm, factual — used with consistency/stabilization framing.
  informative,

  /// Direct, slightly urgent — used with protection framing.
  assertive,

  /// Warm, empathetic — used with recovery framing.
  supportive,
}

CoachingTone coachingToneFromStorage(String? raw) {
  for (final v in CoachingTone.values) {
    if (v.name == raw) return v;
  }
  return CoachingTone.informative;
}

/// Expected tone for a given [CoachingFraming].
/// Used during semantic validation to catch framing drift.
CoachingTone expectedToneForFraming(CoachingFraming framing) {
  switch (framing) {
    case CoachingFraming.momentum:
      return CoachingTone.encouraging;
    case CoachingFraming.recovery:
      return CoachingTone.supportive;
    case CoachingFraming.protection:
      return CoachingTone.assertive;
    case CoachingFraming.stabilization:
    case CoachingFraming.consistency:
      return CoachingTone.informative;
  }
}

// ─── Validation result ────────────────────────────────────────────────────────

/// Outcome of lightweight semantic validation on an [AiSummaryResponse].
enum AiSummaryValidationOutcome {
  /// Response passed all checks.
  passed,

  /// Response contradicts the focus reason (e.g. "rest day" for streak risk).
  contradictsFocus,

  /// Tone declared by AI does not match the expected tone for the framing.
  toneMismatch,

  /// Summary or recommendation is excessively long.
  tooLong,

  /// Summary text is too vague / below the minimum useful length.
  tooVague,

  /// JSON decoded correctly but a required field is blank.
  missingRequiredField,
}

class AiSummaryValidationResult {
  const AiSummaryValidationResult({
    required this.outcome,
    this.detail = '',
  });

  final AiSummaryValidationOutcome outcome;
  final String detail;

  bool get passed => outcome == AiSummaryValidationOutcome.passed;

  @override
  String toString() =>
      passed ? 'passed' : '${outcome.name}: $detail';
}

// ─── AI summary response ──────────────────────────────────────────────────────

/// Structured coaching summary returned by the AI client.
///
/// All fields are strict — the client must validate JSON shape and populate
/// every required field, falling back to [AiSummaryResponse.empty] on failure.
class AiSummaryResponse {
  const AiSummaryResponse({
    required this.focusId,
    required this.summaryType,
    required this.tone,
    required this.dailySummary,
    required this.mainRecommendation,
    required this.framing,
    required this.generatedAtMs,
    required this.promptVersion,
    this.secondaryNote,
    this.validationOutcome = AiSummaryValidationOutcome.passed,
    this.isFallback = false,
    this.schemaVersion = kAiSummaryResponseSchemaVersion,
    this.metadata = const <String, dynamic>{},
  });

  /// Matches [CoachingAiPayload.focusId] to bind the summary to its focus.
  final String focusId;
  final SummaryType summaryType;
  final CoachingTone tone;

  /// Main coaching narrative (max ~80 words).
  final String dailySummary;

  /// Concrete, single-action recommendation (max ~40 words).
  final String mainRecommendation;

  /// The framing the AI applied — cross-checked during validation.
  final CoachingFraming framing;

  final int generatedAtMs;

  /// Prompt version used to generate this response — enables regression tracking.
  final String promptVersion;

  /// Optional secondary note (e.g. acknowledgment of secondary insight).
  final String? secondaryNote;

  /// Validation outcome assigned after semantic checks. [passed] means safe to show.
  final AiSummaryValidationOutcome validationOutcome;

  /// True when this response was produced by [DeterministicCoachingRenderer].
  final bool isFallback;

  final int schemaVersion;
  final Map<String, dynamic> metadata;

  bool get isValid => validationOutcome == AiSummaryValidationOutcome.passed;

  /// Returns a copy with [validationOutcome] overridden — used by the validator.
  AiSummaryResponse withValidationOutcome(AiSummaryValidationOutcome outcome) {
    return AiSummaryResponse(
      focusId: focusId,
      summaryType: summaryType,
      tone: tone,
      dailySummary: dailySummary,
      mainRecommendation: mainRecommendation,
      framing: framing,
      generatedAtMs: generatedAtMs,
      promptVersion: promptVersion,
      secondaryNote: secondaryNote,
      validationOutcome: outcome,
      isFallback: isFallback,
      schemaVersion: schemaVersion,
      metadata: metadata,
    );
  }

  Map<String, dynamic> toMap() => {
    'focusId': focusId,
    'summaryType': summaryType.name,
    'tone': tone.name,
    'dailySummary': dailySummary,
    'mainRecommendation': mainRecommendation,
    'framing': framing.name,
    'generatedAtMs': generatedAtMs,
    'promptVersion': promptVersion,
    if (secondaryNote != null) 'secondaryNote': secondaryNote,
    'validationOutcome': validationOutcome.name,
    'isFallback': isFallback,
    'schemaVersion': schemaVersion,
    'metadata': metadata,
  };

  static AiSummaryResponse fromMap(Map<String, dynamic> map) {
    return AiSummaryResponse(
      focusId: map['focusId'] as String? ?? '',
      summaryType: summaryTypeFromStorage(map['summaryType'] as String?),
      tone: coachingToneFromStorage(map['tone'] as String?),
      dailySummary: map['dailySummary'] as String? ?? '',
      mainRecommendation: map['mainRecommendation'] as String? ?? '',
      framing: coachingFramingFromStorage(map['framing'] as String?),
      generatedAtMs: (map['generatedAtMs'] as num?)?.toInt() ?? 0,
      promptVersion: map['promptVersion'] as String? ?? '',
      secondaryNote: map['secondaryNote'] as String?,
      validationOutcome: _outcomeFromStorage(map['validationOutcome'] as String?),
      isFallback: map['isFallback'] as bool? ?? false,
      schemaVersion:
          (map['schemaVersion'] as num?)?.toInt() ?? kAiSummaryResponseSchemaVersion,
      metadata:
          (map['metadata'] as Map?)?.cast<String, dynamic>() ??
          const <String, dynamic>{},
    );
  }

  /// Empty fallback — used when no valid response is available yet.
  static const AiSummaryResponse empty = AiSummaryResponse(
    focusId: '',
    summaryType: SummaryType.daily,
    tone: CoachingTone.informative,
    dailySummary: '',
    mainRecommendation: '',
    framing: CoachingFraming.consistency,
    generatedAtMs: 0,
    promptVersion: '',
    isFallback: true,
  );
}

AiSummaryValidationOutcome _outcomeFromStorage(String? raw) {
  for (final v in AiSummaryValidationOutcome.values) {
    if (v.name == raw) return v;
  }
  return AiSummaryValidationOutcome.passed;
}
