import 'package:flutter/foundation.dart';

import '../../../core/notifications/local_notifications_service.dart';
import '../../planning/domain/models/routine_mode.dart';
import '../domain/models/goal_enums.dart';
import '../domain/models/user_goal.dart';
import 'goal_intensity_mode.dart';
import 'goal_reminder_schedule.dart';

/// Maps [UserGoal] reminder fields to OS daily notifications (V1: [GoalReminderStyle.dailyOnce] only).
class GoalReminderSyncService {
  GoalReminderSyncService({required LocalNotificationsService notifications})
    : _n = notifications;

  final LocalNotificationsService _n;

  Future<void> cancelForGoal(String goalId) async {
    await _n.cancel(_n.idFromGoalId(goalId));
    for (var wd = DateTime.monday; wd <= DateTime.sunday; wd++) {
      await _n.cancel(_n.idFromGoalIdWeekday(goalId, wd));
    }
    for (var dom = 1; dom <= 31; dom++) {
      await _n.cancel(_n.idFromGoalIdMonthDay(goalId, dom));
    }
  }

  Future<void> applyForGoal(UserGoal goal) async {
    await cancelForGoal(goal.id);
    if (!goalShouldScheduleDailyReminder(goal, DateTime.now())) return;
    final minutes = goal.reminderMinutesFromMidnight!;
    final mode = GoalIntensityMode.routineModeFromGoalIntensity(goal.intensity);
    final body = switch (mode) {
      RoutineMode.flexible => 'Time for your planned actions.',
      RoutineMode.disciplined => 'Check in on your goal — stay with the plan.',
      RoutineMode.extreme =>
        'Goal commitment: time to act or consciously adjust.',
    };
    final title = 'Goal: ${goal.title}';
    final payload = 'goal:${Uri.encodeComponent(goal.id)}';

    try {
      // Interval repeats (every 2 days/weeks/months…) can't use an OS
      // auto-repeat matcher — schedule the single next occurrence; bootstrap
      // and goal saves roll it forward.
      if (goal.repeatInterval > 1) {
        final first = nextGoalActionDayReminderLocal(
          goal: goal,
          minutesFromMidnight: minutes,
          now: DateTime.now(),
        );
        if (first == null) return;
        await _n.schedule(
          id: _n.idFromGoalId(goal.id),
          title: title,
          body: body,
          when: first,
          payload: payload,
        );
        return;
      }

      switch (goal.repeatCadence) {
        case GoalRepeatCadence.off:
          return;
        case GoalRepeatCadence.daily:
          final first = nextGoalDailyReminderLocal(
            goal: goal,
            minutesFromMidnight: minutes,
            now: DateTime.now(),
          );
          if (first == null) {
            debugPrint(
              'Goal reminder skipped (no slot in period): goal=${goal.id}',
            );
            return;
          }
          await _n.scheduleDailyAtLocalTime(
            id: _n.idFromGoalId(goal.id),
            title: title,
            body: body,
            firstFireLocal: first,
            payload: payload,
          );
        case GoalRepeatCadence.weekly:
          // One weekly-repeating notification per selected weekday.
          for (final weekday in goal.scheduledWeekdays ?? const <int>[]) {
            final first = nextGoalWeekdayReminderLocal(
              goal: goal,
              weekday: weekday,
              minutesFromMidnight: minutes,
              now: DateTime.now(),
            );
            if (first == null) continue;
            await _n.scheduleWeeklyAtLocalTime(
              id: _n.idFromGoalIdWeekday(goal.id, weekday),
              title: title,
              body: body,
              firstFireLocal: first,
              payload: payload,
            );
          }
        case GoalRepeatCadence.monthly:
          // One monthly-repeating notification per selected day of month.
          for (final dom in goal.repeatDaysOfMonth ?? const <int>[]) {
            final first = _nextMonthDayFire(goal, dom, minutes);
            if (first == null) continue;
            await _n.scheduleMonthlyAtLocalTime(
              id: _n.idFromGoalIdMonthDay(goal.id, dom),
              title: title,
              body: body,
              firstFireLocal: first,
              payload: payload,
            );
          }
      }
    } catch (e, st) {
      debugPrint('Goal reminder schedule failed: $e $st');
    }
  }

  /// Next future fire on day-of-month [dom] within the goal period, or null.
  static DateTime? _nextMonthDayFire(UserGoal goal, int dom, int minutes) {
    final now = DateTime.now();
    final end = DateTime.fromMillisecondsSinceEpoch(goal.periodEndMs);
    var probe = DateTime.fromMillisecondsSinceEpoch(goal.periodStartMs);
    if (now.isAfter(probe)) probe = now;
    // Scan up to 13 months to skip months lacking the day (e.g. the 31st).
    for (var i = 0; i <= 13; i++) {
      final candidate = DateTime(
        probe.year,
        probe.month + i,
        dom,
        minutes ~/ 60,
        minutes % 60,
      );
      if (candidate.day != dom) continue; // rolled over a short month
      if (!candidate.isAfter(now)) continue;
      if (candidate.isAfter(end)) return null;
      return candidate;
    }
    return null;
  }

  Future<void> applyForGoals(Iterable<UserGoal> goals) async {
    for (final g in goals) {
      await applyForGoal(g);
    }
  }
}
