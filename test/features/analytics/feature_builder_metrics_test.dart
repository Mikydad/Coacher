import 'package:coach_for_life/features/analytics/application/feature_builder_metrics.dart';
import 'package:coach_for_life/features/analytics/domain/models/analytics_event.dart';
import 'package:coach_for_life/features/analytics/domain/models/behavior_feature_object.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('feature_builder_metrics', () {
    test('computeBehaviorTimeMetrics: adherence, missed, late, flex', () {
      const keys7d = {'2026-05-01', '2026-05-02', '2026-05-03', '2026-05-04', '2026-05-05', '2026-05-06'};
      const keys30d = keys7d;
      final scheduled = {'2026-05-05', '2026-05-06'};
      const completions = {'2026-05-05'};
      final timing = [
        CompletionTimingSample(
          completionDateKey: '2026-05-05',
          scheduledAtLocal: DateTime(2026, 5, 5, 8),
          completedAtLocal: DateTime(2026, 5, 5, 8, 30),
        ),
        CompletionTimingSample(
          completionDateKey: '2026-05-06',
          scheduledAtLocal: DateTime(2026, 5, 6, 8),
          completedAtLocal: DateTime(2026, 5, 6, 7, 50),
        ),
      ];
      final out = computeBehaviorTimeMetrics(
        keys7d: keys7d,
        keys30d: keys30d,
        scheduledDateKeysInFullWindow: scheduled,
        completionDateKeys: completions,
        timingSamples: timing,
        hasScheduledOccurrenceToday: false,
        scheduledInstantToday: null,
        completedToday: false,
        nowLocal: DateTime(2026, 5, 6, 12),
      );
      expect(out.scheduledOccurrences7d, 2);
      expect(out.missedScheduledCount7d, 1);
      expect(out.completionRate7d, 0.5);
      expect(out.flexCompletionFrequency7d, 1 / 7);
      expect(out.lateCompletionRate7d, 0.5);
      expect(out.avgCompletionDelayMinutes, 30);
    });

    test('computeBehaviorTimeMetrics: flex-only when no scheduled days', () {
      const keys7d = {'2026-05-04', '2026-05-05', '2026-05-06'};
      const keys30d = keys7d;
      final out = computeBehaviorTimeMetrics(
        keys7d: keys7d,
        keys30d: keys30d,
        scheduledDateKeysInFullWindow: const <String>{},
        completionDateKeys: const {'2026-05-05', '2026-05-06'},
        timingSamples: const [],
        hasScheduledOccurrenceToday: false,
        scheduledInstantToday: null,
        completedToday: false,
        nowLocal: DateTime(2026, 5, 6, 12),
      );
      expect(out.scheduledOccurrences7d, 0);
      expect(out.completionRate7d, 0);
      expect(out.flexCompletionFrequency7d, 2 / 7);
    });

    test('layer1CompletionSignal7d uses adherence when scheduled', () {
      final m = computeBehaviorTimeMetrics(
        keys7d: const {'2026-05-06'},
        keys30d: const {'2026-05-06'},
        scheduledDateKeysInFullWindow: const {'2026-05-06'},
        completionDateKeys: const {'2026-05-06'},
        timingSamples: const [],
        hasScheduledOccurrenceToday: true,
        scheduledInstantToday: DateTime(2026, 5, 6, 9),
        completedToday: true,
        nowLocal: DateTime(2026, 5, 6, 12),
      );
      expect(layer1CompletionSignal7d(m), 1.0);
    });

    test('layer1CompletionSignal7d uses flex density when unscheduled', () {
      const m = BehaviorTimeMetrics(
        scheduledOccurrences7d: 0,
        scheduledOccurrences30d: 0,
        missedScheduledCount7d: 0,
        missedScheduledCount30d: 0,
        completionRate7d: 0,
        completionRate30d: 0,
        flexCompletionFrequency7d: 3 / 7,
        flexCompletionFrequency30d: 0,
        lateCompletionRate7d: 0,
        lateCompletionRate30d: 0,
        avgCompletionDelayMinutes: 0,
        isCurrentlyOverdue: false,
        minutesOverdue: 0,
      );
      expect(layer1CompletionSignal7d(m), 1.0);
    });

    test('computeBehaviorTimeMetrics is identical on repeated calls', () {
      const keys7d = {'2026-05-05', '2026-05-06'};
      const keys30d = keys7d;
      final a = computeBehaviorTimeMetrics(
        keys7d: keys7d,
        keys30d: keys30d,
        scheduledDateKeysInFullWindow: const {'2026-05-06'},
        completionDateKeys: const {},
        timingSamples: const [],
        hasScheduledOccurrenceToday: true,
        scheduledInstantToday: DateTime(2026, 5, 6, 9),
        completedToday: false,
        nowLocal: DateTime(2026, 5, 6, 15),
      );
      final b = computeBehaviorTimeMetrics(
        keys7d: keys7d,
        keys30d: keys30d,
        scheduledDateKeysInFullWindow: const {'2026-05-06'},
        completionDateKeys: const {},
        timingSamples: const [],
        hasScheduledOccurrenceToday: true,
        scheduledInstantToday: DateTime(2026, 5, 6, 9),
        completedToday: false,
        nowLocal: DateTime(2026, 5, 6, 15),
      );
      expect(a.toMap(), b.toMap());
    });

    test('timezone boundary: local day keys only', () {
      final nowLocal = DateTime(2026, 5, 10, 10, 30);
      const keys7d = {'2026-05-04', '2026-05-05', '2026-05-06', '2026-05-07', '2026-05-08', '2026-05-09', '2026-05-10'};
      final out = computeBehaviorTimeMetrics(
        keys7d: keys7d,
        keys30d: keys7d,
        scheduledDateKeysInFullWindow: const {'2026-05-10'},
        completionDateKeys: const {},
        timingSamples: const [],
        hasScheduledOccurrenceToday: true,
        scheduledInstantToday: DateTime(2026, 5, 10, 9),
        completedToday: false,
        nowLocal: nowLocal,
      );
      expect(out.isCurrentlyOverdue, true);
      expect(out.minutesOverdue, greaterThan(0));
    });

    test('computeFeatureStreakMetrics unchanged contract', () {
      final out = computeFeatureStreakMetrics(
        completionDateKeys: const {
          '2026-05-01',
          '2026-05-03',
          '2026-05-04',
          '2026-05-05',
          '2026-05-06',
        },
        nowLocal: DateTime(2026, 5, 6, 12),
      );
      expect(out.currentStreak, 4);
      expect(out.longestStreak, 4);
      expect(out.missedLast2Days, false);
      expect(out.missedCount7d, 2);
    });

    test('computeGoalBehaviorTimeMetrics missed vs opportunities', () {
      const keys7d = {'2026-05-01', '2026-05-02', '2026-05-03', '2026-05-04', '2026-05-05', '2026-05-06', '2026-05-07'};
      const keys30d = keys7d;
      final out = computeGoalBehaviorTimeMetrics(
        keys7d: keys7d,
        keys30d: keys30d,
        completionDateKeys: const {'2026-05-06'},
        scheduledOpportunities7d: 7,
        scheduledOpportunities30d: 7,
      );
      expect(out.missedScheduledCount7d, 6);
      expect(out.completionRate7d, closeTo(1 / 7, 0.0001));
    });

    test('computeFeatureEffortMetrics from sessions and defer events', () {
      final out = computeFeatureEffortMetrics(
        sessions: const [
          SessionEffortSample(
            plannedMinutes: 30,
            actualMinutes: 20,
            snoozeCount: 1,
          ),
          SessionEffortSample(
            plannedMinutes: 20,
            actualMinutes: 30,
            snoozeCount: 2,
          ),
        ],
        deferredEventCount: 3,
      );
      expect(out.avgSessionDuration, 25);
      expect(out.avgSnoozeCount, 3);
      expect(out.plannedVsActualRatio, closeTo(1.0, 0.0001));
    });

    test('computeFeatureGoalMetrics and context', () {
      final goal = computeFeatureGoalMetrics(
        progress: 0.4,
        expectedProgress: 0.8,
      );
      expect(goal.gap, 0.4);

      final context = computeFeatureContext(
        completionEvents: [
          _event(id: '1', iso: '2026-05-06T06:00:00'),
          _event(id: '2', iso: '2026-05-06T18:00:00'),
          _event(id: '3', iso: '2026-05-06T06:30:00'),
        ],
        isHabitAnchor: false,
        priority: 2,
      );
      expect(context.bestTimeBlock, 'morning');
      expect(context.priority, 2);
    });
  });
}

AnalyticsEvent _event({required String id, required String iso}) {
  return AnalyticsEvent(
    id: id,
    type: AnalyticsEventType.taskCompleted,
    entityId: 'e',
    entityKind: 'task',
    dateKey: '2026-05-06',
    timestampLocalIso: iso,
    sourceSurface: 'test',
    idempotencyKey: id,
    createdAtMs: 1,
    updatedAtMs: 1,
  );
}
