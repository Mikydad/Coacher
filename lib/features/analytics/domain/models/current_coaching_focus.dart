import '../../../../core/validation/model_validators.dart';

const int kCurrentCoachingFocusSchemaVersion = 1;

// ─── Focus lifecycle ──────────────────────────────────────────────────────────

enum FocusLifecycleState {
  candidate,
  active,
  reinforced,
  resolved,
  stale,
  replaced,
}

FocusLifecycleState focusLifecycleStateFromStorage(String? raw) {
  for (final v in FocusLifecycleState.values) {
    if (v.name == raw) return v;
  }
  return FocusLifecycleState.active;
}

bool isFocusLive(FocusLifecycleState state) {
  switch (state) {
    case FocusLifecycleState.candidate:
    case FocusLifecycleState.active:
    case FocusLifecycleState.reinforced:
      return true;
    case FocusLifecycleState.resolved:
    case FocusLifecycleState.stale:
    case FocusLifecycleState.replaced:
      return false;
  }
}

// ─── Focus reason ─────────────────────────────────────────────────────────────

/// Canonical, stable reason a particular focus was selected.
/// Used for AI summarization, UX explainability, and analytics.
enum FocusReason {
  imminentStreakRisk,
  highestMomentumLeverage,
  bestRecoveryOpportunity,
  overdueItemCritical,
  scheduledWindowActive,
  globalOverloadSignal,
  consistencyBreakdownAlert,
  goalDriftDetected,
  reinforcingActiveStreak,
  timingOpportunity,
}

FocusReason focusReasonFromStorage(String? raw) {
  for (final v in FocusReason.values) {
    if (v.name == raw) return v;
  }
  return FocusReason.highestMomentumLeverage;
}

// ─── Replacement reason ──────────────────────────────────────────────────────

enum FocusReplacementReason {
  scoreSurpassed,
  minDurationExpired,
  focusBecameStale,
  forcedByPolicy,
  manualOverride,
}

FocusReplacementReason focusReplacementReasonFromStorage(String? raw) {
  for (final v in FocusReplacementReason.values) {
    if (v.name == raw) return v;
  }
  return FocusReplacementReason.scoreSurpassed;
}

// ─── Score breakdown ─────────────────────────────────────────────────────────

/// Fully explainable sub-scores for a focus decision.
class FocusScoreBreakdown {
  const FocusScoreBreakdown({
    required this.urgencyScore,
    required this.momentumScore,
    required this.feasibilityScore,
    required this.riskScore,
    required this.recoveryScore,
    required this.focusScore,
  });

  final double urgencyScore;
  final double momentumScore;
  final double feasibilityScore;
  final double riskScore;
  final double recoveryScore;
  /// Weighted composite of the above sub-scores (0–1).
  final double focusScore;

  Map<String, dynamic> toMap() => {
    'urgencyScore': urgencyScore.clamp(0.0, 1.0),
    'momentumScore': momentumScore.clamp(0.0, 1.0),
    'feasibilityScore': feasibilityScore.clamp(0.0, 1.0),
    'riskScore': riskScore.clamp(0.0, 1.0),
    'recoveryScore': recoveryScore.clamp(0.0, 1.0),
    'focusScore': focusScore.clamp(0.0, 1.0),
  };

  static FocusScoreBreakdown fromMap(Map<String, dynamic> map) {
    double v(String key) =>
        ((map[key] as num?)?.toDouble() ?? 0).clamp(0.0, 1.0);
    return FocusScoreBreakdown(
      urgencyScore: v('urgencyScore'),
      momentumScore: v('momentumScore'),
      feasibilityScore: v('feasibilityScore'),
      riskScore: v('riskScore'),
      recoveryScore: v('recoveryScore'),
      focusScore: v('focusScore'),
    );
  }
}

// ─── Context snapshot ─────────────────────────────────────────────────────────

/// Durable coaching context embedded in the focus record so future recomputes,
/// history browsing, and AI summarization don't depend on live insight lookups.
class FocusContextSnapshot {
  const FocusContextSnapshot({
    required this.insightTypes,
    required this.keyPatternCodes,
    required this.topEvidence,
    required this.selectedRationale,
    required this.timingProfile,
  });

  final List<String> insightTypes;
  final List<String> keyPatternCodes;
  /// Flat key→value evidence from supporting patterns (for explainability).
  final Map<String, dynamic> topEvidence;
  /// One-sentence human-readable rationale (engineering/debug, not user-facing).
  final String selectedRationale;
  final String timingProfile;

