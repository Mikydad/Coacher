import 'package:sidepal/features/analytics/application/focus_candidate.dart';
import 'package:sidepal/features/analytics/application/focus_scoring_engine.dart';
import 'package:sidepal/features/analytics/application/focus_selector.dart';
import 'package:sidepal/features/analytics/domain/models/behavior_feature_object.dart';
import 'package:sidepal/features/analytics/domain/models/current_coaching_focus.dart';
import 'package:sidepal/features/analytics/domain/models/detected_behavior_pattern.dart';
import 'package:sidepal/features/analytics/domain/models/detected_pattern.dart';
import 'package:sidepal/features/analytics/domain/models/generated_insight.dart';
import 'package:sidepal/features/analytics/domain/models/pattern_taxonomy.dart';
import 'package:sidepal/features/analytics/application/layer4_delivery_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FocusLifecycleState', () {
    test('isFocusLive returns true for live states', () {
      expect(isFocusLive(FocusLifecycleState.candidate), isTrue);
      expect(isFocusLive(FocusLifecycleState.active), isTrue);
      expect(isFocusLive(FocusLifecycleState.reinforced), isTrue);
    });

    test('isFocusLive returns false for terminal states', () {
      expect(isFocusLive(FocusLifecycleState.resolved), isFalse);
      expect(isFocusLive(FocusLifecycleState.stale), isFalse);
      expect(isFocusLive(FocusLifecycleState.replaced), isFalse);
    });

    test('roundtrips all states through storage', () {
      for (final state in FocusLifecycleState.values) {
        expect(focusLifecycleStateFromStorage(state.name), equals(state));
      }
      expect(
        focusLifecycleStateFromStorage(null),
        equals(FocusLifecycleState.active),
      );
    });
  });

  group('FocusReason', () {
    test('roundtrips all values through storage', () {
      for (final reason in FocusReason.values) {
        expect(focusReasonFromStorage(reason.name), equals(reason));
      }
    });
  });

  group('CurrentCoachingFocus model', () {
    test('toMap / fromMap round-trip preserves all fields', () {
      final original = _makeFocus(
        primaryInsightId: 'entity::e1::streakRiskWarning::2026-05-07',
        lifecycleState: FocusLifecycleState.reinforced,
        reason: FocusReason.imminentStreakRisk,
        focusScore: 0.82,
        focusConfidence: 0.74,
      );

      final restored = CurrentCoachingFocus.fromMap(original.toMap());

      expect(restored.focusId, equals(original.focusId));
      expect(restored.primaryInsightId, equals(original.primaryInsightId));
      expect(restored.lifecycleState, equals(original.lifecycleState));
      expect(restored.focusReason, equals(original.focusReason));
      expect(restored.focusScore, closeTo(original.focusScore, 0.001));
      expect(restored.focusConfidence, closeTo(original.focusConfidence, 0.001));
      expect(
        restored.scoreBreakdown.urgencyScore,
        closeTo(original.scoreBreakdown.urgencyScore, 0.001),
      );
      expect(
        restored.contextSnapshot.timingProfile,
        equals(original.contextSnapshot.timingProfile),
      );
      expect(restored.evaluationTrace, equals(original.evaluationTrace));
      expect(
        restored.suppressedCandidates.length,
        equals(original.suppressedCandidates.length),
      );
    });

    test('validate throws for empty focusId', () {
      final bad = _makeFocus(primaryInsightId: 'x').copyWith(focusId: '');
      expect(() => bad.validate(), throwsArgumentError);
    });
  });

  group('FocusScoringEngine — determinism', () {
    test('same candidate always produces same scores', () {
      final candidate = _candidate(
        insightType: InsightType.streakRiskWarning,
        bucket: InsightBucket.risk,
        priority: InsightPriority.high,
        confidence: 0.9,
        urgency: 0.85,
        coachingImportance: 0.9,
        patterns: [_pattern(PatternCode.streakRisk, severity: 0.8)],
      );

      final b1 = computeFocusScoreBreakdown(candidate);
      final b2 = computeFocusScoreBreakdown(candidate);

      expect(b1.focusScore, closeTo(b2.focusScore, 0.0001));
      expect(b1.urgencyScore, closeTo(b2.urgencyScore, 0.0001));
      expect(b1.momentumScore, closeTo(b2.momentumScore, 0.0001));
      expect(b1.feasibilityScore, closeTo(b2.feasibilityScore, 0.0001));
      expect(b1.riskScore, closeTo(b2.riskScore, 0.0001));
      expect(b1.recoveryScore, closeTo(b2.recoveryScore, 0.0001));
    });

    test('high-priority risk insight scores higher than low-priority reinforcement', () {
      final highRisk = _candidate(
        insightType: InsightType.streakRiskWarning,
        bucket: InsightBucket.risk,
        priority: InsightPriority.high,
        confidence: 0.9,
        urgency: 0.85,
        coachingImportance: 0.9,
        patterns: [_pattern(PatternCode.streakRisk, severity: 0.9)],
      );

      final lowReinforcement = _candidate(
        insightType: InsightType.strongStreakPraise,
        bucket: InsightBucket.reinforcement,
        priority: InsightPriority.low,
        confidence: 0.6,
        urgency: 0.2,
        coachingImportance: 0.2,
        patterns: [_pattern(PatternCode.strongStreak, severity: 0.5)],
      );

      final highScore = computeFocusScoreBreakdown(highRisk).focusScore;
      final lowScore = computeFocusScoreBreakdown(lowReinforcement).focusScore;
      expect(highScore, greaterThan(lowScore));
    });

    test('in-focus-session suppresses urgency + feasibility', () {
      final normal = _candidate(
        insightType: InsightType.streakRiskWarning,
        bucket: InsightBucket.risk,
        priority: InsightPriority.high,
        confidence: 0.9,
        urgency: 0.9,
        coachingImportance: 0.9,
        patterns: [],
      );
      final inSession = FocusCandidate(
        insight: normal.insight,
        supportingPatterns: normal.supportingPatterns,
        realtimeContext: const FocusRealtimeContext(
          timingProfile: DeliveryTimingProfile.afternoon,
          isInFocusSession: true,
        ),
      );

      final normalScore = computeFocusScoreBreakdown(normal);
      final sessionScore = computeFocusScoreBreakdown(inSession);

      expect(sessionScore.urgencyScore, lessThan(normalScore.urgencyScore));
      expect(sessionScore.feasibilityScore, lessThan(normalScore.feasibilityScore));
    });

    test('overdue items increase urgency score', () {
      final noOverdue = _candidate(
        insightType: InsightType.streakRiskWarning,
        bucket: InsightBucket.risk,
        priority: InsightPriority.high,
        confidence: 0.8,
        urgency: 0.7,
        coachingImportance: 0.8,
        patterns: [],
      );
      final withOverdue = FocusCandidate(
        insight: noOverdue.insight,
        supportingPatterns: noOverdue.supportingPatterns,
        realtimeContext: const FocusRealtimeContext(
          timingProfile: DeliveryTimingProfile.morning,
          overdueCount: 3,
          highestOverdueSeverity: 0.9,
        ),
      );

      expect(
        computeFocusScoreBreakdown(withOverdue).urgencyScore,
        greaterThan(computeFocusScoreBreakdown(noOverdue).urgencyScore),
      );
    });
  });

  group('FocusSelector — selection', () {
    test('same candidates always produce same focus selection', () {
      final candidates = _multipleCandidates();
      final now = DateTime(2026, 5, 7, 10);

      final r1 = selectFocus(candidates: candidates, now: now);
      final r2 = selectFocus(candidates: candidates, now: now);

      expect(r1.focus.primaryInsightId, equals(r2.focus.primaryInsightId));
      expect(r1.focus.focusScore, closeTo(r2.focus.focusScore, 0.0001));
      expect(r1.focus.evaluationTrace, equals(r2.focus.evaluationTrace));
    });

    test('highest scoring candidate is selected as primary', () {
      final highRisk = _candidate(
        insightType: InsightType.streakRiskWarning,
        bucket: InsightBucket.risk,
        priority: InsightPriority.high,
        confidence: 0.9,
        urgency: 0.9,
        coachingImportance: 0.9,
        patterns: [_pattern(PatternCode.streakRisk, severity: 0.9)],
        insightId: 'high-risk-insight',
      );
      final lowReinforcement = _candidate(
        insightType: InsightType.strongStreakPraise,
        bucket: InsightBucket.reinforcement,
        priority: InsightPriority.low,
        confidence: 0.5,
        urgency: 0.2,
        coachingImportance: 0.2,
        patterns: [],
        insightId: 'low-reinforcement-insight',
      );

      final result = selectFocus(
        candidates: [highRisk, lowReinforcement],
        now: DateTime(2026, 5, 7, 10),
      );

      expect(result.focus.primaryInsightId, equals('high-risk-insight'));
    });

    test('anti-thrash: active focus retained within minActiveDuration', () {
      final existing = _makeFocus(
        primaryInsightId: 'existing-insight',
        lifecycleState: FocusLifecycleState.active,
        focusScore: 0.75,
        detectedAtMs: DateTime(2026, 5, 7, 9).millisecondsSinceEpoch,
        activeUntilMs: DateTime(2026, 5, 7, 11).millisecondsSinceEpoch,
      );

      // Competing candidate with higher score but still within min duration.
      final newCandidate = _candidate(
        insightType: InsightType.fragileStreakAlert,
        bucket: InsightBucket.risk,
        priority: InsightPriority.high,
        confidence: 0.95,
        urgency: 0.95,
        coachingImportance: 0.95,
        patterns: [_pattern(PatternCode.streakRisk, severity: 0.95)],
        insightId: 'new-competing-insight',
      );

      final now = DateTime(2026, 5, 7, 9, 30); // 30min in — still in min window
      final result = selectFocus(
        candidates: [newCandidate],
        existingFocus: existing,
        now: now,
      );

      // Should retain existing because we're within the 2h min duration.
      expect(result.antiThrashApplied, isTrue);
    });

    test('replacement allowed after minActiveDuration + score delta exceeds threshold', () {
      final existing = _makeFocus(
        primaryInsightId: 'old-insight',
        lifecycleState: FocusLifecycleState.active,
        focusScore: 0.50,
        detectedAtMs: DateTime(2026, 5, 7, 7).millisecondsSinceEpoch,
        activeUntilMs: DateTime(2026, 5, 7, 9).millisecondsSinceEpoch,
      );

      // Strong new candidate with score well above threshold.
      final newCandidate = _candidate(
        insightType: InsightType.streakRiskWarning,
        bucket: InsightBucket.risk,
        priority: InsightPriority.high,
        confidence: 0.95,
        urgency: 0.95,
        coachingImportance: 0.95,
        patterns: [_pattern(PatternCode.streakRisk, severity: 0.95)],
        insightId: 'new-dominant-insight',
      );

      final now = DateTime(2026, 5, 7, 10); // After min duration.
      final result = selectFocus(
        candidates: [newCandidate],
        existingFocus: existing,
        now: now,
      );

      expect(result.antiThrashApplied, isFalse);
      expect(result.focus.primaryInsightId, equals('new-dominant-insight'));
    });

    test('same focus gains reinforced lifecycle on second selection', () {
      final now = DateTime(2026, 5, 7, 10);
      final candidate = _candidate(
        insightType: InsightType.streakRiskWarning,
        bucket: InsightBucket.risk,
        priority: InsightPriority.high,
        confidence: 0.9,
        urgency: 0.9,
        coachingImportance: 0.9,
        patterns: [_pattern(PatternCode.streakRisk, severity: 0.9)],
        insightId: 'persistent-insight',
      );

      // First selection.
      final r1 = selectFocus(candidates: [candidate], now: now);
      expect(r1.focus.lifecycleState, equals(FocusLifecycleState.active));

      // Second selection with same candidate and existing focus.
      final r2 = selectFocus(
        candidates: [candidate],
        existingFocus: r1.focus,
        now: now.add(const Duration(hours: 3)),
      );
      expect(r2.focus.lifecycleState, equals(FocusLifecycleState.reinforced));
    });

    test('stale focus emitted when no candidates pass threshold', () {
      final existing = _makeFocus(
        primaryInsightId: 'previous-insight',
        lifecycleState: FocusLifecycleState.active,
        focusScore: 0.6,
      );

      // Very low score candidate that won't pass minFocusScoreToActivate.
      final weakCandidate = _candidate(
        insightType: InsightType.strongStreakPraise,
        bucket: InsightBucket.reinforcement,
        priority: InsightPriority.low,
        confidence: 0.1,
        urgency: 0.0,
        coachingImportance: 0.05,
        patterns: [],
        insightId: 'weak-insight',
      );

      final result = selectFocus(
        candidates: [weakCandidate],
        existingFocus: existing,
        now: DateTime(2026, 5, 7, 10),
        policy: const FocusSelectorPolicy(minFocusScoreToActivate: 0.99),
      );

      expect(result.focus.lifecycleState, equals(FocusLifecycleState.stale));
    });

    test('suppressed candidates are captured with rejection reason', () {
      final candidates = _multipleCandidates();
      final result = selectFocus(
        candidates: candidates,
        now: DateTime(2026, 5, 7, 10),
      );

      // Should have at least some suppressed candidates if multiple were evaluated.
      if (candidates.length > 1) {
        expect(result.focus.suppressedCandidates, isNotEmpty);
        expect(
          result.focus.suppressedCandidates.every(
            (c) => c.rejectionReason.isNotEmpty,
          ),
          isTrue,
        );
      }
    });

    test('focus confidence is higher when top candidate dominates', () {
      final dominant = _candidate(
        insightType: InsightType.streakRiskWarning,
        bucket: InsightBucket.risk,
        priority: InsightPriority.high,
        confidence: 0.99,
        urgency: 0.99,
        coachingImportance: 0.99,
        patterns: [_pattern(PatternCode.streakRisk, severity: 0.99)],
        insightId: 'dominant',
      );
      final weak = _candidate(
        insightType: InsightType.strongStreakPraise,
        bucket: InsightBucket.reinforcement,
        priority: InsightPriority.low,
        confidence: 0.2,
        urgency: 0.1,
        coachingImportance: 0.1,
        patterns: [],
        insightId: 'weak',
      );
      final tied1 = _candidate(
        insightType: InsightType.streakRiskWarning,
        bucket: InsightBucket.risk,
        priority: InsightPriority.high,
        confidence: 0.85,
        urgency: 0.85,
        coachingImportance: 0.85,
        patterns: [_pattern(PatternCode.streakRisk, severity: 0.85)],
        insightId: 'tied1',
      );
      final tied2 = _candidate(
        insightType: InsightType.fragileStreakAlert,
        bucket: InsightBucket.risk,
        priority: InsightPriority.high,
        confidence: 0.84,
        urgency: 0.84,
        coachingImportance: 0.84,
        patterns: [_pattern(PatternCode.streakRisk, severity: 0.84)],
        insightId: 'tied2',
      );

      final dominant_result = selectFocus(
        candidates: [dominant, weak],
        now: DateTime(2026, 5, 7, 10),
      );
      final tied_result = selectFocus(
        candidates: [tied1, tied2],
        now: DateTime(2026, 5, 7, 10),
      );

      // Dominant scenario: margin is large → higher confidence.
      expect(
        dominant_result.focus.focusConfidence,
        greaterThan(tied_result.focus.focusConfidence),
      );
    });

    test('evaluation trace is non-empty and contains selection details', () {
      final result = selectFocus(
        candidates: _multipleCandidates(),
        now: DateTime(2026, 5, 7, 10),
      );

      expect(result.focus.evaluationTrace, isNotEmpty);
      final traceText = result.focus.evaluationTrace.join(' ');
      expect(traceText, contains('Score:'));
      expect(traceText, contains('Timing:'));
    });

    test('activeUntilMs is set to at least 2 hours in the future', () {
      final now = DateTime(2026, 5, 7, 10);
      final result = selectFocus(
        candidates: _multipleCandidates(),
        now: now,
      );

      final minExpected =
          now.add(const Duration(hours: 2)).millisecondsSinceEpoch;
      expect(result.focus.activeUntilMs, greaterThanOrEqualTo(minExpected));
    });
  });

  group('FocusScoreBreakdown serialization', () {
    test('toMap / fromMap roundtrips', () {
      const b = FocusScoreBreakdown(
        urgencyScore: 0.8,
        momentumScore: 0.6,
        feasibilityScore: 0.5,
        riskScore: 0.9,
        recoveryScore: 0.3,
        focusScore: 0.72,
      );
      final restored = FocusScoreBreakdown.fromMap(b.toMap());
      expect(restored.urgencyScore, closeTo(b.urgencyScore, 0.001));
      expect(restored.focusScore, closeTo(b.focusScore, 0.001));
    });
  });

  group('FocusContextSnapshot serialization', () {
    test('toMap / fromMap roundtrips', () {
      const snap = FocusContextSnapshot(
        insightTypes: ['streakRiskWarning'],
        keyPatternCodes: ['streakRisk'],
        topEvidence: {'streakRisk.severity': 0.9},
        selectedRationale: 'test rationale',
        timingProfile: 'morning',
      );
      final restored = FocusContextSnapshot.fromMap(snap.toMap());
      expect(restored.insightTypes, equals(snap.insightTypes));
      expect(restored.keyPatternCodes, equals(snap.keyPatternCodes));
      expect(
        restored.topEvidence['streakRisk.severity'],
        closeTo(0.9, 0.001),
      );
      expect(restored.selectedRationale, equals(snap.selectedRationale));
    });
  });
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

