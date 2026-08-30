import 'package:flutter/foundation.dart';

import '../../../core/notifications/local_notifications_service.dart';
import '../../../core/utils/stable_id.dart';
import 'adaptive_reminder_policy.dart';
import 'attention_orchestrator_service.dart';
import 'reminder_occurrence_service.dart';
import 'interruption_level_resolver.dart';
import '../data/reminder_repository.dart';
import '../domain/models/reminder_config.dart';
import '../domain/models/reminder_occurrence_enums.dart';
import '../domain/models/reminder_intent.dart';
import '../domain/models/reminder_type.dart';

// ─── Notifications port (kept for permissions + cancel) ───────────────────────

abstract class ReminderNotificationsPort {
  Future<bool> requestPermissionsIfNeeded();
  int idFromTaskId(String taskId, {int slot});
  Future<void> cancel(int id);

  /// Retained for callers that still need a direct schedule path (e.g. goal
  /// reminders). For task/habit reminders, use [AttentionOrchestratorService].
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime when,
    String? payload,
  });
}

class LocalReminderNotificationsPort implements ReminderNotificationsPort {
  LocalReminderNotificationsPort(this._inner);
  final LocalNotificationsService _inner;

  @override
  Future<void> cancel(int id) => _inner.cancel(id);

  @override
  int idFromTaskId(String taskId, {int slot = 0}) =>
      _inner.idFromTaskId(taskId, slot: slot);

  @override
  Future<bool> requestPermissionsIfNeeded() =>
      _inner.requestPermissionsIfNeeded();

  @override
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime when,
    String? payload,
  }) => _inner.schedule(
    id: id,
    title: title,
    body: body,
    when: when,
    payload: payload,
  );
}

/// Maximum tail follow-ups for extreme mode after [ReminderCadence.maxEscalationLevel]
/// is reached. Replaces the old pre-scheduled tailRepeatCount: 5.
const int kExtremeMaxTailFollowUps = 3;

// ─── ReminderSyncService (adapter role) ───────────────────────────────────────

/// Owns [ReminderConfig] persistence and cadence policy.
/// Produces [ReminderIntent]s for the **next** meaningful fire time only
/// and passes them to [AttentionOrchestratorService] for evaluation.
///
/// After Phase C:
///   - No longer calls [LocalNotificationsService.schedule] directly.
///   - Replaces the 64-slot cancel loop with a single cancel via
///     [AttentionOrchestratorService.cancelForEntity].
class ReminderSyncService {
  ReminderSyncService({
    required ReminderRepository repository,
    required ReminderNotificationsPort notifications,
    required AttentionOrchestratorService orchestratorService,

    /// The V2 state machine's [L-ALIVE] layer. Optional so existing tests and
    /// legacy wiring keep working; when absent, occurrences simply are not
    /// tracked and nothing else changes.
    ReminderOccurrenceService? occurrenceService,

    /// Re-arms compiled ladders after a save. Injected as a callback to keep
    /// this service free of a dependency cycle with the scheduler.
    Future<void> Function()? rearmLadders,
    DateTime Function()? now,
  }) : _repository = repository,
       _notifications = notifications,
       _orchestrator = orchestratorService,
       _occurrences = occurrenceService,
       _rearmLadders = rearmLadders,
       _now = now ?? DateTime.now;

  final ReminderRepository _repository;
  // Kept for: requestPermissionsIfNeeded, and goal-reminder direct scheduling.
  final ReminderNotificationsPort _notifications;
  final AttentionOrchestratorService _orchestrator;
  final ReminderOccurrenceService? _occurrences;
  final Future<void> Function()? _rearmLadders;
  final DateTime Function() _now;

  Future<bool> ensurePermissions() =>
      _notifications.requestPermissionsIfNeeded();

  // ── Public sync methods ───────────────────────────────────────────────────

  Future<void> syncForTaskIds(List<String> taskIds) async {
    await _repository.hydrateFromRemoteForTasks(taskIds);
    final reminders = await _repository.listAllReminders();
    await _applyReminders(reminders);
    // A reminder the user just set should exist in the state machine now, not
    // at the next sweep — the Recovery Card and the task row read occurrences.
    final ids = taskIds.toSet();
    for (final r in reminders) {
      if (ids.contains(r.taskId)) {
        await _occurrences?.ensureForConfig(r);
      }
    }
    // Arm the ladder now: a reminder the user just set should be scheduled
    // when they leave the screen, not at the next recompute.
    await _rearmLadders?.call();
  }

  Future<void> scheduleFromCache() async {
    final reminders = await _repository.listAllReminders();
    await _applyReminders(reminders);
  }

