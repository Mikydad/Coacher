import 'package:sidepal/features/analytics/application/insight_generation_policy.dart';
import 'package:sidepal/features/analytics/domain/models/generated_insight.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('insight_generation_policy', () {
    test('centralized config exposes strict V1 caps', () {
      expect(
        kLayer3InsightPolicyConfig.version,
        kLayer3InsightPolicyConfigVersion,
      );
      expect(kLayer3InsightPolicyConfig.outputCaps.maxEntityInsights, 3);
      expect(kLayer3InsightPolicyConfig.outputCaps.maxGlobalInsights, 3);
    });

    test('mapping catalog covers all Layer 3 V1 insight types', () {
      final mappedTypes = kLayer3InsightPolicyConfig.rules
          .map((rule) => rule.insightType)
          .toSet();
      // V1 types must all be present.
      expect(mappedTypes, containsAll(kLayer3V1InsightTypes));
      // V2 catalog covers all types including Phase 3 additions.
      expect(mappedTypes, equals(kLayer3V2InsightTypes));
      expect(kLayer3InsightPolicyConfig.rules, hasLength(kLayer3V2InsightTypes.length));
    });

    test('includes deterministic combination rule for goal_at_risk', () {
      final rule = kLayer3InsightPolicyConfig.rules.firstWhere(
        (entry) => entry.insightType == InsightType.goalAtRisk,
      );
      expect(rule.requiredAllPatterns.length, 1);
      expect(rule.requiredAnyPatterns, isNotEmpty);
      expect(rule.priority, InsightPriority.high);
      expect(rule.action, InsightAction.focus);
    });

    test('priority ranking helper orders high before medium/low', () {
      expect(priorityWeight(InsightPriority.high), greaterThan(priorityWeight(InsightPriority.medium)));
      expect(priorityWeight(InsightPriority.medium), greaterThan(priorityWeight(InsightPriority.low)));
    });

    test('compareInsightOrdering is deterministic for ties', () {
      final a = GeneratedInsight(
        insightId: 'a',
        scopeType: InsightScopeType.entity,
        scopeId: 'task-1',
        insightType: InsightType.latePattern,
        insightBucket: InsightBucket.neutral,
        priority: InsightPriority.medium,
        messageKey: 'late_pattern_1',
        message: 'A',
        action: InsightAction.reschedule,
        linkedPatternCodes: const <String>['late_behavior'],
        confidence: 0.7,
        detectedAtMs: 1,
        sourceWindowStartDateKey: '2026-05-01',
        sourceWindowEndDateKey: '2026-05-07',
      );
      final b = GeneratedInsight(
        insightId: 'b',
        scopeType: InsightScopeType.entity,
        scopeId: 'task-1',
        insightType: InsightType.latePattern,
        insightBucket: InsightBucket.neutral,
        priority: InsightPriority.medium,
        messageKey: 'late_pattern_1',
        message: 'B',
        action: InsightAction.reschedule,
        linkedPatternCodes: const <String>['late_behavior'],
        confidence: 0.7,
        detectedAtMs: 1,
        sourceWindowStartDateKey: '2026-05-01',
        sourceWindowEndDateKey: '2026-05-07',
      );
      expect(compareInsightOrdering(a, b), lessThan(0));
      expect(compareInsightOrdering(b, a), greaterThan(0));
    });

    test('merge key is stable by scope and insight type', () {
      final insight = GeneratedInsight(
        insightId: 'id-1',
        scopeType: InsightScopeType.global,
        scopeId: '2026-05-07',
        insightType: InsightType.streakRiskWarning,
        insightBucket: InsightBucket.risk,
        priority: InsightPriority.high,
        messageKey: 'streak_risk_1',
        message: 'm',
        action: InsightAction.doNow,
        linkedPatternCodes: const <String>['streak_risk'],
        confidence: 0.9,
        detectedAtMs: 1,
        sourceWindowStartDateKey: '2026-05-01',
        sourceWindowEndDateKey: '2026-05-07',
      );
      expect(
        mergeKeyForInsight(insight),
        'global::2026-05-07::streakRiskWarning',
      );
    });
  });
}