FocusCandidate _candidate({
  required InsightType insightType,
  required InsightBucket bucket,
  required InsightPriority priority,
  required double confidence,
  required double urgency,
  required double coachingImportance,
  required List<DetectedBehaviorPattern> patterns,
  String insightId = 'test-insight',
  FocusRealtimeContext ctx = FocusRealtimeContext.empty,
}) {
  final insight = GeneratedInsight(
    insightId: insightId,
    scopeType: InsightScopeType.entity,
    scopeId: 'e1',
    insightType: insightType,
    insightBucket: bucket,
    priority: priority,
    messageKey: 'key',
    message: 'msg',
    action: InsightAction.doNow,
    linkedPatternCodes: patterns.map((p) => p.patternCode.name).toList(),
    confidence: confidence,
    detectedAtMs: 1000,
    sourceWindowStartDateKey: '2026-05-01',
    sourceWindowEndDateKey: '2026-05-07',
    urgency: urgency,
    coachingImportance: coachingImportance,
  );
  return FocusCandidate(
    insight: insight,
    supportingPatterns: patterns,
    realtimeContext: ctx,
  );
}

DetectedBehaviorPattern _pattern(PatternCode code, {double severity = 0.8}) {
  return DetectedBehaviorPattern(
    entityId: 'e1',
    entityKind: BehaviorEntityKind.task,
    patternCode: code,
    patternGroup: PatternGroup.streakConsistency,
    taxonomyFamily: patternTaxonomyFamilyForGroup(PatternGroup.streakConsistency),
    severity: severity,
    confidence: 0.8,
    detectedAtMs: 1000,
    sourceWindowStartDateKey: '2026-05-01',
    sourceWindowEndDateKey: '2026-05-07',
    evidence: const [],
  );
}