  /// The user started the task (timer/focus start). `Active` is an opt-in
  /// signal: it stops the ladder without claiming the task is done.
  Future<void> markTaskStarted(String taskId) async {
    await _occurrences?.markActiveForEntity(taskId);
    await _resolveReminder(taskId, keepEnabled: false);
  }

  /// The user completed the task — the occurrence is resolved in the same
  /// gesture as the local write (FR-R-13), with no network in between.
  Future<void> markTaskCompleted(String taskId) async {
    await _occurrences?.resolveForEntity(
      taskId,
      kind: ReminderResolutionKind.completed,
    );
    await _resolveReminder(taskId, keepEnabled: false);
  }

  /// The user skipped or rescheduled it. [reason] is required by Extreme mode
  /// (FR-R-42) and enforced by the surface offering the choice.
  Future<void> markTaskDeferred(
    String taskId, {
    required ReminderResolutionKind kind,
    String? reason,
  }) async {
    await _occurrences?.resolveForEntity(taskId, kind: kind, reason: reason);
    await _resolveReminder(taskId, keepEnabled: false);
  }

  /// Task deleted: cancel the armed OS notification AND delete the config.
  /// Deleting the config matters as much as the cancel — `scheduleFromCache`
  /// and boot reconciliation re-arm every stored config on next launch, so a
  /// surviving row would resurrect the notification.
  Future<void> removeForDeletedTask(String taskId) async {
    await _orchestrator.cancelForEntity(taskId);
    await _repository.deleteRemindersForTask(taskId);
    // A deleted task must stop surfacing on the Recovery Card.
    await _occurrences?.deleteForEntity(taskId);
  }

  /// The user gave a logical reason instead of doing it — a deferral, which
  /// resolves the occurrence as skipped and carries the reason into the
  /// record Extreme mode demands (FR-R-42).
  Future<void> markLogicalReasonProvided(String taskId, {String? reason}) async {
    await _occurrences?.resolveForEntity(
      taskId,
      kind: ReminderResolutionKind.skipped,
      reason: reason,
    );
    await _resolveReminder(taskId, keepEnabled: false);
  }

  /// Move a task's reminder onto [targetDay], keeping its time of day.
  ///
  /// AUDIT §10 C3, precisely located. Carrying a task to tomorrow
  /// (`_moveToTomorrow`) reuses the SAME task id and preserves
  /// `reminderTimeIso` — which still carries yesterday's date. The config's
  /// `scheduledAtIso` is likewise never moved, so `_nextReminderTime` parses
  /// a past timestamp, returns null, and the carried task is armed with
  /// nothing. The reminder silently stops existing the moment the user moves
  /// the task.
  ///
  /// (The audit framed C3 as "recurring tasks remind once in their life".
  /// There is no task recurrence model here — routines are per-day containers
  /// and each day's tasks are new rows — so carry-forward is the real and
  /// only subject.)
  ///
  /// The old day's occurrence resolves as `rescheduled`; the new day gets its
  /// own, which is the whole point of occurrences being separate from config.
  Future<void> shiftToDate(String taskId, {required DateTime targetDay}) async {
    final reminders = await _repository.listAllReminders();
    final i = reminders.indexWhere((r) => r.taskId == taskId);
    if (i < 0) return;
    final current = reminders[i];

    final shifted = shiftIsoToDate(current.scheduledAtIso, targetDay);
    if (shifted == null) return;

    // The day that is being left behind was not completed — it moved.
    await _occurrences?.resolveForEntity(
      taskId,
      kind: ReminderResolutionKind.rescheduled,
    );

    final nowMs = _now().millisecondsSinceEpoch;
    final updated = current.copyWith(
      scheduledAtIso: shifted.toIso8601String(),
      pendingAction: false,
      escalationLevel: 0,
      nextPromptAtIso: null,
      updatedAtMs: nowMs,
    );
    await _upsertQuietly(updated);
    await _applyReminders(await _repository.listAllReminders());
    await _occurrences?.ensureForConfig(updated);
  }

  /// Rebuilds [iso] on [targetDay], keeping hour/minute. Null when [iso] is
  /// absent or unparseable.
  static DateTime? shiftIsoToDate(String? iso, DateTime targetDay) {
    if (iso == null) return null;
    final parsed = DateTime.tryParse(iso);
    if (parsed == null) return null;
    return DateTime(
      targetDay.year,
      targetDay.month,
      targetDay.day,
      parsed.hour,
      parsed.minute,
      parsed.second,
    );
  }

