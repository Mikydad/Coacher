import 'package:flutter/foundation.dart';

import '../../../core/notifications/local_notifications_service.dart';
import '../../../core/utils/stable_id.dart';
import '../../planning/domain/models/routine_mode.dart';
import '../../reminders/application/attention_orchestrator_service.dart';
import '../../reminders/application/interruption_level_resolver.dart';
import '../../reminders/application/notification_route_resolver.dart';
import '../../reminders/domain/models/reminder_intent.dart';
import '../domain/models/user_goal.dart';
import 'goal_intensity_mode.dart';
import 'goal_reminder_schedule.dart';

/// Maps [UserGoal] reminder fields to OS notifications
/// (V1: [GoalReminderStyle.dailyOnce] only).
///
/// Phase 0 reroute (decision log 2026-07-23): goal reminders no longer call
/// the OS repeat matchers directly. Each goal schedules ONE next occurrence
/// as a `ReminderIntent(entityKind: 'goal')` through the
/// [AttentionOrchestratorService] — inheriting override suppression,
/// collision spacing, batching and the notification ledger — and is rolled
/// forward by bootstrap, goal saves, and the recompute graph's notification
/// step (the pattern interval repeats always used). This also collapses up
/// to 39 pending OS slots per goal down to one (iOS caps pending at 64).
class GoalReminderSyncService {
  GoalReminderSyncService({
    required GoalNotificationsPort notifications,
    required AttentionOrchestratorService orchestrator,
    DateTime Function()? now,
  }) : _n = notifications,
       _orchestrator = orchestrator,
       _now = now ?? DateTime.now;

  final GoalNotificationsPort _n;
  final AttentionOrchestratorService _orchestrator;
  final DateTime Function() _now;

  /// Throttle for [rearmIfStale] — recompute flushes are frequent; the
  /// roll-forward only needs to catch day changes and fired reminders.
  static const Duration kRearmMinInterval = Duration(minutes: 5);
  int _lastRearmMs = 0;

  /// Cancels every notification id a goal may ever have pinned — including
  /// the retired per-weekday/per-month-day slots from before the Phase 0
  /// reroute, so upgrading users don't keep stale repeating notifications.
  Future<void> cancelForGoal(String goalId) async {
    await _n.cancel(_n.idFromGoalId(goalId));
    for (var wd = DateTime.monday; wd <= DateTime.sunday; wd++) {
      await _n.cancel(_n.idFromGoalIdWeekday(goalId, wd));
    }
    for (var dom = 1; dom <= 31; dom++) {
      await _n.cancel(_n.idFromGoalIdMonthDay(goalId, dom));
    }
    await _orchestrator.cancelForEntity(goalId);
  }

  Future<void> applyForGoal(UserGoal goal) async {
    await cancelForGoal(goal.id);
    final now = _now();
    // Passive goals stay silent: goalShouldScheduleDailyReminder returns
    // false when repeatCadence == off (decision log 2026-07-11).
    if (!goalShouldScheduleDailyReminder(goal, now)) return;
    final minutes = goal.reminderMinutesFromMidnight!;
    final mode = GoalIntensityMode.routineModeFromGoalIntensity(goal.intensity);
    final body = switch (mode) {
      RoutineMode.flexible => 'Time for your planned actions.',
      RoutineMode.disciplined => 'Check in on your goal — stay with the plan.',
      RoutineMode.extreme =>
        'Goal commitment: time to act or consciously adjust.',
    };

    // Single next occurrence across ALL cadences: isActionDay handles daily,
    // weekly weekday selections, monthly days, and interval repeats.
    final first = nextGoalActionDayReminderLocal(
      goal: goal,
      minutesFromMidnight: minutes,
      now: now,
    );
    if (first == null) {
      debugPrint('Goal reminder skipped (no slot in period): goal=${goal.id}');
      return;
    }

    final intent = ReminderIntent(
      id: StableId.generate('ri_goal'),
      entityId: goal.id,
      entityKind: ReminderEntityKinds.goal,
      entityTitle: 'Goal: ${goal.title}',
      proposedAt: first,
      importance: 50,
      interruptionLevel: InterruptionLevelResolver.resolve(
        enforcementMode: mode.name,
        escalationLevel: 0,
        emergencyBypass: false,
      ),
      enforcementMode: mode.name,
      sourceReason: 'goal_reminder',
      bodyOverride: body,
      createdAtMs: now.millisecondsSinceEpoch,
    );
    try {
      await _orchestrator.evaluate(intent);
    } catch (e, st) {
      debugPrint('Goal reminder schedule failed: $e $st');
    }
  }

  Future<void> applyForGoals(Iterable<UserGoal> goals) async {
    for (final g in goals) {
      await applyForGoal(g);
    }
  }

  /// Roll-forward hook for the recompute graph's notification step: since
  /// goal reminders are one-shot now, a fired reminder needs the next
  /// occurrence re-armed on the next app activity. Throttled so frequent
  /// recompute flushes don't re-cancel/re-schedule constantly.
  Future<void> rearmIfStale(Iterable<UserGoal> goals) async {
    final nowMs = _now().millisecondsSinceEpoch;
    if (nowMs - _lastRearmMs < kRearmMinInterval.inMilliseconds) return;
    _lastRearmMs = nowMs;
    await applyForGoals(goals);
  }

  @visibleForTesting
  void debugResetRearmThrottle() => _lastRearmMs = 0;
}
