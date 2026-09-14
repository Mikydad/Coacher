import 'package:sidepal/features/analytics/application/feature_builder_assembler.dart';
import 'package:sidepal/features/analytics/application/feature_builder_input_adapters.dart';
import 'package:sidepal/features/analytics/application/feature_builder_metrics.dart';
import 'package:sidepal/features/analytics/domain/models/analytics_stats_cache.dart';
import 'package:sidepal/features/goals/domain/models/goal_check_in.dart';
import 'package:sidepal/features/goals/domain/models/goal_enums.dart';
import 'package:sidepal/features/goals/domain/models/user_goal.dart';
import 'package:sidepal/features/planning/application/planned_task_collect.dart';
import 'package:sidepal/features/planning/domain/models/task_item.dart';
import 'package:flutter_test/flutter_test.dart';

/// Layer 1 counts misses on **opportunity days** only (2026-09-15): a goal's
/// action days in its period, a task's planned days. Calendar days the entity
/// was never scheduled on are neither streak breaks nor misses.
void main() {
  // 2026-09-07 Mon … 2026-09-11 Fri; 09-12 Sat; 09-13 Sun; 09-14 Mon.
  const monToFri = {
    '2026-09-07',
    '2026-09-08',
    '2026-09-09',
    '2026-09-10',
    '2026-09-11',
  };

  group('computeFeatureStreakMetrics with opportunity days', () {
    test('a Mon–Fri entity is not "missed" over the weekend', () {
      final out = computeFeatureStreakMetrics(
        completionDateKeys: monToFri,
        nowLocal: DateTime(2026, 9, 13, 10), // Sunday
        opportunityDateKeys: monToFri,
      );
      expect(out.missedLast2Days, isFalse);
      expect(out.missedCount7d, 0);
      expect(out.currentStreak, 5);
      expect(out.longestStreak, 5);
    });

    test(
      'Monday morning after a weekend: calendar fires, schedule does not',
      () {
        final monday = DateTime(2026, 9, 14, 8);
        final legacy = computeFeatureStreakMetrics(
          completionDateKeys: monToFri,
          nowLocal: monday,
        );
        expect(legacy.missedLast2Days, isTrue, reason: 'Sat + Sun empty');
        final scheduled = computeFeatureStreakMetrics(
          completionDateKeys: monToFri,
          nowLocal: monday,
          opportunityDateKeys: {...monToFri, '2026-09-14'},
        );
        expect(scheduled.missedLast2Days, isFalse, reason: 'Thu + Fri done');
        expect(scheduled.currentStreak, 0, reason: 'today not done yet');
        expect(scheduled.missedCount7d, 1, reason: 'only today, so far');
      },
    );

    test('missing the last two scheduled days fires on the next day', () {
      // Mon/Wed/Fri goal, did Mon, skipped Wed + Fri, evaluated Saturday.
      const monWedFri = {'2026-09-07', '2026-09-09', '2026-09-11'};
      final out = computeFeatureStreakMetrics(
        completionDateKeys: const {'2026-09-07'},
        nowLocal: DateTime(2026, 9, 12, 10), // Saturday
        opportunityDateKeys: monWedFri,
      );
      expect(out.missedLast2Days, isTrue);
      expect(out.missedCount7d, 2);
      expect(out.currentStreak, 0);
      expect(out.longestStreak, 1);
    });

    test('fewer than two prior opportunities is no evidence', () {
      // Task first planned today.
      final out = computeFeatureStreakMetrics(
        completionDateKeys: const {},
        nowLocal: DateTime(2026, 9, 13, 10),
        opportunityDateKeys: const {'2026-09-13'},
      );
      expect(out.missedLast2Days, isFalse);
      expect(out.missedCount7d, 1, reason: 'today is not done yet');
    });

    test('future planned days are neither hits nor misses', () {
      final out = computeFeatureStreakMetrics(
        completionDateKeys: const {'2026-09-12', '2026-09-13'},
        nowLocal: DateTime(2026, 9, 13, 10),
        opportunityDateKeys: const {'2026-09-12', '2026-09-13', '2026-09-14'},
      );
      expect(out.currentStreak, 2);
      expect(out.missedCount7d, 0);
    });
  });

  group('FeatureBuilderAssembler opportunity days', () {
    final window = _window(
      from: DateTime(2026, 8, 15),
      to: DateTime(2026, 9, 13),
    );

    test('Mon–Fri goal evaluated on Sunday: five chances, none missed', () {
      final goal = _goal(
        id: 'g-weekdays',
        cadence: GoalRepeatCadence.weekly,
        weekdays: const [1, 2, 3, 4, 5],
      );
      final bundle = FeatureBuilderInputBundle(
        window: window,
        eventHistoryByEntityId: const {},
        taskSeedsById: const {},
        goalSeedsById: {
          goal.id: GoalFeatureSeed(
            goal: goal,
            entityKind: 'goal',
            checkIns: [
              for (final k in monToFri)
                GoalCheckIn(
                  goalId: goal.id,
                  dateKey: k,
                  metCommitment: true,
                  updatedAtMs: 1,
                ),
            ],
            completedMilestones: 0,
            totalMilestones: 0,
          ),
        },
        statsCache: const <AnalyticsStatsCache>[],
      );
      final out = const FeatureBuilderAssembler().assemble(
        inputs: bundle,
        now: DateTime(2026, 9, 13, 10), // Sunday
      );
      final f = out.featuresByEntityId['g-weekdays']!;
      expect(f.timeMetrics.scheduledOccurrences7d, 5);
      expect(f.timeMetrics.missedScheduledCount7d, 0);
      expect(f.timeMetrics.completionRate7d, 1.0);
      expect(f.streakMetrics.missedLast2Days, isFalse);
      expect(f.streakMetrics.missedCount7d, 0);
      expect(f.streakMetrics.currentStreak, 5);
    });

    test('passive goal keeps one opportunity, misses clamp to the period', () {
      final goal = _goal(
        id: 'g-passive',
        cadence: GoalRepeatCadence.off,
        periodStart: DateTime(2026, 9, 11), // Fri — 3 days in window so far
      );
      final bundle = FeatureBuilderInputBundle(
        window: window,
        eventHistoryByEntityId: const {},
        taskSeedsById: const {},
        goalSeedsById: {
          goal.id: GoalFeatureSeed(
            goal: goal,
            entityKind: 'goal',
            checkIns: const [],
            completedMilestones: 0,
            totalMilestones: 0,
          ),
        },
        statsCache: const <AnalyticsStatsCache>[],
      );
      final out = const FeatureBuilderAssembler().assemble(
        inputs: bundle,
        now: DateTime(2026, 9, 13, 10),
      );
      final f = out.featuresByEntityId['g-passive']!;
      expect(f.timeMetrics.scheduledOccurrences7d, 1);
      expect(f.timeMetrics.scheduledOccurrences30d, 1);
      expect(f.streakMetrics.missedLast2Days, isTrue, reason: 'Fri + Sat');
      expect(f.streakMetrics.missedCount7d, 3, reason: 'Fri, Sat, Sun only');
    });

    test('a task first planned today has not missed the last two days', () {
      final task = _task(id: 't-new');
      final bundle = FeatureBuilderInputBundle(
        window: window,
        eventHistoryByEntityId: const {},
        taskSeedsById: {
          task.id: TaskFeatureSeed(
            row: PlannedTaskRow(
              dateKey: '2026-09-13',
              routineId: 'r',
              blockId: 'b',
              task: task,
            ),
            entityKind: 'task',
            scheduledDateKey: '2026-09-13',
            scheduledDateKeysInWindow: const {'2026-09-13'},
          ),
        },
        goalSeedsById: const {},
        statsCache: const <AnalyticsStatsCache>[],
      );
      final out = const FeatureBuilderAssembler().assemble(
        inputs: bundle,
        now: DateTime(2026, 9, 13, 8),
      );
      final f = out.featuresByEntityId['t-new']!;
      expect(f.streakMetrics.missedLast2Days, isFalse);
      expect(f.streakMetrics.missedCount7d, 1);
    });
  });
}