  /// Produces a follow-up [ReminderIntent] and passes it through the
  /// orchestrator pipeline (replaces the old direct-schedule snooze path).
  Future<void> requestSnooze(
    String taskId, {
    bool emergencyBypass = false,
  }) async {
    final reminders = await _repository.listAllReminders();
    final i = reminders.indexWhere((r) => r.taskId == taskId);
    if (i < 0) return;
    final current = reminders[i];
    final cadence = AdaptiveReminderPolicy.cadenceFor(
      modeRefId: current.modeRefId,
      blockUrgencyScore: current.blockUrgencyScore,
    );
    final step = AdaptiveReminderPolicy.nextStep(
      cadence: cadence,
      currentEscalationLevel: current.escalationLevel,
      emergencyBypass: emergencyBypass || current.emergencyBypass,
    );
    final nextAt = _now().add(Duration(minutes: step.snoozeMinutes));
    final updated = current.copyWith(
      pendingAction: true,
      enabled: true,
      escalationLevel: step.nextEscalationLevel,
      emergencyBypass: emergencyBypass || current.emergencyBypass,
      lastTriggeredAtMs: _now().millisecondsSinceEpoch,
      nextPromptAtIso: nextAt.toIso8601String(),
      updatedAtMs: _now().millisecondsSinceEpoch,
    );
    await _upsertQuietly(updated);

    // Produce a follow-up intent and route through the orchestrator.
    final intent = _intentFromConfig(
      updated,
      proposedAt: nextAt,
      reminderType: ReminderType.followUp,
    );
    if (intent != null) {
      await _orchestrator.evaluate(intent);
    }
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  Future<void> _resolveReminder(
    String taskId, {
    required bool keepEnabled,
  }) async {
    final reminders = await _repository.listAllReminders();
    final i = reminders.indexWhere((r) => r.taskId == taskId);
    if (i < 0) return;
    final updated = reminders[i].copyWith(
      pendingAction: false,
      escalationLevel: 0,
      enabled: keepEnabled,
      nextPromptAtIso: null,
      lastTriggeredAtMs: _now().millisecondsSinceEpoch,
      updatedAtMs: _now().millisecondsSinceEpoch,
    );
    await _upsertQuietly(updated);
    // Replace the 64-slot loop with a single cancel via the orchestrator.
    await _orchestrator.cancelForEntity(taskId);
    if (keepEnabled) {
      await _applyReminders(await _repository.listAllReminders());
    }
  }

  Future<void> _upsertQuietly(ReminderConfig reminder) async {
    try {
      await _repository.upsertReminder(reminder);
    } catch (e) {
      debugPrint(
        'Reminder upsert failed (non-fatal): '
        'task=${reminder.taskId} error=$e',
      );
    }
  }

  /// Produces a single [ReminderIntent] per enabled reminder and passes it
  /// through [AttentionOrchestratorService.evaluate].
  /// No direct [LocalNotificationsService.schedule] calls here.
  Future<void> _applyReminders(List<ReminderConfig> reminders) async {
    for (final reminder in reminders) {
      // The cancel is deliberately NOT unconditional (AUDIT §10 C6).
      // Cancelling up front and only then evaluating means a suppression
      // (active override, coaching back-off), a budget denial or a blank
      // title destroys the alarm the user already had, with nothing armed in
      // its place. So cancel only on the paths that will NOT arm a
      // replacement; when we do evaluate, the orchestrator's own
      // post-approval cancel performs the swap — the ordering the goal path
      // already relies on (goal_reminder_sync_service.dart).
      if (!reminder.enabled) {
        await _orchestrator.cancelForEntity(reminder.taskId);
        continue;
      }

      final nextAt = _nextReminderTime(reminder);
      if (nextAt == null) {
        await _orchestrator.cancelForEntity(reminder.taskId);
        continue;
      }

      // OWNERSHIP (R3): the ladder compiler owns the SCHEDULED ladder — it is
      // the only thing that knows the interruption boundary, the shields and
      // the budget, and arming slot 0 from here as well would give one slot
      // two owners. What stays here is the SNOOZE re-plan: `nextPromptAtIso`
      // is this service's own state, and its occurrence is still sitting at
      // the original (now past) time, so the ladder produces nothing for it.
      if (!reminder.pendingAction) continue;

      final intent = _intentFromConfig(
        reminder,
        proposedAt: nextAt,
        reminderType: ReminderType.followUp,
      );
      if (intent == null) {
        await _orchestrator.cancelForEntity(reminder.taskId);
        continue;
      }

      debugPrint(
        '[ReminderSync] snooze re-plan: '
        'task=${reminder.taskId} at=$nextAt escalation=${reminder.escalationLevel}',
      );
      await _orchestrator.evaluate(intent);
    }
  }

  /// Returns the single next fire time for [reminder], or null if none.
  ///
  /// For extreme mode: reactive escalation only — no pre-computed chain.
  /// Once [escalationLevel] >= [ReminderCadence.maxEscalationLevel], the
  /// tail phase is capped at [kExtremeMaxTailFollowUps] additional follow-ups.
  DateTime? _nextReminderTime(ReminderConfig reminder) {
    final now = _now();
    final cadence = AdaptiveReminderPolicy.cadenceFor(
      modeRefId: reminder.modeRefId,
      blockUrgencyScore: reminder.blockUrgencyScore,
    );

    if (reminder.pendingAction) {
      final preferred = reminder.nextPromptAtIso;
      final parsed = preferred == null ? null : DateTime.tryParse(preferred);
      if (parsed != null && parsed.isAfter(now)) return parsed;

      // Extreme tail phase cap: count how many tail follow-ups have already
      // fired (escalation levels beyond maxEscalationLevel).
      final isExtremeMode =
          (reminder.modeRefId ?? '').toLowerCase() == 'extreme';
      if (isExtremeMode &&
          reminder.escalationLevel > cadence.maxEscalationLevel) {
        final tailCount = reminder.escalationLevel - cadence.maxEscalationLevel;
        if (tailCount >= kExtremeMaxTailFollowUps) {
          // Tail phase exhausted — stop scheduling follow-ups.
          return null;
        }
        // Tail phase: follow up every 60 minutes (reactive, not pre-computed).
        return now.add(const Duration(minutes: 60));
      }

      return now.add(Duration(minutes: cadence.initialSnoozeMinutes));
    }

    final parsed = reminder.scheduledAtIso == null
        ? null
        : DateTime.tryParse(reminder.scheduledAtIso!);
    if (parsed == null) return null;
    return parsed.isAfter(now) ? parsed : null;
  }

  /// Builds a [ReminderIntent] from a [ReminderConfig].
  /// Returns null if the config is insufficient to produce a valid intent.
  ReminderIntent? _intentFromConfig(
    ReminderConfig config, {
    required DateTime proposedAt,
    required ReminderType reminderType,
  }) {
    final title = config.taskTitle?.trim();
    if (title == null || title.isEmpty) return null;

    final level = InterruptionLevelResolver.resolve(
      enforcementMode: config.modeRefId ?? 'flexible',
      escalationLevel: config.escalationLevel,
      emergencyBypass: config.emergencyBypass,
    );

    return ReminderIntent(
      id: StableId.generate('ri_${config.taskId}'),
      entityId: config.taskId,
      entityKind: 'task',
      entityTitle: title,
      proposedAt: proposedAt,
      importance: config.blockUrgencyScore.clamp(0, 100),
      interruptionLevel: level,
      enforcementMode: config.modeRefId ?? 'flexible',
      escalationLevel: config.escalationLevel,
      reminderType: reminderType,
      sourceReason: reminderType == ReminderType.followUp
          ? 'snooze_followup'
          : 'scheduled',
      createdAtMs: _now().millisecondsSinceEpoch,
    );
  }

  // ── Title / body helpers (retained for goal reminders & debug) ────────────

  String titleForReminder(ReminderConfig reminder) {
    final title = reminder.taskTitle?.trim();
    if (title == null || title.isEmpty) return 'Task Reminder';
    return title;
  }

  String bodyForReminder(ReminderConfig reminder) {
    final cadence = AdaptiveReminderPolicy.cadenceFor(
      modeRefId: reminder.modeRefId,
      blockUrgencyScore: reminder.blockUrgencyScore,
    );
    final step = AdaptiveReminderPolicy.nextStep(
      cadence: cadence,
      currentEscalationLevel: reminder.escalationLevel,
      emergencyBypass: reminder.emergencyBypass,
    );
    if (step.enableNonEssentialActionGate) {
      final t = reminder.taskTitle?.trim();
      if (t != null && t.isNotEmpty) {
        return 'Action needed for "$t": start now or submit a logical reason.';
      }
      return 'Action needed: start now or submit a logical reason to continue.';
    }
    if (step.requireAppOpenNudge) {
      final t = reminder.taskTitle?.trim();
      if (t != null && t.isNotEmpty) {
        return 'Please open SidePal: start "$t" or provide a logical reason.';
      }
      return 'Please open SidePal: start this task or provide a logical reason.';
    }
    final t = reminder.taskTitle?.trim();
    if (t != null && t.isNotEmpty) return 'Time to start "$t".';
    return 'Time to start your planned task.';
  }
}