  Map<String, dynamic> toMap() => {
    'insightTypes': insightTypes,
    'keyPatternCodes': keyPatternCodes,
    'topEvidence': topEvidence,
    'selectedRationale': selectedRationale,
    'timingProfile': timingProfile,
  };

  static FocusContextSnapshot fromMap(Map<String, dynamic> map) {
    List<String> stringList(String key) {
      final raw = map[key];
      if (raw is List) return raw.whereType<String>().toList(growable: false);
      return const <String>[];
    }

    return FocusContextSnapshot(
      insightTypes: stringList('insightTypes'),
      keyPatternCodes: stringList('keyPatternCodes'),
      topEvidence:
          (map['topEvidence'] as Map?)?.cast<String, dynamic>() ??
          const <String, dynamic>{},
      selectedRationale: map['selectedRationale'] as String? ?? '',
      timingProfile: map['timingProfile'] as String? ?? '',
    );
  }
}

// ─── Suppressed candidate ─────────────────────────────────────────────────────

class FocusSuppressedCandidate {
  const FocusSuppressedCandidate({
    required this.insightId,
    required this.insightType,
    required this.focusScore,
    required this.rejectionReason,
  });

  final String insightId;
  final String insightType;
  final double focusScore;
  final String rejectionReason;

  Map<String, dynamic> toMap() => {
    'insightId': insightId,
    'insightType': insightType,
    'focusScore': focusScore.clamp(0.0, 1.0),
    'rejectionReason': rejectionReason,
  };

  static FocusSuppressedCandidate fromMap(Map<String, dynamic> map) {
    return FocusSuppressedCandidate(
      insightId: map['insightId'] as String? ?? '',
      insightType: map['insightType'] as String? ?? '',
      focusScore:
          ((map['focusScore'] as num?)?.toDouble() ?? 0).clamp(0.0, 1.0),
      rejectionReason: map['rejectionReason'] as String? ?? '',
    );
  }
}

// ─── CurrentCoachingFocus ─────────────────────────────────────────────────────

/// The behavioral attention state for a user at a given point in time.
/// NOT just a selected insight — this represents a coaching decision with
/// full provenance, lifecycle, explainability, and durable context.
class CurrentCoachingFocus {
  const CurrentCoachingFocus({
    required this.focusId,
    required this.primaryInsightId,
    this.secondaryInsightId,
    required this.lifecycleState,
    required this.focusReason,
    required this.focusScore,
    required this.focusConfidence,
    required this.scoreBreakdown,
    required this.contextSnapshot,
    required this.evaluationTrace,
    required this.suppressedCandidates,
    required this.sourceInsightTypes,
    required this.detectedAtMs,
    required this.activeUntilMs,
    this.resolvedAtMs,
    this.replacementReason,
    this.metadata = const <String, dynamic>{},
    this.schemaVersion = kCurrentCoachingFocusSchemaVersion,
  });

  final String focusId;
  final String primaryInsightId;
  final String? secondaryInsightId;
  final FocusLifecycleState lifecycleState;
  final FocusReason focusReason;
  /// 0–1 composite focus score from the scoring engine.
  final double focusScore;
  /// 0–1 confidence in the prioritization decision itself (distinct from
  /// underlying insight confidence — evaluates "should THIS be current focus?").
  final double focusConfidence;
  final FocusScoreBreakdown scoreBreakdown;
  final FocusContextSnapshot contextSnapshot;
  /// Ordered list of human-readable trace entries explaining the decision.
  final List<String> evaluationTrace;
  final List<FocusSuppressedCandidate> suppressedCandidates;
  /// Insight types contributing to this focus (for AI summarization).
  final List<String> sourceInsightTypes;
  final int detectedAtMs;
  /// Earliest timestamp this focus can be replaced (minimum active duration).
  final int activeUntilMs;
  final int? resolvedAtMs;
  final FocusReplacementReason? replacementReason;
  final Map<String, dynamic> metadata;
  final int schemaVersion;

  void validate() {
    ModelValidators.requireNotBlank(focusId, 'currentCoachingFocus.focusId');
    ModelValidators.requireNotBlank(
      primaryInsightId,
      'currentCoachingFocus.primaryInsightId',
    );
    ModelValidators.requireRange(
      value: schemaVersion,
      min: 1,
      max: 9999,
      fieldName: 'currentCoachingFocus.schemaVersion',
    );
  }

