import 'package:coach_for_life/features/analytics/application/insight_mapping_engine.dart';
import 'package:coach_for_life/features/analytics/domain/models/behavior_feature_object.dart';
import 'package:coach_for_life/features/analytics/domain/models/coaching_insight_taxonomy.dart';
import 'package:coach_for_life/features/analytics/domain/models/detected_pattern.dart';
import 'package:coach_for_life/features/analytics/domain/models/generated_insight.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 3 — coaching insight taxonomy', () {
    test('all Phase 3 InsightTypes have a taxonomy entry', () {
      for (final type in InsightType.values) {
        expect(
          kCoachingInsightTaxonomy.containsKey(type),
          isTrue,
          reason: '${type.name} is missing from kCoachingInsightTaxonomy',
        );
      }
    });

    test('taxonomy families cover all insight types without duplication', () {
      final seen = <CoachingInsightFamily>{};
      for (final entry in kCoachingInsightTaxonomy.values) {
        // Multiple types may share a family; verify family is valid.
        expect(
          CoachingInsightFamily.values.contains(entry.family),
          isTrue,
          reason: '${entry.insightType.name} has invalid family',
        );
        seen.add(entry.family);
      }
      // All families must appear at least once.
      for (final family in CoachingInsightFamily.values) {
        expect(
          seen.contains(family),
          isTrue,
          reason: 'family ${family.name} has no insight types mapped',
        );
      }
    });

    test('coachingInsightFamilyForType is consistent with taxonomy', () {
      for (final type in InsightType.values) {
        final fromFunction = coachingInsightFamilyForType(type);
        final fromTaxonomy = kCoachingInsightTaxonomy[type]!.family;
        expect(
          fromFunction,
          equals(fromTaxonomy),
          reason: '${type.name}: function returned ${fromFunction.name} but taxonomy says ${fromTaxonomy.name}',
        );
      }
    });

    test('coachingInsightFamilyFromStorage roundtrips all values', () {
      for (final family in CoachingInsightFamily.values) {
        expect(coachingInsightFamilyFromStorage(family.name), equals(family));
      }
      expect(
        coachingInsightFamilyFromStorage(null),
        equals(CoachingInsightFamily.risk),
      );
    });

    test('focus-oriented insights are flagged isFocusOriented', () {
      const expected = {
        InsightType.highestMomentumLeverage,
        InsightType.fragileStreakAlert,
        InsightType.bestRecoveryOpportunity,
        InsightType.streakRiskWarning,
        InsightType.goalAtRisk,
      };
      for (final type in expected) {
        expect(
          kCoachingInsightTaxonomy[type]!.isFocusOriented,
          isTrue,
          reason: '${type.name} should be isFocusOriented',
        );
      }
    });
  });

  group('Phase 3 — insight lifecycle fields', () {
    test('mapPatternsToInsights emits lifecycleState=active with urgency + coachingImportance', () {
      final insights = mapPatternsToInsights(
        patterns: <DetectedPattern>[
          _p(PatternCode.streakRisk, PatternGroup.streakConsistency, 0.9),
        ],
        context: const InsightMappingContext(
          scopeType: InsightScopeType.entity,
          scopeId: 'task-1',
          sourceWindowStartDateKey: '2026-05-01',
          sourceWindowEndDateKey: '2026-05-07',
          detectedAtMs: 1000,
        ),
      );

      expect(insights, isNotEmpty);
      final insight = insights.first;
      expect(insight.lifecycleState, InsightLifecycleState.active);
      expect(insight.urgency, greaterThan(0.0));
      expect(insight.coachingImportance, greaterThan(0.0));
      expect(insight.urgency, lessThanOrEqualTo(1.0));
      expect(insight.coachingImportance, lessThanOrEqualTo(1.0));
    });

    test('urgency is higher for high-priority than low-priority at same confidence', () {
      final highPriorityUrgency = computeInsightUrgency(
        priority: InsightPriority.high,
        confidence: 0.8,
        state: InsightLifecycleState.active,
      );
      final lowPriorityUrgency = computeInsightUrgency(
        priority: InsightPriority.low,
        confidence: 0.8,
        state: InsightLifecycleState.active,
      );
      expect(highPriorityUrgency, greaterThan(lowPriorityUrgency));
    });

    test('reinforced lifecycle slightly increases urgency compared to active', () {
      const priority = InsightPriority.medium;
      const confidence = 0.8;
      final activeUrgency = computeInsightUrgency(
        priority: priority,
        confidence: confidence,
        state: InsightLifecycleState.active,
      );
      final reinforcedUrgency = computeInsightUrgency(
        priority: priority,
        confidence: confidence,
        state: InsightLifecycleState.reinforced,
      );
      expect(reinforcedUrgency, greaterThan(activeUrgency));
    });

    test('coachingImportance is higher for risk bucket vs reinforcement', () {
      final riskImportance = computeCoachingImportance(
        bucket: InsightBucket.risk,
        priority: InsightPriority.high,
        confidence: 0.8,
      );
      final reinforcementImportance = computeCoachingImportance(
        bucket: InsightBucket.reinforcement,
        priority: InsightPriority.high,
        confidence: 0.8,
      );
      expect(riskImportance, greaterThan(reinforcementImportance));
    });

    test('isInsightLive returns true for active/generated/reinforced and false for resolved/archived', () {
      expect(isInsightLive(InsightLifecycleState.generated), isTrue);
      expect(isInsightLive(InsightLifecycleState.active), isTrue);
      expect(isInsightLive(InsightLifecycleState.reinforced), isTrue);
      expect(isInsightLive(InsightLifecycleState.resolved), isFalse);
      expect(isInsightLive(InsightLifecycleState.archived), isFalse);
    });
  });

  group('Phase 3 — supporting metrics in insight', () {
    test('emitted insight contains supportingMetrics with severity + confidence per code', () {
      final insights = mapPatternsToInsights(
        patterns: <DetectedPattern>[
          _p(PatternCode.tooHard, PatternGroup.effortDifficulty, 0.75),
        ],
        context: const InsightMappingContext(
          scopeType: InsightScopeType.entity,
          scopeId: 'habit-x',
          sourceWindowStartDateKey: '2026-05-01',
          sourceWindowEndDateKey: '2026-05-07',
        ),
      );

      expect(insights, hasLength(1));
      final metrics = insights.first.supportingMetrics;
      expect(metrics['tooHard.severity'], isA<double>());
      expect(metrics['tooHard.confidence'], closeTo(0.75, 0.001));
    });

    test('supporting metrics serialise and deserialise via toMap/fromMap', () {
      final original = mapPatternsToInsights(
        patterns: <DetectedPattern>[
          _p(PatternCode.streakRisk, PatternGroup.streakConsistency, 0.9),
        ],
        context: const InsightMappingContext(
          scopeType: InsightScopeType.entity,
          scopeId: 'e1',
          sourceWindowStartDateKey: '2026-05-01',
          sourceWindowEndDateKey: '2026-05-07',
          detectedAtMs: 42,
        ),
      ).first;

      final map = original.toMap();
      final restored = GeneratedInsight.fromMap(map);

      expect(restored.supportingMetrics, equals(original.supportingMetrics));
      expect(restored.lifecycleState, equals(original.lifecycleState));
      expect(restored.urgency, closeTo(original.urgency, 0.001));
      expect(restored.coachingImportance, closeTo(original.coachingImportance, 0.001));
    });
  });

  group('Phase 3 — determinism', () {
    test('same patterns always produce same insights in same order', () {
      final patterns = <DetectedPattern>[
        _p(PatternCode.streakRisk, PatternGroup.streakConsistency, 0.9),
        _p(PatternCode.lateBehavior, PatternGroup.timeBehavior, 0.7),
      ];
      const context = InsightMappingContext(
        scopeType: InsightScopeType.entity,
        scopeId: 'entity-1',
        sourceWindowStartDateKey: '2026-05-01',
        sourceWindowEndDateKey: '2026-05-07',
        detectedAtMs: 1000,
      );

      final first = mapPatternsToInsights(patterns: patterns, context: context);
      final second = mapPatternsToInsights(patterns: patterns, context: context);

      expect(first.length, equals(second.length));
      for (var i = 0; i < first.length; i++) {
        expect(first[i].insightId, equals(second[i].insightId));
        expect(first[i].insightType, equals(second[i].insightType));
        expect(first[i].urgency, closeTo(second[i].urgency, 0.0001));
        expect(first[i].coachingImportance, closeTo(second[i].coachingImportance, 0.0001));
      }
    });

    test('high priority insight sorts before low priority', () {
      final insights = mapPatternsToInsights(
        patterns: <DetectedPattern>[
          _p(PatternCode.strongStreak, PatternGroup.streakConsistency, 0.9),
          _p(PatternCode.streakRisk, PatternGroup.streakConsistency, 0.9),
          _p(PatternCode.lowEngagement, PatternGroup.effortDifficulty, 0.9),
        ],
        context: const InsightMappingContext(
          scopeType: InsightScopeType.entity,
          scopeId: 'e1',
          sourceWindowStartDateKey: '2026-05-01',
          sourceWindowEndDateKey: '2026-05-07',
        ),
      );

      // First insight should be high-priority (streakRisk → streakRiskWarning)
      expect(insights.first.priority, equals(InsightPriority.high));
    });
  });

  group('Phase 3 — focus-oriented rules', () {
    test('highestMomentumLeverage fires for strongStreak entity without streakRisk', () {
      final insights = mapPatternsToInsights(
        patterns: <DetectedPattern>[
          _p(PatternCode.strongStreak, PatternGroup.streakConsistency, 0.9),
        ],
        context: const InsightMappingContext(
          scopeType: InsightScopeType.entity,
          scopeId: 'habit-best',
          sourceWindowStartDateKey: '2026-05-01',
          sourceWindowEndDateKey: '2026-05-07',
        ),
      );

      expect(
        insights.any((i) => i.insightType == InsightType.highestMomentumLeverage),
        isTrue,
      );
    });

    test('fragileStreakAlert fires for streakRisk entity without strongStreak', () {
      final insights = mapPatternsToInsights(
        patterns: <DetectedPattern>[
          _p(PatternCode.streakRisk, PatternGroup.streakConsistency, 0.85),
        ],
        context: const InsightMappingContext(
          scopeType: InsightScopeType.entity,
          scopeId: 'habit-fragile',
          sourceWindowStartDateKey: '2026-05-01',
          sourceWindowEndDateKey: '2026-05-07',
        ),
      );

      expect(
        insights.any((i) => i.insightType == InsightType.fragileStreakAlert),
        isTrue,
      );
    });

    test('fragileStreakAlert is blocked when strongStreak is also present', () {
      final insights = mapPatternsToInsights(
        patterns: <DetectedPattern>[
          _p(PatternCode.streakRisk, PatternGroup.streakConsistency, 0.85),
          _p(PatternCode.strongStreak, PatternGroup.streakConsistency, 0.9),
        ],
        context: const InsightMappingContext(
          scopeType: InsightScopeType.entity,
          scopeId: 'habit-mixed',
          sourceWindowStartDateKey: '2026-05-01',
          sourceWindowEndDateKey: '2026-05-07',
        ),
      );

      expect(
        insights.any((i) => i.insightType == InsightType.fragileStreakAlert),
        isFalse,
      );
    });

    test('bestRecoveryOpportunity fires for inconsistentBehavior without streakRisk or tooHard', () {
      final insights = mapPatternsToInsights(
        patterns: <DetectedPattern>[
          _p(PatternCode.inconsistentBehavior, PatternGroup.streakConsistency, 0.7),
        ],
        context: const InsightMappingContext(
          scopeType: InsightScopeType.entity,
          scopeId: 'habit-recover',
          sourceWindowStartDateKey: '2026-05-01',
          sourceWindowEndDateKey: '2026-05-07',
        ),
      );

      expect(
        insights.any((i) => i.insightType == InsightType.bestRecoveryOpportunity),
        isTrue,
      );
    });
  });

  group('Phase 3 — global coaching summaries', () {
    test('overloadTrend fires for global scope with streakRisk + tooHard', () {
      final insights = mapPatternsToInsights(
        patterns: <DetectedPattern>[
          _pg(PatternCode.streakRisk, PatternGroup.streakConsistency, 0.9),
          _pg(PatternCode.tooHard, PatternGroup.effortDifficulty, 0.8),
        ],
        context: const InsightMappingContext(
          scopeType: InsightScopeType.global,
          scopeId: '2026-05-07',
          sourceWindowStartDateKey: '2026-05-07',
          sourceWindowEndDateKey: '2026-05-07',
        ),
      );

      expect(
        insights.any((i) => i.insightType == InsightType.overloadTrend),
        isTrue,
      );
    });

    test('improvingConsistency fires for global scope with strongStreak but no streakRisk', () {
      final insights = mapPatternsToInsights(
        patterns: <DetectedPattern>[
          _pg(PatternCode.strongStreak, PatternGroup.streakConsistency, 0.9),
        ],
        context: const InsightMappingContext(
          scopeType: InsightScopeType.global,
          scopeId: '2026-05-07',
          sourceWindowStartDateKey: '2026-05-07',
          sourceWindowEndDateKey: '2026-05-07',
        ),
      );

      expect(
        insights.any((i) => i.insightType == InsightType.improvingConsistency),
        isTrue,
      );
    });

    test('improvingConsistency is blocked when streakRisk is also present in global scope', () {
      final insights = mapPatternsToInsights(
        patterns: <DetectedPattern>[
          _pg(PatternCode.strongStreak, PatternGroup.streakConsistency, 0.9),
          _pg(PatternCode.streakRisk, PatternGroup.streakConsistency, 0.8),
        ],
        context: const InsightMappingContext(
          scopeType: InsightScopeType.global,
          scopeId: '2026-05-07',
          sourceWindowStartDateKey: '2026-05-07',
          sourceWindowEndDateKey: '2026-05-07',
        ),
      );

      expect(
        insights.any((i) => i.insightType == InsightType.improvingConsistency),
        isFalse,
      );
    });

    test('global insights have correct scopeType', () {
      final insights = mapPatternsToInsights(
        patterns: <DetectedPattern>[
          _pg(PatternCode.streakRisk, PatternGroup.streakConsistency, 0.9),
          _pg(PatternCode.tooHard, PatternGroup.effortDifficulty, 0.8),
        ],
        context: const InsightMappingContext(
          scopeType: InsightScopeType.global,
          scopeId: '2026-05-07',
          sourceWindowStartDateKey: '2026-05-07',
          sourceWindowEndDateKey: '2026-05-07',
        ),
      );

      expect(
        insights.every((i) => i.scopeType == InsightScopeType.global),
        isTrue,
      );
    });
  });

  group('Phase 3 — InsightLifecycleState storage', () {
    test('roundtrips all states through storage', () {
      for (final state in InsightLifecycleState.values) {
        expect(insightLifecycleStateFromStorage(state.name), equals(state));
      }
    });

    test('unknown state defaults to active', () {
      expect(
        insightLifecycleStateFromStorage('nonexistent'),
        equals(InsightLifecycleState.active),
      );
      expect(
        insightLifecycleStateFromStorage(null),
        equals(InsightLifecycleState.active),
      );
    });
  });

  group('Phase 3 — GeneratedInsight schema v2 round-trip', () {
    test('toMap/fromMap preserves all Phase 3 fields', () {
      const original = GeneratedInsight(
        insightId: 'entity::e1::streakRiskWarning::2026-05-07',
        scopeType: InsightScopeType.entity,
        scopeId: 'e1',
        insightType: InsightType.streakRiskWarning,
        insightBucket: InsightBucket.risk,
        priority: InsightPriority.high,
        messageKey: 'streak_risk_1',
        message: 'test msg',
        action: InsightAction.doNow,
        linkedPatternCodes: ['streakRisk'],
        confidence: 0.9,
        detectedAtMs: 1000,
        sourceWindowStartDateKey: '2026-05-01',
        sourceWindowEndDateKey: '2026-05-07',
        lifecycleState: InsightLifecycleState.reinforced,
        urgency: 0.72,
        coachingImportance: 0.81,
        supportingMetrics: {'streakRisk.severity': 0.8, 'streakRisk.confidence': 0.9},
      );

      final restored = GeneratedInsight.fromMap(original.toMap());

      expect(restored.lifecycleState, InsightLifecycleState.reinforced);
      expect(restored.urgency, closeTo(0.72, 0.001));
      expect(restored.coachingImportance, closeTo(0.81, 0.001));
      expect(
        restored.supportingMetrics['streakRisk.confidence'],
        closeTo(0.9, 0.001),
      );
    });

    test('fromMap with v1 data (no lifecycleState) defaults gracefully', () {
      final v1Map = <String, dynamic>{
        'insightId': 'entity::e1::latePattern::2026-05-07',
        'scopeType': 'entity',
        'scopeId': 'e1',
        'insightType': 'latePattern',
        'insightBucket': 'neutral',
        'priority': 'medium',
        'messageKey': 'late_1',
        'message': 'old msg',
        'action': 'reschedule',
        'linkedPatternCodes': ['lateBehavior'],
        'confidence': 0.7,
        'detectedAtMs': 1000,
        'sourceWindowStartDateKey': '2026-05-01',
        'sourceWindowEndDateKey': '2026-05-07',
        'metadata': <String, dynamic>{},
        'schemaVersion': 1,
      };

      final insight = GeneratedInsight.fromMap(v1Map);
      expect(insight.lifecycleState, InsightLifecycleState.active);
      expect(insight.urgency, closeTo(0.0, 0.001));
      expect(insight.coachingImportance, closeTo(0.0, 0.001));
      expect(insight.supportingMetrics, isEmpty);
    });
  });
}

DetectedPattern _p(PatternCode code, PatternGroup group, double confidence) {
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

DetectedPattern _pg(PatternCode code, PatternGroup group, double confidence) {
  return DetectedPattern(
    entityId: 'global',
    entityKind: BehaviorEntityKind.task,
    patternCode: code,
    patternGroup: group,
    severity: 0.8,
    confidence: confidence,
    detectedAtMs: 1,
    sourceWindowStartDateKey: '2026-05-07',
    sourceWindowEndDateKey: '2026-05-07',
  );
}
