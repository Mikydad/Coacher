import 'package:flutter_test/flutter_test.dart';
import 'package:sidepal/features/analytics/application/blended_discipline.dart';
import 'package:sidepal/features/analytics/application/daily_analytics_engine.dart';
import 'package:sidepal/features/analytics/application/progress_period_series.dart';
import 'package:sidepal/features/analytics/domain/progress_period.dart';
import 'package:sidepal/features/coaching/domain/models/enforcement_mode.dart';

DailyAnalyticsSnapshot _snap(String key, double created, double completed) {
  return DailyAnalyticsSnapshot(
    dateKey: key,
    createdCount: created.round(),
    completedCount: completed.round(),
    weightedCreated: created,
    weightedCompleted: completed,
    completionRate: created == 0 ? 0 : completed / created,
    weightedCompletionRate: created == 0 ? 0 : completed / created,
    schemaVersion: 3,
  );
}

void main() {
  final now = DateTime(2026, 9, 12, 15);
  final week = ProgressPeriod.forDate(ProgressHorizon.week, now); // 7–13 Sep

  test('week series: one point per day, future days marked, rollups weighted', () {
    final goals = {
      '2026-09-07': _snap('2026-09-07', 2, 2),
      '2026-09-08': _snap('2026-09-08', 2, 1),
      '2026-09-10': _snap('2026-09-10', 2, 2),
      '2026-09-12': _snap('2026-09-12', 2, 2),
    };
    final tasks = {
      '2026-09-07': _snap('2026-09-07', 5, 5),
      '2026-09-08': _snap('2026-09-08', 5, 0),
      '2026-09-11': _snap('2026-09-11', 5, 5),
      '2026-09-12': _snap('2026-09-12', 5, 4),
    };
    final s = assembleProgressPeriodSeries(
      period: week,
      goalByKey: goals,
      taskByKey: tasks,
      protectedDateKeys: const {},
      mode: EnforcementMode.flexible, // 80%
      now: now,
      previousPeriodRate: 0.505,
      currentStreakFromToday: 9,
    );

    expect(s.days.length, 7);
    expect(s.days.map((d) => d.state).toList(), [
      RingState.qualified, // Mon 1.0
      RingState.partial, // Tue 0.6*0.5+0.4*0 = 0.3
      RingState.quiet, // Wed nothing
      RingState.qualified, // Thu goals only → 1.0
      RingState.qualified, // Fri tasks only → 1.0
      RingState.qualified, // Sat today: 0.6*1+0.4*0.8 = 0.92
      RingState.future, // Sun
    ]);
    expect(s.daysPlanned, 5);
    expect(s.daysMet, 4);
    expect(s.currentStreak, 9);
    expect(s.bestStreak, 3); // Thu Fri Sat
    expect(s.deltaPoints, isNotNull);
    expect(s.monthRates, isEmpty);

    // Weighted: goals 7/8, tasks 14/20
    expect(s.goalRate, closeTo(7 / 8, 1e-9));
    expect(s.taskRate, closeTo(14 / 20, 1e-9));
    expect(s.periodRate, closeTo(0.6 * 7 / 8 + 0.4 * 14 / 20, 1e-9));
    expect(s.deltaPoints, 30); // 0.805 − 0.505
  });

  test('a period without today has no current streak; empty period is quiet', () {
    final last = week.previous;
    final s = assembleProgressPeriodSeries(
      period: last,
      goalByKey: const {},
      taskByKey: const {},
      protectedDateKeys: const {},
      mode: EnforcementMode.flexible,
      now: now,
      currentStreakFromToday: 9,
    );
    expect(s.currentStreak, isNull);
    expect(s.periodRate, isNull);
    expect(s.deltaPoints, isNull);
    expect(s.days.every((d) => d.state == RingState.quiet), isTrue);
    expect(s.daysPlanned, 0);
  });

  test('quarter series carries one rate per month, null for quiet months', () {
    final q = ProgressPeriod.forDate(ProgressHorizon.quarter, now); // Jul–Sep
    final s = assembleProgressPeriodSeries(
      period: q,
      goalByKey: {'2026-08-03': _snap('2026-08-03', 4, 2)},
      taskByKey: {'2026-09-01': _snap('2026-09-01', 4, 4)},
      protectedDateKeys: const {},
      mode: EnforcementMode.flexible,
      now: now,
    );
    expect(s.days.length, 92);
    expect(s.monthRates.length, 3);
    expect(s.monthRates[0], isNull); // July
    expect(s.monthRates[1], 0.5); // August, goals only
    expect(s.monthRates[2], 1.0); // September, tasks only
  });

  test('protected day counts as bridging but not as met', () {
    final s = assembleProgressPeriodSeries(
      period: week,
      goalByKey: {
        '2026-09-10': _snap('2026-09-10', 1, 1),
        '2026-09-12': _snap('2026-09-12', 1, 1),
      },
      taskByKey: const {},
      protectedDateKeys: const {'2026-09-11'},
      mode: EnforcementMode.flexible,
      now: now,
    );
    expect(s.pointFor('2026-09-11')!.state, RingState.protected);
    expect(s.daysMet, 2);
    expect(s.bestStreak, 3);
  });
}
