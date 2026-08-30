import 'package:flutter/foundation.dart';

import '../../../core/notifications/local_notifications_service.dart';
import '../../../core/utils/stable_id.dart';
import '../../planning/domain/models/routine_mode.dart';
import '../../reminders/application/attention_orchestrator_service.dart';
import '../../reminders/application/interruption_level_resolver.dart';
import '../../reminders/application/notification_route_resolver.dart';
import '../../reminders/application/reminder_occurrence_service.dart';
import '../../reminders/domain/models/reminder_intent.dart';
import '../../reminders/domain/models/reminder_type.dart';
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

    /// V2 state machine. Optional so existing wiring and tests keep working.
    ReminderOccurrenceService? occurrenceService,
    DateTime Function()? now,
  }) : _n = notifications,
       _orchestrator = orchestrator,
       _occurrences = occurrenceService,
       _now = now ?? DateTime.now;

  final GoalNotificationsPort _n;
  final AttentionOrchestratorService _orchestrator;
  final ReminderOccurrenceService? _occurrences;
  final DateTime Function() _now;

  /// How many occurrences a goal keeps armed at once (FR-R-14).
  ///
  /// One was the Phase 0 reroute's compromise, and it is why a phone left
  /// untouched over a weekend fires Saturday's goal reminder and never
  /// schedules Sunday's: every re-arm trigger is app activity (AUDIT §10 C4).
  /// Two means one missed app-open can no longer silence a daily goal, at a
  /// cost of one extra pending slot per goal — within FR-R-33's budget.
  static const int kArmedOccurrences = 2;

  /// Throttle for [rearmIfStale] — recompute flushes are frequent; the
  /// roll-forward only needs to catch day changes and fired reminders.
  static const Duration kRearmMinInterval = Duration(minutes: 5);
  int _lastRearmMs = 0;

  /// Cancels every notification id a goal may ever have pinned — including
  /// the retired per-weekday/per-month-day slots from before the Phase 0
  /// reroute, so upgrading users don't keep stale repeating notifications.
  Future<void> cancelForGoal(String goalId) async {
    for (var slot = 0; slot < kArmedOccurrences; slot++) {
      await _n.cancel(_n.idFromGoalId(goalId, slot: slot));
    }
    await _cancelLegacySlots(goalId);
    await _orchestrator.cancelForEntity(goalId);
  }

  /// The retired per-weekday/per-month-day slots from before the Phase 0
  /// reroute — safe to sweep unconditionally (nothing schedules them now).
  Future<void> _cancelLegacySlots(String goalId) async {
    for (var wd = DateTime.monday; wd <= DateTime.sunday; wd++) {
      await _n.cancel(_n.idFromGoalIdWeekday(goalId, wd));
    }
    for (var dom = 1; dom <= 31; dom++) {
      await _n.cancel(_n.idFromGoalIdMonthDay(goalId, dom));
    }
  }

  Future<void> applyForGoal(UserGoal goal) async {
    final now = _now();
    // Passive goals stay silent: goalShouldScheduleDailyReminder returns
    // false when repeatCadence == off (decision log 2026-07-11).
    if (!goalShouldScheduleDailyReminder(goal, now)) {
      // Not eligible (paused / passive / disabled / period ended): remove
      // anything armed, legacy or current.
      await cancelForGoal(goal.id);
      return;
    }
    final minutes = goal.reminderMinutesFromMidnight!;
    final mode = GoalIntensityMode.routineModeFromGoalIntensity(goal.intensity);
    final body = switch (mode) {
      RoutineMode.flexible => 'Time for your planned actions.',
      RoutineMode.disciplined => 'Check in on your goal — stay with the plan.',
      RoutineMode.extreme =>
        'Goal commitment: time to act or consciously adjust.',
    };

    // The next [kArmedOccurrences] occurrences across ALL cadences:
    // isActionDay handles daily, weekly weekday selections, monthly days and
    // interval repeats. Arming the SECOND one now is the C4 fix — every
    // re-arm trigger in this app is app activity, so a single armed
    // occurrence means a phone left alone over a weekend fires Saturday's
    // reminder and never schedules Sunday's.
    final fireTimes = nextGoalActionDayReminders(
      goal: goal,
      minutesFromMidnight: minutes,
      now: now,
      count: kArmedOccurrences,
    );
    if (fireTimes.isEmpty) {
      debugPrint('Goal reminder skipped (no slot in period): goal=${goal.id}');
      await cancelForGoal(goal.id);
      return;
    }

    // Schedule path: only sweep the retired legacy slots up front. The LIVE
    // slots are swapped by the orchestrator itself (after the budget check),
    // so a suppressed or budget-denied evaluation leaves the previously
    // armed reminder intact instead of destroying it (review finding A).
    await _cancelLegacySlots(goal.id);

    // The goal's period may end before a second occurrence exists; cancel any
    // stale sibling so it cannot outlive the plan.
    for (var slot = fireTimes.length; slot < kArmedOccurrences; slot++) {
      await _n.cancel(_n.idFromGoalId(goal.id, slot: slot));
    }

    for (var slot = 0; slot < fireTimes.length; slot++) {
      final fireAt = fireTimes[slot];
      final intent = ReminderIntent(
        id: StableId.generate('ri_goal'),
        entityId: goal.id,
        entityKind: ReminderEntityKinds.goal,
        entityTitle: 'Goal: ${goal.title}',
        proposedAt: fireAt,
        importance: 50,
        interruptionLevel: InterruptionLevelResolver.resolve(
          enforcementMode: mode.name,
          escalationLevel: 0,
          emergencyBypass: false,
        ),
        enforcementMode: mode.name,
        reminderType: ReminderType.scheduled,
        sourceReason: 'goal_reminder',
        bodyOverride: body,
        slot: slot,
        createdAtMs: now.millisecondsSinceEpoch,
      );
      try {
        await _orchestrator.evaluate(intent);
      } catch (e, st) {
        debugPrint('Goal reminder schedule failed: $e $st');
      }
      // Each armed occurrence joins the state machine, so a fired-but-
      // unresolved goal day becomes visible instead of vanishing (FR-R-14).
      await _occurrences?.ensureForGoalOccurrence(
        goalId: goal.id,
        title: 'Goal: ${goal.title}',
        scheduledAt: fireAt,
        modeRefId: mode.name,
      );
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
