import 'package:sidepal/features/analytics/application/pattern_detection_pipeline.dart';
import 'package:sidepal/features/analytics/application/pattern_detection_engine.dart';
import 'package:sidepal/features/analytics/domain/models/behavior_feature_object.dart';
import 'package:sidepal/features/analytics/domain/models/detected_pattern.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/behavior_time_metrics_fixture.dart';

void main() {
  group('pattern_detection_pipeline', () {
    test('returns deterministic ordered outputs with diagnostics', () {
      final feature = _feature(
        entityId: 'entity-1',
        completionRate7d: 0.35,
        lateRate: 0.75,
        missedLast2Days: true,
        missedCount7d: 3,
        avgSnoozeCount: 3.0,
        bestTimeBlock: 'evening',
      );
      final first = runPatternDetectionForEntity(
        feature: feature,
        context: const PatternDetectionContext(
          scheduledTimeBlock: 'morning',
          detectedAtMs: 111,
        ),
      );
      final second = runPatternDetectionForEntity(
        feature: feature,
        context: const PatternDetectionContext(
          scheduledTimeBlock: 'morning',
          detectedAtMs: 111,
        ),
      );

      expect(first.hasFatalError, false);
      expect(
        first.patterns.map((p) => p.patternCode).toList(),
        equals(second.patterns.map((p) => p.patternCode).toList()),
      );
      expect(
        first.diagnostics.where(
          (d) => d.status == RuleEvaluationStatus.triggered,
        ),
        isNotEmpty,
      );
    });

    test('handles malformed input safely with fatal diagnostic', () {
      final out = runPatternDetectionForEntity(
        feature: _feature(
          entityId: '',
          completionRate7d: 0.8,
          lateRate: 0.1,
          missedLast2Days: false,
          missedCount7d: 0,
          avgSnoozeCount: 0.1,
          bestTimeBlock: 'morning',
        ),
      );
      expect(out.hasFatalError, true);
      expect(out.patterns, isEmpty);
      expect(
        out.diagnostics.any((d) => d.status == RuleEvaluationStatus.error),
        true,
      );
    });

    test('reports all rules as skipped/triggered diagnostics', () {
      final out = runPatternDetectionForEntity(
        feature: _feature(
          entityId: 'entity-2',
          completionRate7d: 0.95,
          lateRate: 0.1,
          missedLast2Days: false,
          missedCount7d: 0,
          avgSnoozeCount: 0.1,
          bestTimeBlock: 'morning',
        ),
      );
      final ruleDiagnostics = out.diagnostics
          .where(
            (d) =>
                d.reason == 'rule_triggered' || d.reason == 'condition_not_met',
          )
          .toList();
      expect(ruleDiagnostics.length, kLayer2V1PatternCodes.length);
    });
  });
}

BehaviorFeatureObject _feature({
  required String entityId,
  required double completionRate7d,
  required double lateRate,
  required bool missedLast2Days,
  required int missedCount7d,
  required double avgSnoozeCount,
  required String bestTimeBlock,
}) {
  return BehaviorFeatureObject(
    entityId: entityId,
    entityKind: BehaviorEntityKind.habit,
    timeMetrics: testBehaviorTimeMetrics(
      scheduledOccurrences7d: 7,
      scheduledOccurrences30d: 30,
      completionRate7d: completionRate7d,
      completionRate30d: completionRate7d,
      lateCompletionRate7d: lateRate,
      lateCompletionRate30d: lateRate,
      avgCompletionDelayMinutes: 20,
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
