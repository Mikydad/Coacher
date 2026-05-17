import 'package:coach_for_life/features/analytics/application/pattern_detection_engine.dart';
import 'package:coach_for_life/features/analytics/domain/models/behavior_feature_object.dart';
import 'package:coach_for_life/features/analytics/domain/models/detected_pattern.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/behavior_time_metrics_fixture.dart';

void main() {
  group('pattern_detection_engine', () {
    test('emits streak and time patterns deterministically', () {
      final feature = _feature(
        completionRate7d: 0.45,
        lateRate: 0.8,
        currentStreak: 0,
        missedLast2Days: true,
        missedCount7d: 3,
        bestTimeBlock: 'evening',
        avgSnoozeCount: 0.5,
      );
      final first = detectPatternsForFeature(
        feature: feature,
        context: const PatternDetectionContext(
          scheduledTimeBlock: 'morning',
          detectedAtMs: 123,
        ),
      );
      final second = detectPatternsForFeature(
        feature: feature,
        context: const PatternDetectionContext(
          scheduledTimeBlock: 'morning',
          detectedAtMs: 123,
        ),
      );

      expect(first.map((p) => p.patternCode), contains(PatternCode.streakRisk));
      expect(
        first.map((p) => p.patternCode),
        contains(PatternCode.inconsistentBehavior),
      );
      expect(
        first.map((p) => p.patternCode),
        contains(PatternCode.lateBehavior),
      );
      expect(
        first.map((p) => p.patternCode),
        contains(PatternCode.timeMisalignment),
      );
      expect(
        first.map((p) => p.patternCode).toList(),
        equals(second.map((p) => p.patternCode).toList()),
      );
      for (final p in first) {
        expect(p.severity, inInclusiveRange(0.0, 1.0));
        expect(p.confidence, inInclusiveRange(0.0, 1.0));
        expect(p.detectedAtMs, 123);
      }
    });

    test(
      'emits effort/difficulty patterns for low completion and high snooze',
      () {
        final feature = _feature(
          completionRate7d: 0.3,
          lateRate: 0.2,
          currentStreak: 1,
          missedLast2Days: false,
          missedCount7d: 2,
          bestTimeBlock: 'morning',
          avgSnoozeCount: 3.0,
        );
        final out = detectPatternsForFeature(
          feature: feature,
          context: const PatternDetectionContext(detectedAtMs: 1),
        );
        expect(out.map((p) => p.patternCode), contains(PatternCode.tooHard));
        expect(
          out.map((p) => p.patternCode),
          contains(PatternCode.lowEngagement),
        );
      },
    );

    test('emits strong streak when threshold reached', () {
      final feature = _feature(
        completionRate7d: 0.95,
        lateRate: 0.1,
        currentStreak: 9,
        missedLast2Days: false,
        missedCount7d: 0,
        bestTimeBlock: 'morning',
        avgSnoozeCount: 0.1,
      );
      final out = detectPatternsForFeature(
        feature: feature,
        context: const PatternDetectionContext(detectedAtMs: 1),
      );
      expect(out.map((p) => p.patternCode), contains(PatternCode.strongStreak));
      expect(
        out.map((p) => p.patternCode),
        isNot(contains(PatternCode.streakRisk)),
      );
    });

    test('metadata contains required window keys', () {
      final out = detectPatternsForFeature(
        feature: _feature(
          completionRate7d: 0.2,
          lateRate: 0.9,
          currentStreak: 0,
          missedLast2Days: true,
          missedCount7d: 4,
          bestTimeBlock: 'morning',
          avgSnoozeCount: 3.5,
        ),
        context: const PatternDetectionContext(detectedAtMs: 7),
      );
      expect(out, isNotEmpty);
      for (final p in out) {
        expect(p.sourceWindowStartDateKey, '2026-05-01');
        expect(p.sourceWindowEndDateKey, '2026-05-06');
      }
    });
  });
}

BehaviorFeatureObject _feature({
  required double completionRate7d,
  required double lateRate,
  required int currentStreak,
  required bool missedLast2Days,
  required int missedCount7d,
  required String bestTimeBlock,
  required double avgSnoozeCount,
}) {
  return BehaviorFeatureObject(
    entityId: 'entity-1',
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
      currentStreak: currentStreak,
      longestStreak: currentStreak,
      missedLast2Days: missedLast2Days,
      missedCount7d: missedCount7d,
    ),
    effortMetrics: BehaviorEffortMetrics(
      avgSnoozeCount: avgSnoozeCount,
      avgSessionDuration: 25,
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
