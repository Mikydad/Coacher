import '../domain/models/current_coaching_focus.dart';
import 'focus_candidate.dart';
import 'focus_scoring_engine.dart';
import 'layer4_delivery_policy.dart';

// ─── Selector policy ──────────────────────────────────────────────────────────

class FocusSelectorPolicy {
  const FocusSelectorPolicy({
    this.minActiveDurationMs = const Duration(hours: 2),
    this.replacementScoreDeltaThreshold = 0.15,
    this.minFocusScoreToActivate = 0.20,
    this.maxSuppressedCandidatesLogged = 5,
    this.maxHistoryEntries = 150,
  });

  /// Minimum duration before an active focus can be replaced.
  final Duration minActiveDurationMs;

  /// A new candidate must exceed the active focus score by at least this delta
  /// before replacement is allowed (anti-thrash guard).
  final double replacementScoreDeltaThreshold;

  /// Focus candidates below this score are not considered.
  final double minFocusScoreToActivate;

  /// How many suppressed candidates to embed in the record for debug.
  final int maxSuppressedCandidatesLogged;

  /// Maximum focus history entries kept per scope.
  final int maxHistoryEntries;
}

const kFocusSelectorPolicy = FocusSelectorPolicy();

// ─── Selector input ───────────────────────────────────────────────────────────

class FocusScoredCandidate {
  const FocusScoredCandidate({
    required this.candidate,
    required this.breakdown,
  });

  final FocusCandidate candidate;
  final FocusScoreBreakdown breakdown;
}

// ─── Selector result ──────────────────────────────────────────────────────────

class FocusSelectionResult {
  const FocusSelectionResult({
    required this.focus,
    required this.antiThrashApplied,
    required this.candidatesEvaluated,
  });

  final CurrentCoachingFocus focus;
  final bool antiThrashApplied;
  final int candidatesEvaluated;
}

// ─── Selector ────────────────────────────────────────────────────────────────

String _focusId({
  required String primaryInsightId,
  required int detectedAtMs,
}) => 'focus::$primaryInsightId::$detectedAtMs';

