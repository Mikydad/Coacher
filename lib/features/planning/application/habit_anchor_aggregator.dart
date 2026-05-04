import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/utils/date_keys.dart';
import '../../goals/application/goal_period_helpers.dart';
import '../../goals/application/goals_providers.dart';
import '../../goals/domain/models/goal_categories.dart';
import '../../goals/domain/models/goal_enums.dart';
import '../../goals/domain/models/user_goal.dart';
import '../domain/models/task_item.dart';
import 'planned_task_collect.dart';

const goalHabitAnchorDefaultMinutes = 30;

enum HabitAnchorSource { goal, plannedTask }

class HabitAnchor {
  const HabitAnchor({
    required this.id,
    required this.source,
    required this.label,
    required this.dateKey,
    required this.startLocal,
    required this.endLocal,
    this.goalId,
    this.taskId,
  });

  final String id;
  final HabitAnchorSource source;
  final String label;
  final String dateKey;
  final DateTime startLocal;
  final DateTime endLocal;
  final String? goalId;
  final String? taskId;
}

Future<List<HabitAnchor>> readHabitAnchorsForDate(
  WidgetRef ref, {
  required String dateKey,
}) async {
  final repo = ref.read(planningRepositoryProvider);
  final rows = await collectTasksForDateKeyPreferServer(
    repo,
    dateKey,
    enforceTaskPlanDate: true,
  );

  final anchors = <HabitAnchor>[];
  for (final row in rows) {
    final task = row.task;
    if (!task.isHabitAnchor || !taskIsOpenForHub(task)) continue;
    final start = _parseDateTimeLocal(task.reminderTimeIso);
    if (start == null || DateKeys.yyyymmdd(start) != dateKey) continue;
    anchors.add(
      HabitAnchor(
        id: 'task_${task.id}',
        source: HabitAnchorSource.plannedTask,
        label: task.title,
        dateKey: dateKey,
        startLocal: start,
        endLocal: start.add(Duration(minutes: task.durationMinutes)),
        taskId: task.id,
      ),
    );
  }

  final date = DateTime.tryParse(dateKey);
  if (date == null) return anchors;
  final goals = await ref.read(goalsRepositoryProvider).watchGoals().first;
  for (final goal in goals) {
    if (!_isActiveHabitGoalForDate(goal, dateKey)) continue;
    final minutes = goal.reminderMinutesFromMidnight;
    if (minutes == null) continue;
    final start = DateTime(
      date.year,
      date.month,
      date.day,
      minutes ~/ 60,
      minutes % 60,
    );
    anchors.add(
      HabitAnchor(
        id: 'goal_${goal.id}',
        source: HabitAnchorSource.goal,
        label: goal.title,
        dateKey: dateKey,
        startLocal: start,
        endLocal: start.add(const Duration(minutes: goalHabitAnchorDefaultMinutes)),
        goalId: goal.id,
      ),
    );
  }

  anchors.sort((a, b) {
    final c = a.startLocal.compareTo(b.startLocal);
    if (c != 0) return c;
    return a.id.compareTo(b.id);
  });
  return anchors;
}

List<HabitAnchor> findOverlappingHabitAnchorsForTask(
  PlannedTask task,
  Iterable<HabitAnchor> anchors, {
  String? ignoredTaskId,
}) {
  final start = _parseDateTimeLocal(task.reminderTimeIso);
  if (start == null) return const <HabitAnchor>[];
  final end = start.add(Duration(minutes: task.durationMinutes));
  final overlaps = <HabitAnchor>[];
  for (final anchor in anchors) {
    if (anchor.source == HabitAnchorSource.plannedTask && anchor.taskId == ignoredTaskId) {
      continue;
    }
    if (_windowsOverlap(start, end, anchor.startLocal, anchor.endLocal)) {
      overlaps.add(anchor);
    }
  }
  overlaps.sort((a, b) => a.startLocal.compareTo(b.startLocal));
  return overlaps;
}

bool _isActiveHabitGoalForDate(UserGoal goal, String dateKey) {
  if (goal.status != GoalStatus.active) return false;
  if (goal.categoryId != GoalCategories.habits) return false;
  if (!goal.reminderEnabled || goal.reminderMinutesFromMidnight == null) return false;
  return GoalPeriodHelpers.isDateKeyInPeriod(goal, dateKey);
}

DateTime? _parseDateTimeLocal(String? iso) {
  if (iso == null || iso.trim().isEmpty) return null;
  return DateTime.tryParse(iso)?.toLocal();
}

bool _windowsOverlap(
  DateTime aStart,
  DateTime aEnd,
  DateTime bStart,
  DateTime bEnd,
) {
  return aStart.isBefore(bEnd) && aEnd.isAfter(bStart);
}
