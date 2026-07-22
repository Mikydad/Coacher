import '../../../core/utils/date_keys.dart';
import '../../coaching/application/enforcement_mode_policy.dart';
import '../../coaching/domain/models/enforcement_mode.dart';
import '../../goals/application/goal_period_helpers.dart';
import '../../goals/domain/models/goal_check_in.dart';
import '../../goals/domain/models/goal_enums.dart';
import '../../goals/domain/models/user_goal.dart';
import '../../planning/domain/models/task_item.dart';

const String goalHabitDailyScope = 'goal_habit_daily';
const String taskDailyScope = 'task_daily';

class DailyAnalyticsSnapshot {
  const DailyAnalyticsSnapshot({
    required this.dateKey,
    required this.createdCount,
    required this.completedCount,
    required this.weightedCreated,
    required this.weightedCompleted,
    required this.completionRate,
    required this.weightedCompletionRate,
    required this.schemaVersion,
  });

  final String dateKey;
  final int createdCount;
  final int completedCount;

  /// Doubles since schema v3: goals contribute FRACTIONALLY (a daily goal
  /// at 45/60 min adds 0.75 × weight), not just met/not-met.
  final double weightedCreated;
  final double weightedCompleted;
  final double completionRate;
  final double weightedCompletionRate;
  final int schemaVersion;

  Map<String, dynamic> toPayload() => {
    'dateKey': dateKey,
    'createdCount': createdCount,
    'completedCount': completedCount,
    'weightedCreated': weightedCreated,
    'weightedCompleted': weightedCompleted,
    'completionRate': completionRate,
    'weightedCompletionRate': weightedCompletionRate,
    'schemaVersion': schemaVersion,
  };

  static DailyAnalyticsSnapshot fromPayload(Map<String, dynamic> payload) {
    final completionRate =
        (payload['completionRate'] as num?)?.toDouble() ?? 0.0;
    final weightedCompletionRate =
        (payload['weightedCompletionRate'] as num?)?.toDouble() ?? 0.0;
    return DailyAnalyticsSnapshot(
      dateKey: payload['dateKey'] as String? ?? '',
      createdCount: (payload['createdCount'] as num?)?.toInt() ?? 0,
      completedCount: (payload['completedCount'] as num?)?.toInt() ?? 0,
      weightedCreated: (payload['weightedCreated'] as num?)?.toDouble() ?? 0,
      weightedCompleted: (payload['weightedCompleted'] as num?)?.toDouble() ?? 0,
      completionRate: completionRate.clamp(0.0, 1.0),
      weightedCompletionRate: weightedCompletionRate.clamp(0.0, 1.0),
      schemaVersion: (payload['schemaVersion'] as num?)?.toInt() ?? 2,
    );
  }
}

class RollupAnalyticsSnapshot {
  const RollupAnalyticsSnapshot({
    required this.daysCount,
    required this.createdCount,
    required this.completedCount,
    required this.weightedCreated,
    required this.weightedCompleted,
    required this.completionRate,
    required this.weightedCompletionRate,
    required this.currentStreakDays,
    required this.bestStreakDays,
  });

  final int daysCount;
  final int createdCount;
  final int completedCount;
  final double weightedCreated;
  final double weightedCompleted;
  final double completionRate;
  final double weightedCompletionRate;
  final int currentStreakDays;
  final int bestStreakDays;
}

int linearPriorityWeight(int priority) {
  final clamped = priority.clamp(1, 5);
  return 6 - clamped;
}

