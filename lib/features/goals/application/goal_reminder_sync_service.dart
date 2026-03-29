import 'package:flutter/foundation.dart';

import '../../../core/notifications/local_notifications_service.dart';
import '../../planning/domain/models/routine_mode.dart';
import '../domain/models/user_goal.dart';
import 'goal_intensity_mode.dart';
import 'goal_reminder_schedule.dart';

/// Maps [UserGoal] reminder fields to OS daily notifications (V1: [GoalReminderStyle.dailyOnce] only).
class GoalReminderSyncService {
  GoalReminderSyncService({required LocalNotificationsService notifications}) : _n = notifications;

  final LocalNotificationsService _n;

  Future<void> cancelForGoal(String goalId) async {
    await _n.cancel(_n.idFromGoalId(goalId));
  }

  Future<void> applyForGoal(UserGoal goal) async {
    final id = _n.idFromGoalId(goal.id);
    await _n.cancel(id);
    if (!goalShouldScheduleDailyReminder(goal, DateTime.now())) return;
    final minutes = goal.reminderMinutesFromMidnight!;
    final first = nextGoalDailyReminderLocal(goal: goal, minutesFromMidnight: minutes, now: DateTime.now());
    if (first == null) {
      debugPrint('Goal reminder skipped (no slot in period): goal=${goal.id}');
      return;
    }
    final mode = GoalIntensityMode.routineModeFromGoalIntensity(goal.intensity);
    final body = switch (mode) {
      RoutineMode.flexible => 'Time for your planned actions.',
      RoutineMode.disciplined => 'Check in on your goal — stay with the plan.',
      RoutineMode.extreme => 'Goal commitment: time to act or consciously adjust.',
    };
    try {
      await _n.scheduleDailyAtLocalTime(
        id: id,
        title: 'Goal: ${goal.title}',
        body: body,
        firstFireLocal: first,
        payload: 'goal:${Uri.encodeComponent(goal.id)}',
      );
    } catch (e, st) {
      debugPrint('Goal reminder schedule failed: $e $st');
    }
  }

  Future<void> applyForGoals(Iterable<UserGoal> goals) async {
    for (final g in goals) {
      await applyForGoal(g);
    }
  }
}
