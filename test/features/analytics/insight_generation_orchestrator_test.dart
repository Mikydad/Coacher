import 'package:coach_for_life/features/analytics/application/insight_generation_orchestrator.dart';
import 'package:coach_for_life/features/analytics/domain/models/behavior_feature_object.dart';
import 'package:coach_for_life/features/analytics/domain/models/detected_pattern.dart';
import 'package:coach_for_life/features/analytics/domain/models/generated_insight.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('insight_generation_orchestrator', () {
    const orchestrator = InsightGenerationOrchestrator();

    test('runForEntity produces deterministic insights from entity patterns', () {
      final result = orchestrator.runForEntity(
        entityId: 'task-1',
        patterns: <DetectedPattern>[
          _pattern(PatternCode.streakRisk, PatternGroup.streakConsistency),
          _pattern(PatternCode.lateBehavior, PatternGroup.timeBehavior),
        ],
        featureContext: const Layer3FeatureContext(
          currentStreak: 2,
          completionRate7d: 0.4,
          entityLabel: 'Workout',
        ),
        now: DateTime(2026, 5, 7, 10),
      );

      expect(result.hasFatalError, false);
      expect(result.insights, isNotEmpty);
      expect(result.insights.first.scopeType, InsightScopeType.entity);
      expect(result.insights.first.metadata['featureContext'], isNotNull);
      expect(result.postProcessDiagnostics, isNotNull);
    });

    test('runForGlobalDay produces global-scope insights', () {
      final result = orchestrator.runForGlobalDay(
        dateKey: '2026-05-07',
        patterns: <DetectedPattern>[
          _pattern(PatternCode.streakRisk, PatternGroup.streakConsistency),
          _pattern(PatternCode.tooHard, PatternGroup.effortDifficulty),
          _pattern(PatternCode.lowEngagement, PatternGroup.effortDifficulty),
        ],
        now: DateTime(2026, 5, 7, 10),
      );

      expect(result.hasFatalError, false);
      expect(result.dateKey, '2026-05-07');
      expect(
        result.insights.every((insight) => insight.scopeType == InsightScopeType.global),
        isTrue,
      );
      expect(result.postProcessDiagnostics, isNotNull);
    });

    test('handles malformed entity input safely', () {
      final missingEntity = orchestrator.runForEntity(
        entityId: ' ',
        patterns: <DetectedPattern>[],
      );
      expect(missingEntity.hasFatalError, true);
      expect(missingEntity.insights, isEmpty);

      final missingWindow = orchestrator.runForEntity(
        entityId: 'task-1',
        patterns: <DetectedPattern>[
          _pattern(
            PatternCode.streakRisk,
            PatternGroup.streakConsistency,
            start: '',
            end: '',
          ),
        ],
      );
      expect(missingWindow.hasFatalError, false);
      expect(missingWindow.insights, isEmpty);
      expect(missingWindow.diagnostics.first.code, 'source_window_missing');
    });

    test('runBatch returns metadata with counts and elapsed time', () {
      final result = orchestrator.runBatch(
        dateKey: '2026-05-07',
        entityPatternsById: <String, List<DetectedPattern>>{
          'a': <DetectedPattern>[
            _pattern(PatternCode.streakRisk, PatternGroup.streakConsistency),
          ],
          'b': <DetectedPattern>[
            _pattern(PatternCode.tooHard, PatternGroup.effortDifficulty),
          ],
        },
        globalPatterns: <DetectedPattern>[
          _pattern(PatternCode.streakRisk, PatternGroup.streakConsistency),
        ],
        contextByEntityId: const <String, Layer3FeatureContext>{
          'a': Layer3FeatureContext(currentStreak: 1),
        },
        now: DateTime(2026, 5, 7, 10),
      );

      expect(result.entityResults, hasLength(2));
      expect(result.globalResult.dateKey, '2026-05-07');
      expect(result.metadata.entitiesProcessed, 2);
      expect(result.metadata.totalInsightsEmitted, greaterThanOrEqualTo(1));
      expect(result.metadata.schemaVersion, kGeneratedInsightSchemaVersion);
      expect(result.metadata.elapsedMs, greaterThanOrEqualTo(0));
    });
  });
}

DetectedPattern _pattern(
  PatternCode code,
  PatternGroup group, {
  String start = '2026-05-01',
  String end = '2026-05-07',
}) {
  return DetectedPattern(
    entityId: 'entity',
    entityKind: BehaviorEntityKind.task,
    patternCode: code,
    patternGroup: group,
    severity: 0.8,
    confidence: 0.8,
    detectedAtMs: 1,
    sourceWindowStartDateKey: start,
    sourceWindowEndDateKey: end,
  );
}
