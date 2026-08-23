import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_keys.dart';
import '../../goals/application/goal_period_helpers.dart';
import '../../goals/application/goals_providers.dart';
import '../../goals/domain/models/goal_enums.dart';
import '../../goals/domain/models/user_goal.dart';
import '../../planning/application/planned_task_providers.dart';
import '../../planning/domain/models/task_item.dart';

/// The two at-a-glance numbers beside the streak on Profile (2026-08-23):
/// today's task completion and this week's goal completion. Both are derived
/// from the same Isar watch streams the rest of the app reads, so they stay
/// live and work offline — nothing here touches the network.
class ProfileHeroStats {
  const ProfileHeroStats({
    required this.tasksDone,
    required this.tasksTotal,
    required this.goalDaysMet,
    required this.goalDaysScheduled,
  });

  const ProfileHeroStats.empty()
    : tasksDone = 0,
      tasksTotal = 0,
      goalDaysMet = 0,
      goalDaysScheduled = 0;

  final int tasksDone;
  final int tasksTotal;

  /// Goal-days met vs. scheduled since Monday — a goal counts once per day it
  /// was actually due, so an every-other-day goal isn't punished for its
  /// off-days.
  final int goalDaysMet;
  final int goalDaysScheduled;

  /// An em dash rather than "0/0": nothing planned is not a failure.
  String get tasksLabel => tasksTotal == 0 ? '—' : '$tasksDone/$tasksTotal';

  String get goalsLabel => goalDaysScheduled == 0
      ? '—'
      : '${(goalDaysMet * 100 / goalDaysScheduled).round()}%';
}

final profileHeroStatsProvider = Provider<ProfileHeroStats>((ref) {
  // ── Today's tasks ─────────────────────────────────────────────────────────
  final rows = ref.watch(todayAllTasksRowsProvider).valueOrNull;
  final tasksTotal = rows?.length ?? 0;
  final tasksDone =
      rows?.where((r) => r.task.status == TaskStatus.completed).length ?? 0;

  // ── This week's goals (Monday → today, the app's week anchor) ─────────────
  // NOT activeGoalsProvider: that applies the Goals tab's category filter, so
  // filtering there would silently change this number.
  final goals =
      (ref.watch(goalsStreamProvider).valueOrNull ?? const <UserGoal>[]).where(
        (g) => g.status == GoalStatus.active,
      );

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final monday = today.subtract(Duration(days: today.weekday - 1));

  var scheduled = 0;
  var met = 0;
  for (final goal in goals) {
    final checkIns =
        ref.watch(goalCheckInsStreamProvider(goal.id)).valueOrNull ?? const [];
    final metKeys = <String>{
      for (final c in checkIns)
        if (c.metCommitment) c.dateKey,
    };
    for (
      var day = monday;
      !day.isAfter(today);
      day = day.add(const Duration(days: 1))
    ) {
      final key = DateKeys.yyyymmdd(day);
      if (!GoalPeriodHelpers.isDateKeyInPeriod(goal, key)) continue;
      // Repeat-off goals accumulate every day; repeating goals only on their
      // action days.
      if (goal.hasRepeatSchedule && !goal.isActionDay(day)) continue;
      scheduled++;
      if (metKeys.contains(key)) met++;
    }
  }

  return ProfileHeroStats(
    tasksDone: tasksDone,
    tasksTotal: tasksTotal,
    goalDaysMet: met,
    goalDaysScheduled: scheduled,
  );
});
