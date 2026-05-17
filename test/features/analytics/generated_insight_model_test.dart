import 'package:coach_for_life/features/analytics/domain/models/generated_insight.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('generated_insight model', () {
    test('fromMap uses compatibility defaults for unknown enums', () {
      final insight = GeneratedInsight.fromMap(<String, dynamic>{
        'insightId': 'insight-1',
        'scopeType': 'unknown',
        'scopeId': 'task-1',
        'insightType': 'unknown',
        'insightBucket': 'unknown',
        'priority': 'unknown',
        'messageKey': 'k',
        'message': 'fallback message',
        'action': 'unknown',
        'linkedPatternCodes': <dynamic>['streak_risk', 123, '', null],
        'sourceWindowStartDateKey': '2026-05-01',
        'sourceWindowEndDateKey': '2026-05-07',
      });

      expect(insight.scopeType, InsightScopeType.entity);
      expect(insight.insightType, InsightType.latePattern);
      expect(insight.insightBucket, InsightBucket.neutral);
      expect(insight.priority, InsightPriority.medium);
      expect(insight.action, InsightAction.doNow);
      expect(insight.linkedPatternCodes, <String>['streak_risk']);
      expect(insight.confidence, 0);
      expect(insight.schemaVersion, kGeneratedInsightSchemaVersion);
    });

    test('toMap clamps confidence and filters empty linked codes', () {
      final insight = GeneratedInsight(
        insightId: 'insight-2',
        scopeType: InsightScopeType.global,
        scopeId: '2026-05-07',
        insightType: InsightType.streakRiskWarning,
        insightBucket: InsightBucket.risk,
        priority: InsightPriority.high,
        messageKey: 'streak_risk_1',
        message: 'You are close to breaking momentum.',
        action: InsightAction.doNow,
        linkedPatternCodes: <String>['streak_risk', ' ', 'late_behavior'],
        confidence: 1.4,
        detectedAtMs: 7,
        sourceWindowStartDateKey: '2026-05-01',
        sourceWindowEndDateKey: '2026-05-07',
      );

      final map = insight.toMap();
      expect(map['confidence'], 1.0);
      expect(
        map['linkedPatternCodes'],
        <String>['streak_risk', 'late_behavior'],
      );
    });

    test('validate enforces required non-empty fields', () {
      final invalid = GeneratedInsight(
        insightId: '',
        scopeType: InsightScopeType.entity,
        scopeId: 'scope',
        insightType: InsightType.goalAtRisk,
        insightBucket: InsightBucket.risk,
        priority: InsightPriority.high,
        messageKey: 'goal_risk_1',
        message: 'Goal is slipping.',
        action: InsightAction.focus,
        linkedPatternCodes: const <String>['goal_gap'],
        confidence: 0.8,
        detectedAtMs: 1,
        sourceWindowStartDateKey: '2026-05-01',
        sourceWindowEndDateKey: '2026-05-07',
      );

      expect(invalid.validate, throwsArgumentError);
    });

    test('catalog contains all Layer 3 V1 insight types', () {
      expect(kLayer3V1InsightTypes, contains(InsightType.streakRiskWarning));
      expect(kLayer3V1InsightTypes, contains(InsightType.latePattern));
      expect(
        kLayer3V1InsightTypes,
        contains(InsightType.consistentBehaviorPraise),
      );
      expect(kLayer3V1InsightTypes, hasLength(10));
    });
  });
}