List<FocusCandidate> _multipleCandidates() {
  return [
    _candidate(
      insightType: InsightType.streakRiskWarning,
      bucket: InsightBucket.risk,
      priority: InsightPriority.high,
      confidence: 0.9,
      urgency: 0.85,
      coachingImportance: 0.9,
      patterns: [_pattern(PatternCode.streakRisk)],
      insightId: 'insight-streak-risk',
    ),
    _candidate(
      insightType: InsightType.strongStreakPraise,
      bucket: InsightBucket.reinforcement,
      priority: InsightPriority.low,
      confidence: 0.7,
      urgency: 0.3,
      coachingImportance: 0.3,
      patterns: [_pattern(PatternCode.strongStreak)],
      insightId: 'insight-strong-streak',
    ),
    _candidate(
      insightType: InsightType.inconsistencyNotice,
      bucket: InsightBucket.neutral,
      priority: InsightPriority.medium,
      confidence: 0.6,
      urgency: 0.5,
      coachingImportance: 0.5,
      patterns: [_pattern(PatternCode.inconsistentBehavior)],
      insightId: 'insight-inconsistency',
    ),
  ];
}

CurrentCoachingFocus _makeFocus({
  String primaryInsightId = 'insight-id',
  FocusLifecycleState lifecycleState = FocusLifecycleState.active,
  FocusReason reason = FocusReason.highestMomentumLeverage,
  double focusScore = 0.7,
  double focusConfidence = 0.65,
  int? detectedAtMs,
  int? activeUntilMs,
}) {
  final nowMs = DateTime(2026, 5, 7, 9).millisecondsSinceEpoch;
  return CurrentCoachingFocus(
    focusId: 'focus::$primaryInsightId::$nowMs',
    primaryInsightId: primaryInsightId,
    lifecycleState: lifecycleState,
    focusReason: reason,
    focusScore: focusScore,
    focusConfidence: focusConfidence,
    scoreBreakdown: FocusScoreBreakdown(
      urgencyScore: 0.7,
      momentumScore: 0.5,
      feasibilityScore: 0.6,
      riskScore: 0.8,
      recoveryScore: 0.3,
      focusScore: focusScore,
    ),
    contextSnapshot: const FocusContextSnapshot(
      insightTypes: ['streakRiskWarning'],
      keyPatternCodes: ['streakRisk'],
      topEvidence: {},
      selectedRationale: 'test',
      timingProfile: 'morning',
    ),
    evaluationTrace: const ['trace line 1', 'trace line 2'],
    suppressedCandidates: const [],
    sourceInsightTypes: const ['streakRiskWarning'],
    detectedAtMs: detectedAtMs ?? nowMs,
    activeUntilMs: activeUntilMs ??
        (nowMs + const Duration(hours: 2).inMilliseconds),
  );
}

extension _CopyWith on CurrentCoachingFocus {
  CurrentCoachingFocus copyWith({String? focusId}) {
    return CurrentCoachingFocus(
      focusId: focusId ?? this.focusId,
      primaryInsightId: primaryInsightId,
      secondaryInsightId: secondaryInsightId,
      lifecycleState: lifecycleState,
      focusReason: focusReason,
      focusScore: focusScore,
      focusConfidence: focusConfidence,
      scoreBreakdown: scoreBreakdown,
      contextSnapshot: contextSnapshot,
      evaluationTrace: evaluationTrace,
      suppressedCandidates: suppressedCandidates,
      sourceInsightTypes: sourceInsightTypes,
      detectedAtMs: detectedAtMs,
      activeUntilMs: activeUntilMs,
      resolvedAtMs: resolvedAtMs,
      replacementReason: replacementReason,
      metadata: metadata,
      schemaVersion: schemaVersion,
    );
  }
}
