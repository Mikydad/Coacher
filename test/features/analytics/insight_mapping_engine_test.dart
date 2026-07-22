import 'package:sidepal/features/analytics/application/insight_mapping_engine.dart';
import 'package:sidepal/features/analytics/domain/models/behavior_feature_object.dart';
import 'package:sidepal/features/analytics/domain/models/detected_pattern.dart';
import 'package:sidepal/features/analytics/domain/models/generated_insight.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('insight_mapping_engine', () {
    test('maps risk, neutral, and reinforcement insights deterministically', () {
      final patterns = <DetectedPattern>[
        _pattern(
          code: PatternCode.streakRisk,
          group: PatternGroup.streakConsistency,
          confidence: 0.9,
        ),
        _pattern(
          code: PatternCode.lateBehavior,
          group: PatternGroup.timeBehavior,
          confidence: 0.7,
        ),
        _pattern(
          code: PatternCode.strongStreak,
          group: PatternGroup.streakConsistency,
          confidence: 0.8,
        ),
      ];

      final insights = mapPatternsToInsights(
        patterns: patterns,
        context: const InsightMappingContext(
          scopeType: InsightScopeType.entity,
          scopeId: 'task-1',
          sourceWindowStartDateKey: '2026-05-01',
          sourceWindowEndDateKey: '2026-05-07',
          detectedAtMs: 123,
        ),
      );

      expect(
        insights.map((insight) => insight.insightType).toList(),
        <InsightType>[
          InsightType.streakRiskWarning,
          InsightType.latePattern,
        ],
      );
    });

    test('supports combination rule for goal_at_risk', () {
      final patterns = <DetectedPattern>[
        _pattern(
          code: PatternCode.inconsistentBehavior,
          group: PatternGroup.streakConsistency,
          confidence: 0.5,
        ),
        _pattern(
          code: PatternCode.lowEngagement,
          group: PatternGroup.effortDifficulty,
          confidence: 0.9,
        ),
      ];

      final insights = mapPatternsToInsights(
        patterns: patterns,
        context: const InsightMappingContext(
          scopeType: InsightScopeType.entity,
          scopeId: 'goal-1',
          sourceWindowStartDateKey: '2026-05-01',
          sourceWindowEndDateKey: '2026-05-07',
        ),
      );

      final goalRisk = insights.firstWhere(
        (insight) => insight.insightType == InsightType.goalAtRisk,
      );
      expect(goalRisk.linkedPatternCodes, contains('inconsistentBehavior'));
      expect(goalRisk.linkedPatternCodes, contains('lowEngagement'));
      expect(goalRisk.action, InsightAction.focus);
    });

    test('defers Layer 3 mapping for subtle Phase-2-only pattern codes', () {
      final onlyDeferred = <DetectedPattern>[
        _pattern(
          code: PatternCode.goalProgressDrift,
          group: PatternGroup.goalAlignment,
          confidence: 0.99,
        ),
        _pattern(
          code: PatternCode.scheduleRhythmVolatile,
          group: PatternGroup.behavioralStability,
          confidence: 0.99,
        ),
      ];
      expect(
        mapPatternsToInsights(
          patterns: onlyDeferred,
          context: const InsightMappingContext(
            scopeType: InsightScopeType.entity,
            scopeId: 'e1',
            sourceWindowStartDateKey: '2026-05-01',
            sourceWindowEndDateKey: '2026-05-07',
          ),
        ),
        isEmpty,
      );

      final mixed = <DetectedPattern>[
        onlyDeferred.first,
        _pattern(
          code: PatternCode.streakRisk,
          group: PatternGroup.streakConsistency,
          confidence: 0.9,
        ),
      ];
      final out = mapPatternsToInsights(
        patterns: mixed,
        context: const InsightMappingContext(
          scopeType: InsightScopeType.entity,
          scopeId: 'e1',
          sourceWindowStartDateKey: '2026-05-01',
          sourceWindowEndDateKey: '2026-05-07',
        ),
      );
      expect(
        out.any((i) => i.linkedPatternCodes.contains('goalProgressDrift')),
        false,
      );
      expect(
        out.any((i) => i.linkedPatternCodes.contains('streakRisk')),
        true,
      );
    });

    test('each emitted insight is fully formed', () {
      final insights = mapPatternsToInsights(
        patterns: <DetectedPattern>[
          _pattern(
            code: PatternCode.tooHard,
            group: PatternGroup.effortDifficulty,
            confidence: 0.8,
          ),
        ],
        context: const InsightMappingContext(
          scopeType: InsightScopeType.entity,
          scopeId: 'habit-1',
          sourceWindowStartDateKey: '2026-05-01',
          sourceWindowEndDateKey: '2026-05-07',
        ),
      );

      expect(insights, hasLength(1));
      final insight = insights.first;
      expect(insight.messageKey, isNotEmpty);
      expect(insight.message, isNotEmpty);
      expect(insight.linkedPatternCodes, isNotEmpty);
      expect(insight.confidence, inInclusiveRange(0.0, 1.0));
      expect(insight.insightId, contains('habit-1'));
      expect(insight.sourceWindowEndDateKey, '2026-05-07');
    });
  });
}

DetectedPattern _pattern({
  required PatternCode code,
  required PatternGroup group,
  required double confidence,
}) {
  return DetectedPattern(
    entityId: 'entity',
    entityKind: BehaviorEntityKind.task,
    patternCode: code,
    patternGroup: group,
    severity: 0.8,
    confidence: confidence,
    detectedAtMs: 1,
    sourceWindowStartDateKey: '2026-05-01',
    sourceWindowEndDateKey: '2026-05-07',
  );
}