DailyAnalyticsSnapshot computeTaskDailyAnalytics({
  required String dateKey,
  required Iterable<PlannedTask> tasks,
}) {
  var createdCount = 0;
  var completedCount = 0;
  var weightedCreated = 0.0;
  var weightedCompleted = 0.0;
  for (final task in tasks) {
    createdCount++;
    final w = linearPriorityWeight(task.priority);
    weightedCreated += w;
    if (task.status == TaskStatus.completed) {
      completedCount++;
      weightedCompleted += w;
    }
  }
  final completionRate = createdCount == 0
      ? 0.0
      : completedCount / createdCount;
  final weightedCompletionRate = weightedCreated == 0
      ? 0.0
      : weightedCompleted / weightedCreated;
  return DailyAnalyticsSnapshot(
    dateKey: dateKey,
    createdCount: createdCount,
    completedCount: completedCount,
    weightedCreated: weightedCreated,
    weightedCompleted: weightedCompleted,
    completionRate: completionRate,
    weightedCompletionRate: weightedCompletionRate,
    schemaVersion: 3,
  );
}

/// How one goal participates in one day's Goals/Habits % (schema v3,
/// formula decided 2026-07-22 — see the decision log).
class GoalDayContribution {
  const GoalDayContribution({required this.weight, required this.fraction});

  /// [linearPriorityWeight] of the goal's intensity.
  final int weight;

  /// 0..1 — how much of this goal's day-credit is earned.
  final double fraction;
}

/// Pure per-goal day scoring. [checkIns] may span the whole period (only
/// this goal's rows are read); windowing happens here so callers just
/// fetch a range. Returns null when the goal is NOT part of [dateKey]'s
/// denominator (weekly/monthly goals off their action days — mirroring
/// Home's "Today's goals" membership).
///
///  * daily cadence   → proportional: evaluation-window total ÷ cycle target
///  * weekly/monthly  → action days only; 1.0 if anything was logged that
///    day (or the cycle already met), else 0 — "did I show up today"
///  * repeat-off      → overall period progress ÷ target, every period day
///    (passive outcome goals count via long-horizon progress)
///
/// Legacy boolean check-ins (null value, metCommitment true) count as a
/// full cycle target.
GoalDayContribution? computeGoalDayContribution({
  required UserGoal goal,
  required String dateKey,
  required Iterable<GoalCheckIn> checkIns,
}) {
  final date = DateKeys.parseLocalDateKey(dateKey);
  final weight = linearPriorityWeight(goal.intensity);

  double effectiveValue(GoalCheckIn c) =>
      c.value ?? (c.metCommitment ? goal.targetValue : 0.0);

  double sumRange(String startKey, String endKey) => checkIns
      .where(
        (c) =>
            c.goalId == goal.id &&
            c.dateKey.compareTo(startKey) >= 0 &&
            c.dateKey.compareTo(endKey) <= 0,
      )
      .fold(0.0, (sum, c) => sum + effectiveValue(c));

  double fractionOf(double total) {
    if (goal.targetValue <= 0) return total > 0 ? 1.0 : 0.0;
    return (total / goal.targetValue).clamp(0.0, 1.0);
  }

  switch (goal.repeatCadence) {
    case GoalRepeatCadence.off:
      final startKey = DateKeys.yyyymmdd(
        DateTime.fromMillisecondsSinceEpoch(goal.periodStartMs),
      );
      return GoalDayContribution(
        weight: weight,
        fraction: fractionOf(sumRange(startKey, dateKey)),
      );
    case GoalRepeatCadence.daily:
      final window = GoalPeriodHelpers.evaluationWindow(goal, date);
      // Progress so far in the cycle — never credit future days.
      return GoalDayContribution(
        weight: weight,
        fraction: fractionOf(sumRange(DateKeys.yyyymmdd(window.start), dateKey)),
      );
    case GoalRepeatCadence.weekly:
    case GoalRepeatCadence.monthly:
      if (!goal.isActionDay(date)) return null;
      final didAnything = checkIns.any(
        (c) =>
            c.goalId == goal.id &&
            c.dateKey == dateKey &&
            ((c.value ?? 0) > 0 || c.metCommitment),
      );
      return GoalDayContribution(
        weight: weight,
        fraction: didAnything ? 1.0 : 0.0,
      );
  }
}