FocusSelectionResult selectFocus({
  required List<FocusCandidate> candidates,
  CurrentCoachingFocus? existingFocus,
  DateTime? now,
  FocusSelectorPolicy policy = kFocusSelectorPolicy,
  FocusScoringWeights scoringWeights = kFocusScoringWeights,
}) {
  final ts = now ?? DateTime.now();
  final nowMs = ts.millisecondsSinceEpoch;

  // Score all candidates.
  final scored =
      candidates
          .map(
            (c) => FocusScoredCandidate(
              candidate: c,
              breakdown: computeFocusScoreBreakdown(c, weights: scoringWeights),
            ),
          )
          .where(
            (s) => s.breakdown.focusScore >= policy.minFocusScoreToActivate,
          )
          .toList()
        ..sort(
          (a, b) => b.breakdown.focusScore.compareTo(a.breakdown.focusScore),
        );

  // If nothing passes the threshold, emit a stale/empty continuation.
  if (scored.isEmpty) {
    final stale = existingFocus != null
        ? _transitionToStale(existingFocus, nowMs: nowMs)
        : _emptyFocus(nowMs: nowMs, policy: policy);
    return FocusSelectionResult(
      focus: stale,
      antiThrashApplied: false,
      candidatesEvaluated: candidates.length,
    );
  }

  final top = scored.first;
  final secondary = scored.length > 1 ? scored[1] : null;
  final allBreakdowns = scored.map((s) => s.breakdown).toList();

  // Anti-thrash: check if existing active focus should be retained.
  final antiThrash = _shouldRetainExistingFocus(
    existing: existingFocus,
    topScore: top.breakdown.focusScore,
    nowMs: nowMs,
    policy: policy,
  );

  final FocusScoredCandidate primary;
  final bool antiThrashApplied;
  if (antiThrash && existingFocus != null) {
    // Find the candidate matching the existing primary, or keep top.
    final existing = scored.firstWhere(
      (s) => s.candidate.insight.insightId == existingFocus.primaryInsightId,
      orElse: () => top,
    );
    primary = existing;
    antiThrashApplied = true;
  } else {
    primary = top;
    antiThrashApplied = false;
  }

  final reason = deriveFocusReason(primary.candidate);
  final focusConfidence = computeFocusConfidence(
    topBreakdown: primary.breakdown,
    allBreakdowns: allBreakdowns,
  );
  final trace = buildEvaluationTrace(
    candidate: primary.candidate,
    breakdown: primary.breakdown,
    reason: reason,
    wasAntiThrashApplied: antiThrashApplied,
    candidateCount: scored.length,
  );
  final contextSnapshot = _buildContextSnapshot(
    primary: primary,
    timingProfile: primary.candidate.realtimeContext.timingProfile,
  );
  final suppressed = _buildSuppressedList(
    all: scored,
    primaryInsightId: primary.candidate.insight.insightId,
    policy: policy,
  );

  // Determine lifecycle: reinforce if same focus was already active.
  final lifecycle = _resolveLifecycle(
    existing: existingFocus,
    primaryInsightId: primary.candidate.insight.insightId,
    antiThrashApplied: antiThrashApplied,
  );

  final activeUntilMs = nowMs + policy.minActiveDurationMs.inMilliseconds;

  // Replacement reason: only set when we're replacing an existing active focus.
  FocusReplacementReason? replacementReason;
  if (existingFocus != null &&
      !antiThrashApplied &&
      isFocusLive(existingFocus.lifecycleState) &&
      existingFocus.primaryInsightId != primary.candidate.insight.insightId) {
    replacementReason = nowMs >= existingFocus.activeUntilMs
        ? FocusReplacementReason.scoreSurpassed
        : FocusReplacementReason.scoreSurpassed;
  }

  final focus = CurrentCoachingFocus(
    focusId: _focusId(
      primaryInsightId: primary.candidate.insight.insightId,
      detectedAtMs: nowMs,
    ),
    primaryInsightId: primary.candidate.insight.insightId,
    secondaryInsightId: secondary?.candidate.insight.insightId,
    lifecycleState: lifecycle,
    focusReason: reason,
    focusScore: primary.breakdown.focusScore,
    focusConfidence: focusConfidence,
    scoreBreakdown: primary.breakdown,
    contextSnapshot: contextSnapshot,
    evaluationTrace: trace,
    suppressedCandidates: suppressed,
    sourceInsightTypes: scored
        .take(3)
        .map((s) => s.candidate.insight.insightType.name)
        .toList(growable: false),
    detectedAtMs: nowMs,
    activeUntilMs: antiThrashApplied
        ? (existingFocus?.activeUntilMs ?? activeUntilMs)
        : activeUntilMs,
    replacementReason: replacementReason,
  );

  return FocusSelectionResult(
    focus: focus,
    antiThrashApplied: antiThrashApplied,
    candidatesEvaluated: candidates.length,
  );
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

bool _shouldRetainExistingFocus({
  required CurrentCoachingFocus? existing,
  required double topScore,
  required int nowMs,
  required FocusSelectorPolicy policy,
}) {
  if (existing == null) return false;
  if (!isFocusLive(existing.lifecycleState)) return false;
  // Within minimum active duration: always retain.
  if (nowMs < existing.activeUntilMs) return true;
  // After min duration: only replace if score delta exceeds threshold.
  final delta = topScore - existing.focusScore;
  return delta < policy.replacementScoreDeltaThreshold;
}

FocusLifecycleState _resolveLifecycle({
  required CurrentCoachingFocus? existing,
  required String primaryInsightId,
  required bool antiThrashApplied,
}) {
  if (existing == null) return FocusLifecycleState.active;
  if (existing.primaryInsightId == primaryInsightId) {
    // Same focus persists — upgrade to reinforced if already active.
    return existing.lifecycleState == FocusLifecycleState.active
        ? FocusLifecycleState.reinforced
        : existing.lifecycleState == FocusLifecycleState.reinforced
        ? FocusLifecycleState.reinforced
        : FocusLifecycleState.active;
  }
  return FocusLifecycleState.active;
}

FocusContextSnapshot _buildContextSnapshot({
  required FocusScoredCandidate primary,
  required DeliveryTimingProfile timingProfile,
}) {
  final insight = primary.candidate.insight;
  final patterns = primary.candidate.supportingPatterns;
  final topEvidence = Map<String, dynamic>.from(insight.supportingMetrics);

  for (final p in patterns.take(3)) {
    topEvidence['pattern.${p.patternCode.name}.severity'] = p.severity;
    topEvidence['pattern.${p.patternCode.name}.confidence'] = p.confidence;
  }

  return FocusContextSnapshot(
    insightTypes: [insight.insightType.name],
    keyPatternCodes: patterns
        .map((p) => p.patternCode.name)
        .toSet()
        .toList(growable: false),
    topEvidence: topEvidence,
    selectedRationale:
        '${insight.insightType.name}: '
        '${insight.message.isNotEmpty ? insight.message : insight.messageKey}',
    timingProfile: timingProfile.name,
  );
}

List<FocusSuppressedCandidate> _buildSuppressedList({
  required List<FocusScoredCandidate> all,
  required String primaryInsightId,
  required FocusSelectorPolicy policy,
}) {
  return all
      .where((s) => s.candidate.insight.insightId != primaryInsightId)
      .take(policy.maxSuppressedCandidatesLogged)
      .map(
        (s) => FocusSuppressedCandidate(
          insightId: s.candidate.insight.insightId,
          insightType: s.candidate.insight.insightType.name,
          focusScore: s.breakdown.focusScore,
          rejectionReason: 'lower_focus_score',
        ),
      )
      .toList(growable: false);
}

CurrentCoachingFocus _transitionToStale(
  CurrentCoachingFocus existing, {
  required int nowMs,
}) {
  return CurrentCoachingFocus(
    focusId: existing.focusId,
    primaryInsightId: existing.primaryInsightId,
    secondaryInsightId: existing.secondaryInsightId,
    lifecycleState: FocusLifecycleState.stale,
    focusReason: existing.focusReason,
    focusScore: existing.focusScore,
    focusConfidence: existing.focusConfidence,
    scoreBreakdown: existing.scoreBreakdown,
    contextSnapshot: existing.contextSnapshot,
    evaluationTrace: [
      ...existing.evaluationTrace,
      'Transitioned to stale: no eligible candidates at $nowMs',
    ],
    suppressedCandidates: existing.suppressedCandidates,
    sourceInsightTypes: existing.sourceInsightTypes,
    detectedAtMs: existing.detectedAtMs,
    activeUntilMs: existing.activeUntilMs,
    resolvedAtMs: nowMs,
    replacementReason: FocusReplacementReason.focusBecameStale,
    metadata: existing.metadata,
    schemaVersion: existing.schemaVersion,
  );
}

CurrentCoachingFocus _emptyFocus({
  required int nowMs,
  required FocusSelectorPolicy policy,
}) {
  return CurrentCoachingFocus(
    focusId: 'focus::empty::$nowMs',
    primaryInsightId: '',
    lifecycleState: FocusLifecycleState.stale,
    focusReason: FocusReason.highestMomentumLeverage,
    focusScore: 0.0,
    focusConfidence: 0.0,
    scoreBreakdown: const FocusScoreBreakdown(
      urgencyScore: 0,
      momentumScore: 0,
      feasibilityScore: 0,
      riskScore: 0,
      recoveryScore: 0,
      focusScore: 0,
    ),
    contextSnapshot: const FocusContextSnapshot(
      insightTypes: [],
      keyPatternCodes: [],
      topEvidence: {},
      selectedRationale: 'No eligible candidates',
      timingProfile: '',
    ),
    evaluationTrace: ['No candidates met minimum focus score threshold'],
    suppressedCandidates: const [],
    sourceInsightTypes: const [],
    detectedAtMs: nowMs,
    activeUntilMs: nowMs,
  );
}
