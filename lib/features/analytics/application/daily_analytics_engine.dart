import '../../../core/utils/date_keys.dart';
import '../../goals/domain/models/goal_check_in.dart';
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
  final int weightedCreated;
  final int weightedCompleted;
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
      weightedCreated: (payload['weightedCreated'] as num?)?.toInt() ?? 0,
      weightedCompleted: (payload['weightedCompleted'] as num?)?.toInt() ?? 0,
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
  final int weightedCreated;
  final int weightedCompleted;
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
  var weightedCreated = 0;
  var weightedCompleted = 0;
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
    schemaVersion: 2,
  );
}

DailyAnalyticsSnapshot computeGoalHabitDailyAnalytics({
  required String dateKey,
  required Iterable<UserGoal> goals,
  required Iterable<GoalCheckIn> checkIns,
  required Iterable<PlannedTask> habitTasks,
}) {
  final doneByGoalId = <String, bool>{};
  for (final checkIn in checkIns) {
    if (checkIn.dateKey != dateKey) continue;
    if (checkIn.metCommitment) {
      doneByGoalId[checkIn.goalId] = true;
    }
  }

  var createdCount = 0;
  var completedCount = 0;
  var weightedCreated = 0;
  var weightedCompleted = 0;

  for (final goal in goals) {
    createdCount++;
    final w = linearPriorityWeight(goal.intensity);
    weightedCreated += w;
    if (doneByGoalId[goal.id] == true) {
      completedCount++;
      weightedCompleted += w;
    }
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
    schemaVersion: 2,
  );
}

RollupAnalyticsSnapshot rollupDailyAnalytics({
  required List<DailyAnalyticsSnapshot> snapshots,
  required DateTime now,
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
  var weightedCreated = 0;
  var weightedCompleted = 0;
  for (final d in sorted) {
    createdCount += d.createdCount;
    completedCount += d.completedCount;
    weightedCreated += d.weightedCreated;
    weightedCompleted += d.weightedCompleted;
  }

  var best = 0;
  var running = 0;
  for (final d in sorted) {
    if (d.weightedCompletionRate >= 0.999) {
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
  while (true) {
    final key = DateKeys.yyyymmdd(cursor);
    final day = byDate[key];
    if (day == null || day.weightedCompletionRate < 0.999) break;
    currentStreak++;
    cursor = cursor.subtract(const Duration(days: 1));
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
