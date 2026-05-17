import 'package:flutter_test/flutter_test.dart';

import 'package:coach_for_life/features/analytics/application/ai_response_validator.dart';
import 'package:coach_for_life/features/analytics/application/coaching_ai_client.dart';
import 'package:coach_for_life/features/analytics/application/deterministic_coaching_renderer.dart';
import 'package:coach_for_life/features/analytics/domain/models/ai_summary_response.dart';
import 'package:coach_for_life/features/analytics/domain/models/coaching_ai_payload.dart';
import 'package:coach_for_life/features/analytics/domain/models/current_coaching_focus.dart';
import 'package:coach_for_life/features/analytics/domain/models/generated_insight.dart';

void main() {
  // ─── CoachingFraming derivation ─────────────────────────────────────────────

  group('deriveCoachingFraming', () {
    test('imminentStreakRisk → protection', () {
      expect(
        deriveCoachingFraming(
          focusReason: FocusReason.imminentStreakRisk,
          focusScore: 0.8,
          urgencyScore: 0.9,
        ),
        CoachingFraming.protection,
      );
    });

    test('bestRecoveryOpportunity → recovery', () {
      expect(
        deriveCoachingFraming(
          focusReason: FocusReason.bestRecoveryOpportunity,
          focusScore: 0.6,
          urgencyScore: 0.5,
        ),
        CoachingFraming.recovery,
      );
    });

    test('highestMomentumLeverage → momentum', () {
      expect(
        deriveCoachingFraming(
          focusReason: FocusReason.highestMomentumLeverage,
          focusScore: 0.75,
          urgencyScore: 0.6,
        ),
        CoachingFraming.momentum,
      );
    });

    test('globalOverloadSignal → stabilization', () {
      expect(
        deriveCoachingFraming(
          focusReason: FocusReason.globalOverloadSignal,
          focusScore: 0.5,
          urgencyScore: 0.4,
        ),
        CoachingFraming.stabilization,
      );
    });

    test('overdueItemCritical high urgency → protection', () {
      expect(
        deriveCoachingFraming(
          focusReason: FocusReason.overdueItemCritical,
          focusScore: 0.7,
          urgencyScore: 0.8,
        ),
        CoachingFraming.protection,
      );
    });

    test('overdueItemCritical low urgency → recovery', () {
      expect(
        deriveCoachingFraming(
          focusReason: FocusReason.overdueItemCritical,
          focusScore: 0.5,
          urgencyScore: 0.3,
        ),
        CoachingFraming.recovery,
      );
    });

    test('scheduledWindowActive high score → momentum', () {
      expect(
        deriveCoachingFraming(
          focusReason: FocusReason.scheduledWindowActive,
          focusScore: 0.75,
          urgencyScore: 0.5,
        ),
        CoachingFraming.momentum,
      );
    });

    test('scheduledWindowActive low score → consistency', () {
      expect(
        deriveCoachingFraming(
          focusReason: FocusReason.scheduledWindowActive,
          focusScore: 0.4,
          urgencyScore: 0.3,
        ),
        CoachingFraming.consistency,
      );
    });

    test('is deterministic for same inputs', () {
      final a = deriveCoachingFraming(
        focusReason: FocusReason.reinforcingActiveStreak,
        focusScore: 0.7,
        urgencyScore: 0.5,
      );
      final b = deriveCoachingFraming(
        focusReason: FocusReason.reinforcingActiveStreak,
        focusScore: 0.7,
        urgencyScore: 0.5,
      );
      expect(a, b);
    });
  });

  // ─── SummaryType derivation ──────────────────────────────────────────────────

  group('deriveSummaryType', () {
    test('strongStreakPraise → reinforcement regardless of framing', () {
      for (final framing in CoachingFraming.values) {
        expect(
          deriveSummaryType(
            framing: framing,
            primaryInsightType: InsightType.strongStreakPraise,
          ),
          SummaryType.reinforcement,
          reason: 'framing=$framing should still yield reinforcement',
        );
      }
    });

    test('recovery framing → SummaryType.recovery', () {
      expect(
        deriveSummaryType(
          framing: CoachingFraming.recovery,
          primaryInsightType: InsightType.latePattern,
        ),
        SummaryType.recovery,
      );
    });

    test('protection framing → SummaryType.focus', () {
      expect(
        deriveSummaryType(
          framing: CoachingFraming.protection,
          primaryInsightType: InsightType.streakRiskWarning,
        ),
        SummaryType.focus,
      );
    });

    test('consistency framing → SummaryType.daily', () {
      expect(
        deriveSummaryType(
          framing: CoachingFraming.consistency,
          primaryInsightType: InsightType.inconsistencyNotice,
        ),
        SummaryType.daily,
      );
    });
  });

  // ─── Staleness TTL ────────────────────────────────────────────────────────────

  group('computeAiSummaryTtlMs', () {
    test('high urgency → 1h TTL', () {
      final ttl = computeAiSummaryTtlMs(
        summaryType: SummaryType.focus,
        focusScore: 0.7,
        urgencyScore: 0.8,
      );
      expect(ttl, 1 * 60 * 60 * 1000);
    });

    test('very high focus score → 1h TTL', () {
      final ttl = computeAiSummaryTtlMs(
        summaryType: SummaryType.focus,
        focusScore: 0.9,
        urgencyScore: 0.4,
      );
      expect(ttl, 1 * 60 * 60 * 1000);
    });

    test('reinforcement → 12h TTL', () {
      final ttl = computeAiSummaryTtlMs(
        summaryType: SummaryType.reinforcement,
        focusScore: 0.5,
        urgencyScore: 0.3,
      );
      expect(ttl, 12 * 60 * 60 * 1000);
    });

    test('low urgency daily → 18h TTL', () {
      final ttl = computeAiSummaryTtlMs(
        summaryType: SummaryType.daily,
        focusScore: 0.3,
        urgencyScore: 0.2,
      );
      expect(ttl, 18 * 60 * 60 * 1000);
    });

    test('mid-tier → default 6h TTL', () {
      final ttl = computeAiSummaryTtlMs(
        summaryType: SummaryType.focus,
        focusScore: 0.5,
        urgencyScore: 0.4,
      );
      expect(ttl, kAiSummaryBaseTtlMs);
    });
  });

  // ─── CoachingAiPayload ─────────────────────────────────────────────────────

  group('CoachingAiPayload', () {
    CurrentCoachingFocus _makeFocus({
      FocusReason reason = FocusReason.imminentStreakRisk,
      double focusScore = 0.8,
      double urgencyScore = 0.9,
    }) {
      return CurrentCoachingFocus(
        focusId: 'focus-1',
        primaryInsightId: 'insight-1',
        lifecycleState: FocusLifecycleState.active,
        focusReason: reason,
        focusScore: focusScore,
        focusConfidence: 0.75,
        scoreBreakdown: FocusScoreBreakdown(
          urgencyScore: urgencyScore,
          momentumScore: 0.6,
          feasibilityScore: 0.7,
          riskScore: 0.8,
          recoveryScore: 0.5,
          focusScore: focusScore,
        ),
        contextSnapshot: const FocusContextSnapshot(
          insightTypes: ['streakRiskWarning'],
          keyPatternCodes: ['streakAtRisk'],
          topEvidence: {'streakDays': 14},
          selectedRationale: 'high streak risk detected',
          timingProfile: 'evening',
        ),
        evaluationTrace: ['high streak risk', 'evening window', 'user idle'],
        suppressedCandidates: [],
        sourceInsightTypes: ['streakRiskWarning'],
        detectedAtMs: 1000,
        activeUntilMs: 999999999999,
      );
    }

    test('fromFocus assembles correctly', () {
      final focus = _makeFocus();
      final delivery = const AiDeliveryContext(
        timingProfile: 'evening',
        localDateKey: '2026-05-17',
      );
      final payload = CoachingAiPayload.fromFocus(
        focus: focus,
        primaryInsightType: InsightType.streakRiskWarning,
        deliveryContext: delivery,
      );

      expect(payload.focusId, 'focus-1');
      expect(payload.focusReason, FocusReason.imminentStreakRisk.name);
      expect(payload.framing, CoachingFraming.protection);
      expect(payload.summaryType, SummaryType.focus);
      expect(payload.promptVersion, kCoachingAiPromptVersion);
      expect(payload.evaluationTrace.length, lessThanOrEqualTo(5));
      expect(payload.keyPatternCodes.length, lessThanOrEqualTo(3));
      expect(payload.topEvidence.length, lessThanOrEqualTo(6));
    });

    test('toMap round-trips framing and summaryType', () {
      final focus = _makeFocus(reason: FocusReason.bestRecoveryOpportunity);
      final payload = CoachingAiPayload.fromFocus(
        focus: focus,
        primaryInsightType: InsightType.bestRecoveryOpportunity,
        deliveryContext: const AiDeliveryContext(
          timingProfile: 'morning',
          localDateKey: '2026-05-17',
        ),
      );
      final map = payload.toMap();
      expect(map['framing'], CoachingFraming.recovery.name);
      expect(map['summaryType'], SummaryType.recovery.name);
    });

    test('evidenceTrace is capped at 5 entries', () {
      final longTrace = List.generate(10, (i) => 'trace $i');
      final focus = CurrentCoachingFocus(
        focusId: 'f',
        primaryInsightId: 'i',
        lifecycleState: FocusLifecycleState.active,
        focusReason: FocusReason.highestMomentumLeverage,
        focusScore: 0.7,
        focusConfidence: 0.6,
        scoreBreakdown: FocusScoreBreakdown(
          urgencyScore: 0.5,
          momentumScore: 0.6,
          feasibilityScore: 0.7,
          riskScore: 0.4,
          recoveryScore: 0.3,
          focusScore: 0.7,
        ),
        contextSnapshot: FocusContextSnapshot(
          insightTypes: const [],
          keyPatternCodes: const [],
          topEvidence: const {},
          selectedRationale: '',
          timingProfile: 'morning',
        ),
        evaluationTrace: longTrace,
        suppressedCandidates: const [],
        sourceInsightTypes: const [],
        detectedAtMs: 0,
        activeUntilMs: 0,
      );
      final payload = CoachingAiPayload.fromFocus(
        focus: focus,
        primaryInsightType: InsightType.highestMomentumLeverage,
        deliveryContext: const AiDeliveryContext(
          timingProfile: 'morning',
          localDateKey: '2026-05-17',
        ),
      );
      expect(payload.toMap()['evaluationTrace'].length, 5);
    });
  });

  // ─── AiSummaryResponse ────────────────────────────────────────────────────────

  group('AiSummaryResponse', () {
    test('toMap/fromMap round-trip', () {
      const r = AiSummaryResponse(
        focusId: 'focus-abc',
        summaryType: SummaryType.focus,
        tone: CoachingTone.assertive,
        dailySummary: 'Your streak needs protection.',
        mainRecommendation: 'Complete a brief session before bed.',
        framing: CoachingFraming.protection,
        generatedAtMs: 1000000,
        promptVersion: 'v1.0.0',
        validationOutcome: AiSummaryValidationOutcome.passed,
        isFallback: false,
      );

      final map = r.toMap();
      final restored = AiSummaryResponse.fromMap(map);

      expect(restored.focusId, r.focusId);
      expect(restored.summaryType, r.summaryType);
      expect(restored.tone, r.tone);
      expect(restored.dailySummary, r.dailySummary);
      expect(restored.mainRecommendation, r.mainRecommendation);
      expect(restored.framing, r.framing);
      expect(restored.validationOutcome, r.validationOutcome);
      expect(restored.isFallback, r.isFallback);
      expect(restored.promptVersion, r.promptVersion);
    });

    test('withValidationOutcome preserves all fields', () {
      const r = AiSummaryResponse(
        focusId: 'f',
        summaryType: SummaryType.daily,
        tone: CoachingTone.informative,
        dailySummary: 'Summary text.',
        mainRecommendation: 'Do this.',
        framing: CoachingFraming.consistency,
        generatedAtMs: 1,
        promptVersion: 'v1',
      );
      final rejected = r.withValidationOutcome(
        AiSummaryValidationOutcome.contradictsFocus,
      );
      expect(rejected.dailySummary, r.dailySummary);
      expect(rejected.focusId, r.focusId);
      expect(rejected.isValid, isFalse);
    });

    test('empty constant has isFallback=true', () {
      expect(AiSummaryResponse.empty.isFallback, isTrue);
    });
  });

  // ─── AiResponseValidator ────────────────────────────────────────────────────

  group('AiResponseValidator', () {
    const validator = AiResponseValidator();

    CoachingAiPayload _payload({
      FocusReason reason = FocusReason.imminentStreakRisk,
    }) {
      final framing = deriveCoachingFraming(
        focusReason: reason,
        focusScore: 0.8,
        urgencyScore: 0.9,
      );
      return CoachingAiPayload(
        focusId: 'f1',
        focusReason: reason.name,
        framing: framing,
        summaryType: SummaryType.focus,
        primaryInsightType: 'streakRiskWarning',
        focusScore: 0.8,
        urgencyScore: 0.9,
        evaluationTrace: const ['trace1'],
        keyPatternCodes: const ['streakAtRisk'],
        topEvidence: const {},
        deliveryContext: const AiDeliveryContext(
          timingProfile: 'evening',
          localDateKey: '2026-05-17',
        ),
        generatedAtMs: 1000,
        promptVersion: 'v1.0.0',
      );
    }

    AiSummaryResponse _response({
      String summary = 'Your streak needs attention. Act now to protect it.',
      String recommendation = 'Complete a short session tonight.',
      CoachingTone tone = CoachingTone.assertive,
      CoachingFraming framing = CoachingFraming.protection,
    }) {
      return AiSummaryResponse(
        focusId: 'f1',
        summaryType: SummaryType.focus,
        tone: tone,
        dailySummary: summary,
        mainRecommendation: recommendation,
        framing: framing,
        generatedAtMs: 1000,
        promptVersion: 'v1.0.0',
      );
    }

    test('valid response passes', () {
      final result = validator.validate(
        response: _response(),
        payload: _payload(),
      );
      expect(result.isValid, isTrue);
    });

    test('missing dailySummary → missingRequiredField', () {
      final result = validator.validate(
        response: _response(summary: ''),
        payload: _payload(),
      );
      expect(result.validationOutcome,
          AiSummaryValidationOutcome.missingRequiredField);
    });

    test('too-short summary → tooVague', () {
      final result = validator.validate(
        response: _response(summary: 'Do it.'),
        payload: _payload(),
      );
      expect(result.validationOutcome, AiSummaryValidationOutcome.tooVague);
    });

    test('excessively long summary → tooLong', () {
      final longSummary = List.generate(120, (i) => 'word').join(' ');
      final result = validator.validate(
        response: _response(summary: longSummary),
        payload: _payload(),
      );
      expect(result.validationOutcome, AiSummaryValidationOutcome.tooLong);
    });

    test('tone mismatch → toneMismatch', () {
      final result = validator.validate(
        response: _response(tone: CoachingTone.supportive), // expects assertive
        payload: _payload(reason: FocusReason.imminentStreakRisk),
      );
      expect(result.validationOutcome, AiSummaryValidationOutcome.toneMismatch);
    });

    test('"take a rest day" for imminentStreakRisk → contradictsFocus', () {
      final result = validator.validate(
        response: _response(
          summary: 'You have been working hard. Take a rest day and recharge.',
          recommendation: 'Skip today — rest day recommended.',
        ),
        payload: _payload(reason: FocusReason.imminentStreakRisk),
      );
      expect(
          result.validationOutcome, AiSummaryValidationOutcome.contradictsFocus);
    });

    test('"at risk" for reinforcingActiveStreak → contradictsFocus', () {
      final momentumPayload = CoachingAiPayload(
        focusId: 'f2',
        focusReason: FocusReason.reinforcingActiveStreak.name,
        framing: CoachingFraming.momentum,
        summaryType: SummaryType.reinforcement,
        primaryInsightType: 'strongStreakPraise',
        focusScore: 0.8,
        urgencyScore: 0.4,
        evaluationTrace: const [],
        keyPatternCodes: const [],
        topEvidence: const {},
        deliveryContext: const AiDeliveryContext(
          timingProfile: 'morning',
          localDateKey: '2026-05-17',
        ),
        generatedAtMs: 1000,
        promptVersion: 'v1.0.0',
      );

      final result = validator.validate(
        response: AiSummaryResponse(
          focusId: 'f2',
          summaryType: SummaryType.reinforcement,
          tone: CoachingTone.encouraging,
          dailySummary: 'Your streak is at risk of falling behind soon.',
          mainRecommendation: 'Keep going but be careful about losing streak.',
          framing: CoachingFraming.momentum,
          generatedAtMs: 1000,
          promptVersion: 'v1.0.0',
        ),
        payload: momentumPayload,
      );
      expect(
          result.validationOutcome, AiSummaryValidationOutcome.contradictsFocus);
    });

    test('validator is deterministic for same inputs', () {
      final r = _response();
      final p = _payload();
      final a = validator.validate(response: r, payload: p);
      final b = validator.validate(response: r, payload: p);
      expect(a.validationOutcome, b.validationOutcome);
    });
  });

  // ─── DeterministicCoachingRenderer ──────────────────────────────────────────

  group('DeterministicCoachingRenderer', () {
    const renderer = DeterministicCoachingRenderer();

    CoachingAiPayload _payload({
      FocusReason reason = FocusReason.imminentStreakRisk,
      CoachingFraming framing = CoachingFraming.protection,
      SummaryType summaryType = SummaryType.focus,
    }) {
      return CoachingAiPayload(
        focusId: 'f1',
        focusReason: reason.name,
        framing: framing,
        summaryType: summaryType,
        primaryInsightType: 'streakRiskWarning',
        focusScore: 0.8,
        urgencyScore: 0.9,
        evaluationTrace: const [],
        keyPatternCodes: const [],
        topEvidence: const {},
        deliveryContext: const AiDeliveryContext(
          timingProfile: 'evening',
          localDateKey: '2026-05-17',
        ),
        generatedAtMs: 1000,
        promptVersion: 'v1.0.0',
      );
    }

    test('always returns isFallback=true', () {
      for (final reason in FocusReason.values) {
        final payload = _payload(reason: reason);
        final response = renderer.render(payload: payload);
        expect(
          response.isFallback,
          isTrue,
          reason: 'reason=$reason should produce fallback',
        );
      }
    });

    test('every FocusReason produces non-empty text', () {
      for (final reason in FocusReason.values) {
        final framing = deriveCoachingFraming(
          focusReason: reason,
          focusScore: 0.7,
          urgencyScore: 0.5,
        );
        final response = renderer.render(
          payload: _payload(reason: reason, framing: framing),
        );
        expect(
          response.dailySummary.trim().isNotEmpty,
          isTrue,
          reason: 'reason=$reason summary must not be blank',
        );
        expect(
          response.mainRecommendation.trim().isNotEmpty,
          isTrue,
          reason: 'reason=$reason recommendation must not be blank',
        );
      }
    });

    test('imminentStreakRisk+protection produces protection framing text', () {
      final response = renderer.render(
        payload: _payload(
          reason: FocusReason.imminentStreakRisk,
          framing: CoachingFraming.protection,
        ),
      );
      expect(response.dailySummary.toLowerCase(), contains('streak'));
    });

    test('reinforcingActiveStreak+momentum produces encouraging tone', () {
      final response = renderer.render(
        payload: _payload(
          reason: FocusReason.reinforcingActiveStreak,
          framing: CoachingFraming.momentum,
        ),
      );
      expect(response.tone, CoachingTone.encouraging);
    });

    test('fallbackReason is stored in metadata when provided', () {
      final response = renderer.render(
        payload: _payload(),
        failureReason: 'timeout',
      );
      expect(response.metadata['fallbackReason'], 'timeout');
    });

    test('render is deterministic for same payload', () {
      final payload = _payload();
      final a = renderer.render(payload: payload);
      final b = renderer.render(payload: payload);
      expect(a.dailySummary, b.dailySummary);
      expect(a.mainRecommendation, b.mainRecommendation);
      expect(a.tone, b.tone);
    });
  });

  // ─── MockCoachingAiClient ─────────────────────────────────────────────────────

  group('MockCoachingAiClient', () {
    test('returns non-fallback response on success', () async {
      const client = MockCoachingAiClient();
      final payload = CoachingAiPayload(
        focusId: 'f1',
        focusReason: FocusReason.highestMomentumLeverage.name,
        framing: CoachingFraming.momentum,
        summaryType: SummaryType.focus,
        primaryInsightType: 'highestMomentumLeverage',
        focusScore: 0.75,
        urgencyScore: 0.5,
        evaluationTrace: const [],
        keyPatternCodes: const [],
        topEvidence: const {},
        deliveryContext: const AiDeliveryContext(
          timingProfile: 'afternoon',
          localDateKey: '2026-05-17',
        ),
        generatedAtMs: 1000,
        promptVersion: 'v1.0.0',
      );
      final response = await client.generateSummary(payload);
      expect(response.isFallback, isFalse);
      expect(response.focusId, 'f1');
      expect(response.dailySummary, isNotEmpty);
    });

    test('shouldFail=true throws AiClientException', () async {
      const client = MockCoachingAiClient(shouldFail: true);
      final payload = CoachingAiPayload(
        focusId: 'f2',
        focusReason: FocusReason.imminentStreakRisk.name,
        framing: CoachingFraming.protection,
        summaryType: SummaryType.focus,
        primaryInsightType: 'streakRiskWarning',
        focusScore: 0.8,
        urgencyScore: 0.9,
        evaluationTrace: const [],
        keyPatternCodes: const [],
        topEvidence: const {},
        deliveryContext: const AiDeliveryContext(
          timingProfile: 'evening',
          localDateKey: '2026-05-17',
        ),
        generatedAtMs: 1000,
        promptVersion: 'v1.0.0',
      );
      expect(
        () => client.generateSummary(payload),
        throwsA(isA<AiClientException>()),
      );
    });
  });

  // ─── CoachingFraming + tone enum round-trips ──────────────────────────────────

  group('enum round-trips', () {
    test('CoachingFraming all values survive storage round-trip', () {
      for (final v in CoachingFraming.values) {
        expect(coachingFramingFromStorage(v.name), v);
      }
    });

    test('SummaryType all values survive storage round-trip', () {
      for (final v in SummaryType.values) {
        expect(summaryTypeFromStorage(v.name), v);
      }
    });

    test('CoachingTone all values survive storage round-trip', () {
      for (final v in CoachingTone.values) {
        expect(coachingToneFromStorage(v.name), v);
      }
    });

    test('AiSummaryValidationOutcome unknown string → passed default', () {
      // Uses the private _outcomeFromStorage indirectly via fromMap
      final r = AiSummaryResponse.fromMap({
        'focusId': 'f',
        'summaryType': 'daily',
        'tone': 'informative',
        'dailySummary': 'text',
        'mainRecommendation': 'do it',
        'framing': 'consistency',
        'generatedAtMs': 0,
        'promptVersion': 'v1',
        'validationOutcome': 'TOTALLY_UNKNOWN_VALUE',
      });
      expect(r.validationOutcome, AiSummaryValidationOutcome.passed);
    });
  });

  // ─── expectedToneForFraming ────────────────────────────────────────────────────

  group('expectedToneForFraming', () {
    test('covers all framings without throwing', () {
      for (final framing in CoachingFraming.values) {
        expect(
          () => expectedToneForFraming(framing),
          returnsNormally,
          reason: 'framing=$framing should produce a tone',
        );
      }
    });

    test('momentum → encouraging', () {
      expect(expectedToneForFraming(CoachingFraming.momentum),
          CoachingTone.encouraging);
    });
    test('recovery → supportive', () {
      expect(expectedToneForFraming(CoachingFraming.recovery),
          CoachingTone.supportive);
    });
    test('protection → assertive', () {
      expect(expectedToneForFraming(CoachingFraming.protection),
          CoachingTone.assertive);
    });
    test('stabilization → informative', () {
      expect(expectedToneForFraming(CoachingFraming.stabilization),
          CoachingTone.informative);
    });
    test('consistency → informative', () {
      expect(expectedToneForFraming(CoachingFraming.consistency),
          CoachingTone.informative);
    });
  });
}
