import 'package:coach_for_life/features/analytics/application/focus_candidate.dart';
import 'package:coach_for_life/features/analytics/application/focus_scoring_engine.dart';
import 'package:coach_for_life/features/analytics/application/layer4_delivery_policy.dart';
import 'package:coach_for_life/features/analytics/domain/models/generated_insight.dart';
import 'package:coach_for_life/features/coaching/application/enforcement_mode_policy.dart';
import 'package:coach_for_life/features/coaching/domain/models/enforcement_mode.dart';
import 'package:flutter_test/flutter_test.dart';

GeneratedInsight _insight({double urgency = 0.5}) => GeneratedInsight(
  insightId: 'i1',
  scopeType: InsightScopeType.entity,
  scopeId: 'entity-1',
  insightType: InsightType.streakRiskWarning,
  insightBucket: InsightBucket.risk,
  priority: InsightPriority.high,
  message: 'Test insight',
  messageKey: 'test',
  action: InsightAction.doNow,
  linkedPatternCodes: const [],
  confidence: 0.8,
  detectedAtMs: 0,
  sourceWindowStartDateKey: '2026-01-01',
  sourceWindowEndDateKey: '2026-01-01',
  urgency: urgency,
  coachingImportance: 0.7,
);

FocusCandidate _candidate(EnforcementMode mode, {double urgency = 0.5}) =>
    FocusCandidate(
      insight: _insight(urgency: urgency),
      supportingPatterns: const [],
      realtimeContext: const FocusRealtimeContext(
        timingProfile: DeliveryTimingProfile.morning,
      ),
      enforcementMode: mode,
    );

void main() {
  // ─── computeUrgencyScore ──────────────────────────────────────────────────

  group('computeUrgencyScore — EnforcementMode multiplier', () {
    const baseUrgency = 0.5;

    test('flexible reduces urgency score by ×0.8', () {
      final score = computeUrgencyScore(
        insight: _insight(urgency: baseUrgency),
        ctx: const FocusRealtimeContext(
          timingProfile: DeliveryTimingProfile.morning,
        ),
        enforcementMode: EnforcementMode.flexible,
      );
      expect(score, closeTo(baseUrgency * 0.8, 0.001));
    });

    test('disciplined leaves urgency score unchanged (×1.0)', () {
      final score = computeUrgencyScore(
        insight: _insight(urgency: baseUrgency),
        ctx: const FocusRealtimeContext(
          timingProfile: DeliveryTimingProfile.morning,
        ),
        enforcementMode: EnforcementMode.disciplined,
      );
      expect(score, closeTo(baseUrgency * 1.0, 0.001));
    });

    test('extreme increases urgency score by ×1.3', () {
      final score = computeUrgencyScore(
        insight: _insight(urgency: baseUrgency),
        ctx: const FocusRealtimeContext(
          timingProfile: DeliveryTimingProfile.morning,
        ),
        enforcementMode: EnforcementMode.extreme,
      );
      expect(score, closeTo(baseUrgency * 1.3, 0.001));
    });

    test('extreme result is clamped to 1.0 when base urgency is 0.9', () {
      final score = computeUrgencyScore(
        insight: _insight(urgency: 0.9),
        ctx: const FocusRealtimeContext(
          timingProfile: DeliveryTimingProfile.morning,
        ),
        enforcementMode: EnforcementMode.extreme,
      );
      expect(score, lessThanOrEqualTo(1.0));
    });
  });

  // ─── computeFocusScoreBreakdown threading ─────────────────────────────────

  group('computeFocusScoreBreakdown threads enforcementMode', () {
    test('flexible candidate has lower urgency than disciplined', () {
      final flexBreakdown = computeFocusScoreBreakdown(
        _candidate(EnforcementMode.flexible, urgency: 0.5),
      );
      final discBreakdown = computeFocusScoreBreakdown(
        _candidate(EnforcementMode.disciplined, urgency: 0.5),
      );
      expect(flexBreakdown.urgencyScore, lessThan(discBreakdown.urgencyScore));
    });

    test('extreme candidate has higher urgency than disciplined', () {
      final extBreakdown = computeFocusScoreBreakdown(
        _candidate(EnforcementMode.extreme, urgency: 0.5),
      );
      final discBreakdown = computeFocusScoreBreakdown(
        _candidate(EnforcementMode.disciplined, urgency: 0.5),
      );
      expect(extBreakdown.urgencyScore, greaterThan(discBreakdown.urgencyScore));
    });

    test('default candidate (no enforcementMode) uses disciplined × 1.0', () {
      final def = computeFocusScoreBreakdown(
        FocusCandidate(
          insight: _insight(urgency: 0.5),
          supportingPatterns: const [],
          realtimeContext: const FocusRealtimeContext(
            timingProfile: DeliveryTimingProfile.morning,
          ),
        ),
      );
      final disc = computeFocusScoreBreakdown(
        _candidate(EnforcementMode.disciplined, urgency: 0.5),
      );
      expect(def.urgencyScore, closeTo(disc.urgencyScore, 0.001));
    });
  });

  // ─── urgencyMultiplier order ──────────────────────────────────────────────

  test('multiplier ordering: flexible < disciplined < extreme', () {
    expect(
      EnforcementModePolicy.urgencyMultiplier(EnforcementMode.flexible),
      lessThan(
        EnforcementModePolicy.urgencyMultiplier(EnforcementMode.disciplined),
      ),
    );
    expect(
      EnforcementModePolicy.urgencyMultiplier(EnforcementMode.disciplined),
      lessThan(
        EnforcementModePolicy.urgencyMultiplier(EnforcementMode.extreme),
      ),
    );
  });
}
