import 'package:coach_for_life/features/analytics/application/insight_post_processor.dart';
import 'package:coach_for_life/features/analytics/domain/models/generated_insight.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('insight_post_processor', () {
    test('merges overlapping same-scope insights deterministically', () {
      final first = _insight(
        id: 'i1',
        type: InsightType.latePattern,
        bucket: InsightBucket.neutral,
        priority: InsightPriority.medium,
        linkedCodes: const <String>['lateBehavior'],
        confidence: 0.6,
      );
      final second = _insight(
        id: 'i2',
        type: InsightType.inconsistencyNotice,
        bucket: InsightBucket.neutral,
        priority: InsightPriority.medium,
        linkedCodes: const <String>['lateBehavior', 'inconsistentBehavior'],
        confidence: 0.8,
      );

      final result = postProcessInsights(
        rawInsights: <GeneratedInsight>[first, second],
        scopeType: InsightScopeType.entity,
      );

      expect(result.insights, hasLength(1));
      expect(result.insights.first.linkedPatternCodes, contains('lateBehavior'));
      expect(
        result.insights.first.linkedPatternCodes,
        contains('inconsistentBehavior'),
      );
      expect(result.diagnostics.mergedCount, 1);
    });

    test('dedupes by insight type per scope and keeps best ranking', () {
      final weaker = _insight(
        id: 'i1',
        type: InsightType.streakRiskWarning,
        bucket: InsightBucket.risk,
        priority: InsightPriority.high,
        linkedCodes: const <String>['streakRisk'],
        confidence: 0.4,
      );
      final stronger = _insight(
        id: 'i2',
        type: InsightType.streakRiskWarning,
        bucket: InsightBucket.risk,
        priority: InsightPriority.high,
        linkedCodes: const <String>['streakRisk'],
        confidence: 0.9,
      );

      final result = postProcessInsights(
        rawInsights: <GeneratedInsight>[weaker, stronger],
        scopeType: InsightScopeType.entity,
      );

      expect(result.insights, hasLength(1));
      expect(result.insights.first.insightId, 'i2');
      expect(result.diagnostics.mergedCount, 1);
    });

    test('applies deterministic rank and strict cap', () {
      final result = postProcessInsights(
        rawInsights: <GeneratedInsight>[
          _insight(
            id: 'a',
            type: InsightType.strongStreakPraise,
            bucket: InsightBucket.reinforcement,
            priority: InsightPriority.low,
            linkedCodes: const <String>['strongStreak'],
            confidence: 0.7,
            scopeType: InsightScopeType.global,
            scopeId: '2026-05-07',
          ),
          _insight(
            id: 'b',
            type: InsightType.latePattern,
            bucket: InsightBucket.neutral,
            priority: InsightPriority.medium,
            linkedCodes: const <String>['lateBehavior'],
            confidence: 0.7,
            scopeType: InsightScopeType.global,
            scopeId: '2026-05-07',
          ),
          _insight(
            id: 'c',
            type: InsightType.habitTooHard,
            bucket: InsightBucket.risk,
            priority: InsightPriority.high,
            linkedCodes: const <String>['tooHard'],
            confidence: 0.9,
            scopeType: InsightScopeType.global,
            scopeId: '2026-05-07',
          ),
          _insight(
            id: 'd',
            type: InsightType.lowEngagementNotice,
            bucket: InsightBucket.neutral,
            priority: InsightPriority.medium,
            linkedCodes: const <String>['lowEngagement'],
            confidence: 0.6,
            scopeType: InsightScopeType.global,
            scopeId: '2026-05-07',
          ),
        ],
        scopeType: InsightScopeType.global,
      );

      expect(result.insights, hasLength(3));
      expect(result.insights.first.insightType, InsightType.habitTooHard);
      expect(result.diagnostics.cappedOutCount, 1);
    });

    test('reports diagnostics for filtered scope items', () {
      final entity = _insight(
        id: 'entity',
        type: InsightType.goalAtRisk,
        bucket: InsightBucket.risk,
        priority: InsightPriority.high,
        linkedCodes: const <String>['inconsistentBehavior'],
        confidence: 0.8,
      );
      final global = GeneratedInsight(
        insightId: 'global',
        scopeType: InsightScopeType.global,
        scopeId: '2026-05-07',
        insightType: InsightType.latePattern,
        insightBucket: InsightBucket.neutral,
        priority: InsightPriority.medium,
        messageKey: 'late_pattern_1',
        message: 'msg',
        action: InsightAction.reschedule,
        linkedPatternCodes: const <String>['lateBehavior'],
        confidence: 0.7,
        detectedAtMs: 1,
        sourceWindowStartDateKey: '2026-05-01',
        sourceWindowEndDateKey: '2026-05-07',
      );

      final result = postProcessInsights(
        rawInsights: <GeneratedInsight>[entity, global],
        scopeType: InsightScopeType.entity,
      );

      expect(result.insights, hasLength(1));
      expect(result.diagnostics.filteredByScopeCount, 1);
      expect(result.diagnostics.inputCount, 2);
      expect(result.diagnostics.outputCount, 1);
    });
  });
}

GeneratedInsight _insight({
  required String id,
  required InsightType type,
  required InsightBucket bucket,
  required InsightPriority priority,
  required List<String> linkedCodes,
  required double confidence,
  InsightScopeType scopeType = InsightScopeType.entity,
  String scopeId = 'task-1',
}) {
  return GeneratedInsight(
    insightId: id,
    scopeType: scopeType,
    scopeId: scopeId,
    insightType: type,
    insightBucket: bucket,
    priority: priority,
    messageKey: '${type.name}_key',
    message: 'message for ${type.name}',
    action: InsightAction.focus,
    linkedPatternCodes: linkedCodes,
    confidence: confidence,
    detectedAtMs: 1,
    sourceWindowStartDateKey: '2026-05-01',
    sourceWindowEndDateKey: '2026-05-07',
  );
}