DailyAnalyticsSnapshot computeGoalHabitDailyAnalytics({
  required String dateKey,
  required Iterable<GoalDayContribution> goalContributions,
  required Iterable<PlannedTask> habitTasks,
}) {
  var createdCount = 0;
  var completedCount = 0;
  var weightedCreated = 0.0;
  var weightedCompleted = 0.0;

  for (final c in goalContributions) {
    createdCount++;
    weightedCreated += c.weight;
    weightedCompleted += c.weight * c.fraction;
    if (c.fraction >= 0.999) completedCount++;
  }

  // Hybrid source: habit task completions also contribute as habit units.
  for (final task in habitTasks) {
    createdCount++;
    final w = linearPriorityWeight(task.priority);
    weightedCreated += w;
    if (task.status == TaskStatus.completed) {
      completedCount++;
      weightedCompleted += w;
    }
  }

  final completionRate = createdCount == 0
      ? 0.0
      : completedCount / createdCount;
  final weightedCompletionRate = weightedCreated == 0
      ? 0.0
      : weightedCompleted / weightedCreated;
  return DailyAnalyticsSnapshot(
    dateKey: dateKey,
    createdCount: createdCount,
    completedCount: completedCount,
    weightedCreated: weightedCreated,
    weightedCompleted: weightedCompleted,
    completionRate: completionRate,
    weightedCompletionRate: weightedCompletionRate,
    schemaVersion: 3,
  );
}

RollupAnalyticsSnapshot rollupDailyAnalytics({
  required List<DailyAnalyticsSnapshot> snapshots,
  required DateTime now,
  EnforcementMode enforcementMode = EnforcementMode.disciplined,
  Set<String> protectedDateKeys = const {},
}) {
  if (snapshots.isEmpty) {
    return const RollupAnalyticsSnapshot(
      daysCount: 0,
      createdCount: 0,
      completedCount: 0,
      weightedCreated: 0,
      weightedCompleted: 0,
      completionRate: 0,
      weightedCompletionRate: 0,
      currentStreakDays: 0,
      bestStreakDays: 0,
    );
  }

  final sorted = List<DailyAnalyticsSnapshot>.from(snapshots)
    ..sort((a, b) => a.dateKey.compareTo(b.dateKey));

  var createdCount = 0;
  var completedCount = 0;
  var weightedCreated = 0.0;
  var weightedCompleted = 0.0;
  for (final d in sorted) {
    createdCount += d.createdCount;
    completedCount += d.completedCount;
    weightedCreated += d.weightedCreated;
    weightedCompleted += d.weightedCompleted;
  }

  bool qualifies(String dateKey, DailyAnalyticsSnapshot? day) {
    if (protectedDateKeys.contains(dateKey)) return true;
    if (day == null) return false;
    return EnforcementModePolicy.isStreakQualifyingDay(
      day.weightedCompletionRate,
      enforcementMode,
    );
  }

  var best = 0;
  var running = 0;
  for (final d in sorted) {
    if (qualifies(d.dateKey, d)) {
      running++;
      if (running > best) best = running;
    } else {
      running = 0;
    }
  }

  var currentStreak = 0;
  var cursor = DateTime(now.year, now.month, now.day);
  final byDate = <String, DailyAnalyticsSnapshot>{
    for (final d in sorted) d.dateKey: d,
  };
  final earliest = sorted.first.dateKey;
  while (true) {
    final key = DateKeys.yyyymmdd(cursor);
    if (key.compareTo(earliest) < 0) break;

    if (qualifies(key, byDate[key])) {
      currentStreak++;
      cursor = cursor.subtract(const Duration(days: 1));
      continue;
    }
    break;
  }

  return RollupAnalyticsSnapshot(
    daysCount: sorted.length,
    createdCount: createdCount,
    completedCount: completedCount,
    weightedCreated: weightedCreated,
    weightedCompleted: weightedCompleted,
    completionRate: createdCount == 0 ? 0.0 : completedCount / createdCount,
    weightedCompletionRate: weightedCreated == 0
        ? 0.0
        : weightedCompleted / weightedCreated,
    currentStreakDays: currentStreak,
    bestStreakDays: best,
  );
}
