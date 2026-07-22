import 'package:flutter/foundation.dart';

import '../../../core/notifications/local_notifications_service.dart';
import '../../../core/utils/stable_id.dart';
import 'adaptive_reminder_policy.dart';
import 'attention_orchestrator_service.dart';
import 'interruption_level_resolver.dart';
import '../data/reminder_repository.dart';
import '../domain/models/reminder_config.dart';
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
    DateTime Function()? now,
  }) : _repository = repository,
       _notifications = notifications,
       _orchestrator = orchestratorService,
       _now = now ?? DateTime.now;

  final ReminderRepository _repository;
  // Kept for: requestPermissionsIfNeeded, and goal-reminder direct scheduling.
  final ReminderNotificationsPort _notifications;
  final AttentionOrchestratorService _orchestrator;
  final DateTime Function() _now;

  Future<bool> ensurePermissions() =>
      _notifications.requestPermissionsIfNeeded();

  // ── Public sync methods ───────────────────────────────────────────────────

  Future<void> syncForTaskIds(List<String> taskIds) async {
    await _repository.hydrateFromRemoteForTasks(taskIds);
    final reminders = await _repository.listAllReminders();
    await _applyReminders(reminders);
  }

  Future<void> scheduleFromCache() async {
    final reminders = await _repository.listAllReminders();
    await _applyReminders(reminders);
  }

  Future<void> markTaskStarted(String taskId) =>
      _resolveReminder(taskId, keepEnabled: false);

  Future<void> markLogicalReasonProvided(String taskId) =>
      _resolveReminder(taskId, keepEnabled: false);

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
      // Cancel the current active slot (single cancel, not 64-slot loop).
      await _orchestrator.cancelForEntity(reminder.taskId);
      if (!reminder.enabled) continue;

      final nextAt = _nextReminderTime(reminder);
      if (nextAt == null) continue;

      final intent = _intentFromConfig(
        reminder,
        proposedAt: nextAt,
        reminderType: reminder.pendingAction
            ? ReminderType.followUp
            : ReminderType.scheduled,
      );
      if (intent == null) continue;

      debugPrint(
        '[ReminderSync] evaluating intent: '
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
