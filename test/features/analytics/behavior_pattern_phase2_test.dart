import 'package:sidepal/features/analytics/application/behavior_pattern_phase2.dart';
import 'package:sidepal/features/analytics/application/pattern_detection_engine.dart';
import 'package:sidepal/features/analytics/domain/models/behavior_feature_object.dart';
import 'package:sidepal/features/analytics/domain/models/detected_behavior_pattern.dart';
import 'package:sidepal/features/analytics/domain/models/detected_pattern.dart';
import 'package:sidepal/features/analytics/domain/models/pattern_taxonomy.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/behavior_time_metrics_fixture.dart';

void main() {
  group('behavior_pattern_phase2', () {
    test('taxonomy maps one spec per PatternCode', () {
      for (final code in PatternCode.values) {
        expect(
          kPatternTaxonomyByCode[code],
          isNotNull,
          reason: 'missing taxonomy for $code',
        );
      }
    });

    test('same input yields identical Phase 2 patterns', () {
      final f = _habitFeature(
        entityId: 'e1',
        completionRate7d: 0.35,
        lateRate: 0.75,
        missedLast2Days: true,
        missedCount7d: 3,
        avgSnoozeCount: 3,
        bestTimeBlock: 'evening',
      );
      const ctx = PatternDetectionContext(
        scheduledTimeBlock: 'morning',
        detectedAtMs: 999,
      );
      final a = detectBehaviorPatternsForFeature(feature: f, context: ctx);
      final b = detectBehaviorPatternsForFeature(feature: f, context: ctx);
      expect(a.length, b.length);
      for (var i = 0; i < a.length; i++) {
        expect(a[i].patternCode, b[i].patternCode);
        expect(a[i].severity, b[i].severity);
        expect(a[i].confidence, b[i].confidence);
        expect(a[i].evidence.length, b[i].evidence.length);
        for (var j = 0; j < a[i].evidence.length; j++) {
          expect(a[i].evidence[j].metricPath, b[i].evidence[j].metricPath);
          expect(a[i].evidence[j].valueSerialized, b[i].evidence[j].valueSerialized);
        }
      }
    });

    test('lateBehavior carries late metric evidence', () {
      final f = _habitFeature(
        entityId: 'late-1',
        completionRate7d: 0.9,
        lateRate: 0.95,
        missedLast2Days: false,
        missedCount7d: 0,
        avgSnoozeCount: 0.1,
        bestTimeBlock: 'morning',
        avgCompletionDelayMinutes: 45,
      );
      final patterns = detectBehaviorPatternsForFeature(feature: f);
      final late = patterns.where((p) => p.patternCode == PatternCode.lateBehavior);
      expect(late, isNotEmpty);
      final ev = late.first.evidence.map((e) => e.metricPath).toSet();
      expect(ev, contains('timeMetrics.lateCompletionRate7d'));
      expect(ev, contains('timeMetrics.avgCompletionDelayMinutes'));
    });

    test('scheduleRhythmVolatile suppressed when scheduled sample too small', () {
      final f = _habitFeature(
        entityId: 'sched-1',
        scheduledOccurrences7d: 3,
        missedScheduledCount7d: 3,
        completionRate7d: 0.0,
        lateRate: 0.0,
        missedLast2Days: false,
        missedCount7d: 0,
        avgSnoozeCount: 0.1,
        bestTimeBlock: 'morning',
      );
      final codes =
          detectBehaviorPatternsForFeature(feature: f).map((p) => p.patternCode).toSet();
      expect(codes, isNot(contains(PatternCode.scheduleRhythmVolatile)));
    });

    test('scheduleRhythmVolatile fires with enough scheduled days and high miss ratio',
        () {
      final f = _habitFeature(
        entityId: 'sched-2',
        scheduledOccurrences7d: 6,
        missedScheduledCount7d: 5,
        completionRate7d: 0.15,
        lateRate: 0.0,
        missedLast2Days: false,
        missedCount7d: 0,
        avgSnoozeCount: 0.1,
        bestTimeBlock: 'morning',
      );
      final codes =
          detectBehaviorPatternsForFeature(feature: f).map((p) => p.patternCode).toSet();
      expect(codes, contains(PatternCode.scheduleRhythmVolatile));
    });

    test('low sampleQuality reduces confidence vs high sampleQuality', () {
      final f = _habitFeature(
        entityId: 'conf-1',
        completionRate7d: 0.35,
        lateRate: 0.1,
        missedLast2Days: true,
        missedCount7d: 4,
        avgSnoozeCount: 0.1,
        bestTimeBlock: 'morning',
      );
      final low = detectBehaviorPatternsForFeature(
        feature: f,
        context: const PatternDetectionContext(sampleQuality: 0.15),
      );
      final high = detectBehaviorPatternsForFeature(
        feature: f,
        context: const PatternDetectionContext(sampleQuality: 1.0),
      );
      final lowRisk = low.firstWhere((p) => p.patternCode == PatternCode.streakRisk);
      final highRisk = high.firstWhere((p) => p.patternCode == PatternCode.streakRisk);
      expect(lowRisk.severity, closeTo(highRisk.severity, 0.0001));
      expect(lowRisk.confidence, lessThan(highRisk.confidence));
    });

    test('goalProgressDrift for goal entity when gap exceeds threshold', () {
      final f = BehaviorFeatureObject(
        entityId: 'goal-1',
        entityKind: BehaviorEntityKind.goal,
        timeMetrics: testBehaviorTimeMetrics(
          scheduledOccurrences7d: 0,
          completionRate7d: 0,
          flexCompletionFrequency7d: 0.1,
        ),
        streakMetrics: const BehaviorStreakMetrics(
          currentStreak: 0,
          longestStreak: 0,
          missedLast2Days: false,
          missedCount7d: 0,
        ),
        effortMetrics: const BehaviorEffortMetrics(
          avgSnoozeCount: 0,
          avgSessionDuration: 0,
          plannedVsActualRatio: 1,
        ),
        goalMetrics: const BehaviorGoalMetrics(
          progress: 0.2,
          expectedProgress: 0.6,
          gap: 0.45,
        ),
        contextFeatures: const BehaviorContextFeatures(
          bestTimeBlock: 'morning',
          isHabitAnchor: false,
          priority: 3,
        ),
        computedAtMs: 1,
        windowStartDateKey: '2026-05-01',
        windowEndDateKey: '2026-05-06',
      );
      final codes =
          detectBehaviorPatternsForFeature(feature: f).map((p) => p.patternCode).toSet();
      expect(codes, contains(PatternCode.goalProgressDrift));
    });

    test('global snapshot dedupes by entity+code keeping higher severity', () {
      final dupLow = DetectedBehaviorPattern(
        entityId: 'a',
        entityKind: BehaviorEntityKind.habit,
        patternCode: PatternCode.streakRisk,
        patternGroup: PatternGroup.streakConsistency,
        taxonomyFamily: PatternTaxonomyFamily.streakConsistency,
        severity: 0.4,
        confidence: 0.9,
        detectedAtMs: 1,
        sourceWindowStartDateKey: '2026-05-01',
        sourceWindowEndDateKey: '2026-05-06',
        evidence: const [],
      );
      final dupHigh = DetectedBehaviorPattern(
        entityId: 'a',
        entityKind: BehaviorEntityKind.habit,
        patternCode: PatternCode.streakRisk,
        patternGroup: PatternGroup.streakConsistency,
        taxonomyFamily: PatternTaxonomyFamily.streakConsistency,
        severity: 0.8,
        confidence: 0.5,
        detectedAtMs: 2,
        sourceWindowStartDateKey: '2026-05-01',
        sourceWindowEndDateKey: '2026-05-06',
        evidence: const [],
      );
      final result = buildGlobalBehaviorPatternSnapshot(
        dateKey: '2026-05-06',
        patterns: [dupLow, dupHigh],
        entitiesProcessed: 5,
        detectedAtMs: 100,
      );
      expect(result.snapshot.totalPatternsEmitted, 1);
      expect(result.snapshot.entries.single.occurrenceCount, 1);
      expect(result.snapshot.entries.single.maxSeverity, closeTo(0.8, 0.0001));
    });

    test('global snapshot aggregates multiple entities', () {
      DetectedBehaviorPattern row(String id, PatternCode code, double sev) {
        final group = code == PatternCode.lateBehavior
            ? PatternGroup.timeBehavior
            : PatternGroup.streakConsistency;
        return DetectedBehaviorPattern(
          entityId: id,
          entityKind: BehaviorEntityKind.task,
          patternCode: code,
          patternGroup: group,
          taxonomyFamily: patternTaxonomyFamilyForGroup(group),
          severity: sev,
          confidence: 0.7,
          detectedAtMs: 1,
          sourceWindowStartDateKey: '2026-05-01',
          sourceWindowEndDateKey: '2026-05-06',
          evidence: const [],
        );
      }

      final result = buildGlobalBehaviorPatternSnapshot(
        dateKey: '2026-05-06',
        patterns: [
          row('x', PatternCode.streakRisk, 0.5),
          row('y', PatternCode.streakRisk, 0.7),
        ],
        entitiesProcessed: 2,
        detectedAtMs: 200,
      );
      final entry =
          result.snapshot.entries.singleWhere((e) => e.patternCode == PatternCode.streakRisk);
      expect(entry.entityCount, 2);
      expect(entry.occurrenceCount, 2);
      expect(entry.averageSeverity, closeTo(0.6, 0.0001));
      expect(result.snapshot.weightedAverageSeverity, closeTo(0.6, 0.0001));
    });

    test('DetectedBehaviorPattern toMap is stable', () {
      final p = DetectedBehaviorPattern(
        entityId: 'z',
        entityKind: BehaviorEntityKind.habit,
        patternCode: PatternCode.timeMisalignment,
        patternGroup: PatternGroup.timeBehavior,
        taxonomyFamily: PatternTaxonomyFamily.timeBehavior,
        severity: 1.2,
        confidence: -0.1,
        detectedAtMs: 3,
        sourceWindowStartDateKey: '2026-05-01',
        sourceWindowEndDateKey: '2026-05-06',
        evidence: const [
          PatternMetricEvidence(metricPath: 'a', valueSerialized: 'b'),
        ],
      );
      final m = p.toMap();
      expect(m['severity'], 1.0);
      expect(m['confidence'], 0.0);
      expect(m['taxonomyFamily'], 'timeBehavior');
    });
  });
}

