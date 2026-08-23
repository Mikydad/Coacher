import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sidepal/core/utils/date_keys.dart';
import 'package:sidepal/features/goals/application/goals_providers.dart';
import 'package:sidepal/features/goals/domain/models/goal_check_in.dart';
import 'package:sidepal/features/goals/domain/models/goal_enums.dart';
import 'package:sidepal/features/goals/domain/models/user_goal.dart';
import 'package:sidepal/features/planning/application/planned_task_providers.dart';
import 'package:sidepal/features/profile/application/profile_hero_stats.dart';

/// The week window is Monday → today (the app's anchor, see
/// GoalPeriodHelpers), and a goal counts once per day it was actually DUE —
/// so an every-other-day goal is never punished for its off-days.
UserGoal _goal({
  required String id,
  GoalRepeatCadence cadence = GoalRepeatCadence.off,
  int interval = 1,
  List<int>? weekdays,
  DateTime? periodStart,
}) {
  final start = periodStart ?? DateTime(2020, 1, 1);
  return UserGoal(
    id: id,
    title: id,
    categoryId: 'productivity',
    status: GoalStatus.active,
    measurementKind: MeasurementKind.count,
    targetValue: 1,
    intensity: 3,
    periodStartMs: start.millisecondsSinceEpoch,
    periodEndMs: DateTime(2030, 1, 1).millisecondsSinceEpoch,
    repeatCadence: cadence,
    repeatInterval: interval,
    scheduledWeekdays: weekdays,
    createdAtMs: 0,
    updatedAtMs: 0,
  );
}

GoalCheckIn _met(String goalId, DateTime day) => GoalCheckIn(
  goalId: goalId,
  dateKey: DateKeys.yyyymmdd(day),
  metCommitment: true,
  updatedAtMs: 0,
);

ProviderContainer _container({
  List<UserGoal> goals = const [],
  Map<String, List<GoalCheckIn>> checkIns = const {},
}) {
  final container = ProviderContainer(
    overrides: [
      // No tasks: this file is about the goal math.
      todayAllTasksRowsProvider.overrideWith((ref) => Stream.value(const [])),
      goalsStreamProvider.overrideWith((ref) => Stream.value(goals)),
      goalCheckInsStreamProvider.overrideWith(
        (ref, goalId) => Stream.value(checkIns[goalId] ?? const []),
      ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

/// Streams emit on a microtask, and the check-in streams are only subscribed
/// once the goals stream has produced a list — so let both levels settle
/// before reading the derived stats.
Future<ProfileHeroStats> _stats(ProviderContainer container) async {
  container.listen(profileHeroStatsProvider, (_, _) {});
  for (var i = 0; i < 3; i++) {
    await Future<void>.delayed(Duration.zero);
  }
  return container.read(profileHeroStatsProvider);
}

void main() {
  final today = DateTime.now();
  final monday = DateTime(
    today.year,
    today.month,
    today.day,
  ).subtract(Duration(days: today.weekday - 1));
  final daysElapsed = today.weekday; // Monday → today, inclusive.

  test('nothing scheduled reads as an em dash, never 0%', () async {
    final stats = await _stats(_container());
    expect(stats.goalsLabel, '—');
    expect(stats.tasksLabel, '—');
  });

  test('a daily goal counts every elapsed day of the week', () async {
    final goal = _goal(id: 'g1', cadence: GoalRepeatCadence.daily);
    final stats = await _stats(
      _container(
        goals: [goal],
        checkIns: {
          'g1': [_met('g1', monday)],
        },
      ),
    );

    expect(stats.goalDaysScheduled, daysElapsed);
    expect(stats.goalDaysMet, 1);
    expect(stats.goalsLabel, '${(100 / daysElapsed).round()}%');
  });

  test('off-days do not count against a goal', () async {
    // Scheduled only on today's weekday — one due day this week.
    final goal = _goal(
      id: 'g2',
      cadence: GoalRepeatCadence.weekly,
      weekdays: [today.weekday],
    );
    final stats = await _stats(
      _container(
        goals: [goal],
        checkIns: {
          'g2': [_met('g2', today)],
        },
      ),
    );

    expect(stats.goalDaysScheduled, 1);
    expect(stats.goalDaysMet, 1);
    expect(stats.goalsLabel, '100%');
  });

  test('paused goals are excluded', () async {
    final paused = _goal(
      id: 'g3',
      cadence: GoalRepeatCadence.daily,
    ).copyWith(status: GoalStatus.paused);
    final stats = await _stats(_container(goals: [paused]));
    expect(stats.goalDaysScheduled, 0);
    expect(stats.goalsLabel, '—');
  });

  test('days before the goal started are not counted', () async {
    // Starts today: only today is inside the period this week.
    final goal = _goal(
      id: 'g4',
      cadence: GoalRepeatCadence.daily,
      periodStart: DateTime(today.year, today.month, today.day),
    );
    final stats = await _stats(_container(goals: [goal]));
    expect(stats.goalDaysScheduled, 1);
  });
}
