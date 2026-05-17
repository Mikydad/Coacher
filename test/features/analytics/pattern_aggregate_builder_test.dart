import 'package:coach_for_life/features/analytics/application/pattern_aggregate_builder.dart';
import 'package:coach_for_life/features/analytics/domain/models/behavior_feature_object.dart';
import 'package:coach_for_life/features/analytics/domain/models/detected_pattern.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('pattern_aggregate_builder', () {
    test('aggregates per pattern code into deterministic global snapshot', () {
      final result = buildGlobalPatternSnapshot(
        dateKey: '2026-05-07',
        entitiesProcessed: 3,
        patterns: [
          _pattern(
            entityId: 'a',
            code: PatternCode.streakRisk,
            group: PatternGroup.streakConsistency,
            severity: 0.9,
            confidence: 0.8,
          ),
          _pattern(
            entityId: 'b',
            code: PatternCode.streakRisk,
            group: PatternGroup.streakConsistency,
            severity: 0.7,
            confidence: 0.9,
          ),
          _pattern(
            entityId: 'c',
            code: PatternCode.lateBehavior,
            group: PatternGroup.timeBehavior,
            severity: 0.6,
            confidence: 0.7,
          ),
        ],
        detectedAtMs: 123,
      );

      expect(result.snapshot.dateKey, '2026-05-07');
      expect(result.snapshot.entries.length, 2);
      expect(result.snapshot.totalEntitiesProcessed, 3);
      expect(result.snapshot.totalPatternsEmitted, 3);
      expect(result.metadata.patternsEmitted, 3);
      expect(
        result.metadata.schemaVersion,
        kGlobalPatternSnapshotSchemaVersion,
      );
    });

    test(
      'merges duplicate entity+pattern by highest severity then confidence',
      () {
        final result = buildGlobalPatternSnapshot(
          dateKey: '2026-05-07',
          entitiesProcessed: 1,
          patterns: [
            _pattern(
              entityId: 'a',
              code: PatternCode.lowEngagement,
              group: PatternGroup.effortDifficulty,
              severity: 0.6,
              confidence: 0.6,
            ),
            _pattern(
              entityId: 'a',
              code: PatternCode.lowEngagement,
              group: PatternGroup.effortDifficulty,
              severity: 0.8,
              confidence: 0.5,
            ),
            _pattern(
              entityId: 'a',
              code: PatternCode.lowEngagement,
              group: PatternGroup.effortDifficulty,
              severity: 0.8,
              confidence: 0.9,
            ),
          ],
        );

        expect(result.snapshot.totalPatternsEmitted, 1);
        expect(
          result.snapshot.entries.single.averageSeverity,
          closeTo(0.8, 0.0001),
        );
        expect(
          result.snapshot.entries.single.averageConfidence,
          closeTo(0.9, 0.0001),
        );
      },
    );

    test('computes weighted average severity from occurrence counts', () {
      final result = buildGlobalPatternSnapshot(
        dateKey: '2026-05-07',
        entitiesProcessed: 2,
        patterns: [
          _pattern(
            entityId: 'a',
            code: PatternCode.streakRisk,
            group: PatternGroup.streakConsistency,
            severity: 1.0,
            confidence: 1.0,
          ),
          _pattern(
            entityId: 'b',
            code: PatternCode.lateBehavior,
            group: PatternGroup.timeBehavior,
            severity: 0.5,
            confidence: 1.0,
          ),
        ],
      );
      expect(result.snapshot.weightedAverageSeverity, closeTo(0.75, 0.0001));
    });
  });
}

DetectedPattern _pattern({
  required String entityId,
  required PatternCode code,
  required PatternGroup group,
  required double severity,
  required double confidence,
}) {
  return DetectedPattern(
    entityId: entityId,
    entityKind: BehaviorEntityKind.habit,
    patternCode: code,
    patternGroup: group,
    severity: severity,
    confidence: confidence,
    detectedAtMs: 1,
    sourceWindowStartDateKey: '2026-05-01',
    sourceWindowEndDateKey: '2026-05-07',
  );
}