BehaviorFeatureObject _habitFeature({
  required String entityId,
  int scheduledOccurrences7d = 7,
  int missedScheduledCount7d = 0,
  required double completionRate7d,
  required double lateRate,
  required bool missedLast2Days,
  required int missedCount7d,
  required double avgSnoozeCount,
  required String bestTimeBlock,
  int avgCompletionDelayMinutes = 10,
}) {
  return BehaviorFeatureObject(
    entityId: entityId,
    entityKind: BehaviorEntityKind.habit,
    timeMetrics: testBehaviorTimeMetrics(
      scheduledOccurrences7d: scheduledOccurrences7d,
      missedScheduledCount7d: missedScheduledCount7d,
      completionRate7d: completionRate7d,
      completionRate30d: completionRate7d,
      lateCompletionRate7d: lateRate,
      lateCompletionRate30d: lateRate,
      avgCompletionDelayMinutes: avgCompletionDelayMinutes,
    ),
    streakMetrics: BehaviorStreakMetrics(
      currentStreak: missedLast2Days ? 0 : 8,
      longestStreak: 8,
      missedLast2Days: missedLast2Days,
      missedCount7d: missedCount7d,
    ),
    effortMetrics: BehaviorEffortMetrics(
      avgSnoozeCount: avgSnoozeCount,
      avgSessionDuration: 20,
      plannedVsActualRatio: 1.0,
    ),
    goalMetrics: const BehaviorGoalMetrics(
      progress: 0.5,
      expectedProgress: 0.5,
      gap: 0.0,
    ),
    contextFeatures: BehaviorContextFeatures(
      bestTimeBlock: bestTimeBlock,
      isHabitAnchor: true,
      priority: 2,
    ),
    computedAtMs: 1,
    windowStartDateKey: '2026-05-01',
    windowEndDateKey: '2026-05-06',
  );
}
