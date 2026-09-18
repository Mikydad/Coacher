import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/utils/date_keys.dart';
import '../../goals/application/goals_providers.dart';
import '../../goals/data/goals_repository.dart';
import '../../goals/domain/models/goal_enums.dart';
import '../../planning/application/planned_task_collect.dart';
import '../../planning/application/planned_task_providers.dart';
import '../../planning/domain/models/task_item.dart';
import '../../time_tracker/application/time_tracker_providers.dart';

/// "What happened that day?" — the Day detail card's read model.
///
/// Tasks and goal check-ins are what the day asked and what was logged;
/// [timeLogged] is a supporting fact from the Time tracker and is never an
/// input to any rate, ring or streak (decision 2026-09-12).
class ProgressDayTask {
  const ProgressDayTask({
    required this.id,
    required this.title,
    required this.status,
    required this.priority,
    required this.isHabitAnchor,
  });

  final String id;
  final String title;
  final TaskStatus status;
  final int priority;
  final bool isHabitAnchor;

  bool get isDone => status == TaskStatus.completed;
}

class ProgressDayCheckIn {
  const ProgressDayCheckIn({
    required this.goalId,
    required this.goalTitle,
    required this.metCommitment,
    required this.value,
  });

  final String goalId;
  final String goalTitle;
  final bool metCommitment;
  final double? value;
}

class ProgressDayDetail {
  const ProgressDayDetail({
    required this.dateKey,
    required this.tasks,
    required this.checkIns,
    required this.timeLogged,
  });

  final String dateKey;
  final List<ProgressDayTask> tasks;
  final List<ProgressDayCheckIn> checkIns;

  /// Total tracked time that day (Time tracker). Zero when nothing logged.
  final Duration timeLogged;

  int get tasksDone => tasks.where((t) => t.isDone).length;
  bool get isEmpty => tasks.isEmpty && checkIns.isEmpty;

  /// `2h 15m` | `45m` | `—`.
  String get timeLoggedLabel => formatLoggedDuration(timeLogged);
}

String formatLoggedDuration(Duration d) {
  if (d.inMinutes <= 0) return '—';
  final h = d.inHours;
  final m = d.inMinutes % 60;
  if (h == 0) return '${m}m';
  if (m == 0) return '${h}h';
  return '${h}h ${m}m';
}

/// All reads are Isar. For today the task rows stream keeps this fresh;
/// past days only change through backfill, which republishes the series.
final progressDayDetailProvider =
    FutureProvider.family<ProgressDayDetail, String>((ref, dateKey) async {
      ref.watch(goalsStreamProvider);
      if (dateKey == DateKeys.todayKey()) {
        ref.watch(todayAllTasksRowsProvider);
      }
      final timeLogged = ref.watch(daySummaryProvider(dateKey)).logged;

      final planningRepo = ref.read(planningRepositoryProvider);
      final rows = await collectTasksForDateKey(
        planningRepo,
        dateKey,
        enforceTaskPlanDate: true,
      );
      final tasks = [
        for (final r in rows)
          ProgressDayTask(
            id: r.task.id,
            title: r.task.title,
            status: r.task.status,
            priority: r.task.priority,
            isHabitAnchor: r.task.isHabitAnchor,
          ),
      ];

      final goalsRepo = ref.read(goalsRepositoryProvider);
      final goals = await goalsRepo.fetchGoalsOnce();
      final titles = {for (final g in goals) g.id: g.title};
      final raw = await readCheckInsForDate(
        goalsRepo,
        dateKey,
        // Active goals only — same rule as the day snapshot, so the Day
        // detail never lists a check-in the ring did not count.
        goalIds: goals
            .where((g) => g.status == GoalStatus.active)
            .map((g) => g.id),
      );
      final checkIns = [
        for (final c in raw)
          if (titles.containsKey(c.goalId))
            ProgressDayCheckIn(
              goalId: c.goalId,
              goalTitle: titles[c.goalId]!,
              metCommitment: c.metCommitment,
              value: c.value,
            ),
      ]..sort((a, b) => a.goalTitle.compareTo(b.goalTitle));

      return ProgressDayDetail(
        dateKey: dateKey,
        tasks: tasks,
        checkIns: checkIns,
        timeLogged: timeLogged,
      );
    });