FeatureBuilderDateWindow _window({
  required DateTime from,
  required DateTime to,
}) {
  final keys = <String>[];
  for (var d = from; !d.isAfter(to); d = d.add(const Duration(days: 1))) {
    keys.add(
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}',
    );
  }
  return FeatureBuilderDateWindow(
    startDateKey: keys.first,
    endDateKey: keys.last,
    dateKeys: keys,
  );
}

UserGoal _goal({
  required String id,
  required GoalRepeatCadence cadence,
  List<int>? weekdays,
  DateTime? periodStart,
}) {
  return UserGoal(
    id: id,
    title: 'Goal',
    categoryId: 'study',
    repeatCadence: cadence,
    scheduledWeekdays: weekdays,
    status: GoalStatus.active,
    measurementKind: MeasurementKind.sessions,
    targetValue: 1,
    intensity: 3,
    periodStartMs: (periodStart ?? DateTime(2026, 8, 1)).millisecondsSinceEpoch,
    periodEndMs: DateTime(2026, 10, 31).millisecondsSinceEpoch,
    createdAtMs: 0,
    updatedAtMs: 0,
  );
}

PlannedTask _task({required String id}) {
  return PlannedTask(
    id: id,
    routineId: 'r',
    blockId: 'b',
    title: 'Task',
    durationMinutes: 25,
    priority: 2,
    orderIndex: 0,
    reminderEnabled: true,
    reminderTimeIso: '2026-09-13T09:00:00',
    status: TaskStatus.notStarted,
    createdAtMs: 0,
    updatedAtMs: 0,
  );
}