  Map<String, dynamic> toMap() => {
    'focusId': focusId,
    'primaryInsightId': primaryInsightId,
    if (secondaryInsightId != null) 'secondaryInsightId': secondaryInsightId,
    'lifecycleState': lifecycleState.name,
    'focusReason': focusReason.name,
    'focusScore': focusScore.clamp(0.0, 1.0),
    'focusConfidence': focusConfidence.clamp(0.0, 1.0),
    'scoreBreakdown': scoreBreakdown.toMap(),
    'contextSnapshot': contextSnapshot.toMap(),
    'evaluationTrace': evaluationTrace,
    'suppressedCandidates':
        suppressedCandidates.map((c) => c.toMap()).toList(growable: false),
    'sourceInsightTypes': sourceInsightTypes,
    'detectedAtMs': detectedAtMs,
    'activeUntilMs': activeUntilMs,
    if (resolvedAtMs != null) 'resolvedAtMs': resolvedAtMs,
    if (replacementReason != null)
      'replacementReason': replacementReason!.name,
    'metadata': metadata,
    'schemaVersion': schemaVersion,
  };

  static CurrentCoachingFocus fromMap(Map<String, dynamic> map) {
    List<String> stringList(String key) {
      final raw = map[key];
      if (raw is List) return raw.whereType<String>().toList(growable: false);
      return const <String>[];
    }

    final rawSuppressed = map['suppressedCandidates'];
    final suppressed = <FocusSuppressedCandidate>[];
    if (rawSuppressed is List) {
      for (final entry in rawSuppressed) {
        if (entry is Map) {
          suppressed.add(
            FocusSuppressedCandidate.fromMap(entry.cast<String, dynamic>()),
          );
        }
      }
    }

    final rawBreakdown = map['scoreBreakdown'];
    final scoreBreakdown = rawBreakdown is Map
        ? FocusScoreBreakdown.fromMap(rawBreakdown.cast<String, dynamic>())
        : FocusScoreBreakdown(
            urgencyScore: 0,
            momentumScore: 0,
            feasibilityScore: 0,
            riskScore: 0,
            recoveryScore: 0,
            focusScore: 0,
          );

    final rawSnapshot = map['contextSnapshot'];
    final contextSnapshot = rawSnapshot is Map
        ? FocusContextSnapshot.fromMap(rawSnapshot.cast<String, dynamic>())
        : const FocusContextSnapshot(
            insightTypes: [],
            keyPatternCodes: [],
            topEvidence: {},
            selectedRationale: '',
            timingProfile: '',
          );

    final rawReplacement = map['replacementReason'] as String?;

    return CurrentCoachingFocus(
      focusId: map['focusId'] as String? ?? '',
      primaryInsightId: map['primaryInsightId'] as String? ?? '',
      secondaryInsightId: map['secondaryInsightId'] as String?,
      lifecycleState: focusLifecycleStateFromStorage(
        map['lifecycleState'] as String?,
      ),
      focusReason: focusReasonFromStorage(map['focusReason'] as String?),
      focusScore:
          ((map['focusScore'] as num?)?.toDouble() ?? 0).clamp(0.0, 1.0),
      focusConfidence:
          ((map['focusConfidence'] as num?)?.toDouble() ?? 0).clamp(0.0, 1.0),
      scoreBreakdown: scoreBreakdown,
      contextSnapshot: contextSnapshot,
      evaluationTrace: stringList('evaluationTrace'),
      suppressedCandidates: suppressed,
      sourceInsightTypes: stringList('sourceInsightTypes'),
      detectedAtMs: (map['detectedAtMs'] as num?)?.toInt() ?? 0,
      activeUntilMs: (map['activeUntilMs'] as num?)?.toInt() ?? 0,
      resolvedAtMs: (map['resolvedAtMs'] as num?)?.toInt(),
      replacementReason: rawReplacement != null
          ? focusReplacementReasonFromStorage(rawReplacement)
          : null,
      metadata:
          (map['metadata'] as Map?)?.cast<String, dynamic>() ??
          const <String, dynamic>{},
      schemaVersion:
          (map['schemaVersion'] as num?)?.toInt() ??
          kCurrentCoachingFocusSchemaVersion,
    );
  }
}
