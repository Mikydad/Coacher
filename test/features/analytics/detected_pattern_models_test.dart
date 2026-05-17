import 'package:coach_for_life/features/analytics/domain/models/behavior_feature_object.dart';
import 'package:coach_for_life/features/analytics/domain/models/detected_pattern.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('detected_pattern models', () {
    test('DetectedPattern fromMap uses compatibility defaults', () {
      final pattern = DetectedPattern.fromMap(<String, dynamic>{
        'entityId': 'task-1',
        'entityKind': 'unknown',
        'patternCode': 'unknown',
        'patternGroup': 'unknown',
        'sourceWindowStartDateKey': '2026-05-01',
        'sourceWindowEndDateKey': '2026-05-06',
      });
      expect(pattern.entityKind, BehaviorEntityKind.task);
      expect(pattern.patternCode, PatternCode.streakRisk);
      expect(pattern.patternGroup, PatternGroup.streakConsistency);
      expect(pattern.severity, 0);
      expect(pattern.confidence, 0);
      expect(pattern.schemaVersion, kDetectedPatternSchemaVersion);
    });

    test('DetectedPattern toMap clamps scores', () {
      final pattern = DetectedPattern(
        entityId: 'habit-1',
        entityKind: BehaviorEntityKind.habit,
        patternCode: PatternCode.tooHard,
        patternGroup: PatternGroup.effortDifficulty,
        severity: 3.2,
        confidence: -1.3,
        detectedAtMs: 1,
        sourceWindowStartDateKey: '2026-05-01',
        sourceWindowEndDateKey: '2026-05-06',
      );
      final map = pattern.toMap();
      expect(map['severity'], 1.0);
      expect(map['confidence'], 0.0);
    });

    test('GlobalPatternSnapshot fromMap handles sparse payloads', () {
      final snapshot = GlobalPatternSnapshot.fromMap(<String, dynamic>{
        'dateKey': '2026-05-06',
      });
      expect(snapshot.dateKey, '2026-05-06');
      expect(snapshot.entries, isEmpty);
      expect(snapshot.totalEntitiesProcessed, 0);
      expect(snapshot.totalPatternsEmitted, 0);
      expect(snapshot.schemaVersion, kGlobalPatternSnapshotSchemaVersion);
    });

    test('Layer 2 V1 catalog contains expected pattern groups/codes', () {
      expect(kLayer2V1PatternGroups, contains(PatternGroup.streakConsistency));
      expect(kLayer2V1PatternGroups, contains(PatternGroup.timeBehavior));
      expect(kLayer2V1PatternGroups, contains(PatternGroup.effortDifficulty));
      expect(kLayer2V1PatternGroups, contains(PatternGroup.goalAlignment));
      expect(kLayer2V1PatternGroups, contains(PatternGroup.behavioralStability));
      expect(kLayer2V1PatternCodes, contains(PatternCode.streakRisk));
      expect(kLayer2V1PatternCodes, contains(PatternCode.timeMisalignment));
      expect(kLayer2V1PatternCodes, contains(PatternCode.lowEngagement));
      expect(kLayer2V1PatternCodes, contains(PatternCode.goalProgressDrift));
      expect(kLayer2V1PatternCodes, contains(PatternCode.scheduleRhythmVolatile));
    });
  });
}
