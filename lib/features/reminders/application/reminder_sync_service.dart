import 'package:flutter/foundation.dart';

import '../../../core/notifications/local_notifications_service.dart';
import 'adaptive_reminder_policy.dart';
import '../data/reminder_repository.dart';
import '../domain/models/reminder_config.dart';

abstract class ReminderNotificationsPort {
  Future<bool> requestPermissionsIfNeeded();
  int idFromTaskId(String taskId, {int slot});
  Future<void> cancel(int id);
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
  int idFromTaskId(String taskId, {int slot = 0}) => _inner.idFromTaskId(taskId, slot: slot);

  @override
  Future<bool> requestPermissionsIfNeeded() => _inner.requestPermissionsIfNeeded();

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

class ReminderSyncService {
  ReminderSyncService({
    required ReminderRepository repository,
    required ReminderNotificationsPort notifications,
    DateTime Function()? now,
  }) : _repository = repository,
       _notifications = notifications,
       _now = now ?? DateTime.now;

  final ReminderRepository _repository;
  final ReminderNotificationsPort _notifications;
  final DateTime Function() _now;

  Future<bool> ensurePermissions() => _notifications.requestPermissionsIfNeeded();

  Future<void> syncForTaskIds(List<String> taskIds) async {
    await _repository.hydrateFromRemoteForTasks(taskIds);
    final reminders = await _repository.listAllReminders();
    await _applyReminders(reminders);
  }

  Future<void> scheduleFromCache() async {
    final reminders = await _repository.listAllReminders();
    await _applyReminders(reminders);
  }

  Future<void> markTaskStarted(String taskId) => _resolveReminder(taskId, keepEnabled: false);

  Future<void> markLogicalReasonProvided(String taskId) => _resolveReminder(taskId, keepEnabled: false);

  Future<void> requestSnooze(String taskId, {bool emergencyBypass = false}) async {
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
    reminders[i] = updated;
    await _upsertQuietly(updated);
    await _applyReminders(await _repository.listAllReminders());
  }

  Future<void> _resolveReminder(String taskId, {required bool keepEnabled}) async {
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
    reminders[i] = updated;
    await _upsertQuietly(updated);
    await _cancelReminderSlots(taskId);
    if (keepEnabled) {
      await _applyReminders(await _repository.listAllReminders());
    }
  }

  Future<void> _cancelReminderSlots(String taskId) async {
    for (var slot = 0; slot < 64; slot++) {
      await _notifications.cancel(_notifications.idFromTaskId(taskId, slot: slot));
    }
  }

  Future<void> _upsertQuietly(ReminderConfig reminder) async {
    try {
      await _repository.upsertReminder(reminder);
    } catch (e) {
      debugPrint('Reminder upsert failed (non-fatal): task=${reminder.taskId} error=$e');
    }
  }

  Future<void> _applyReminders(List<ReminderConfig> reminders) async {
    for (final reminder in reminders) {
      await _cancelReminderSlots(reminder.taskId);
      if (!reminder.enabled) continue;
      final times = _nextReminderTimes(reminder);
      for (var slot = 0; slot < times.length; slot++) {
        final when = times[slot];
        final id = _notifications.idFromTaskId(reminder.taskId, slot: slot);
        debugPrint(
          'Scheduling reminder: task=${reminder.taskId} at=$when notifId=$id escalation=${reminder.escalationLevel}',
        );
        try {
          await _notifications.schedule(
            id: id,
            title: _titleForReminder(reminder),
            body: _bodyForReminder(reminder, slot: slot),
            when: when,
            payload: 'task:${Uri.encodeComponent(reminder.taskId)}',
          );
        } catch (e, st) {
          debugPrint('Reminder schedule failed: task=${reminder.taskId} error=$e');
          debugPrint('$st');
        }
      }
    }
  }

  List<DateTime> _nextReminderTimes(ReminderConfig reminder) {
    final now = _now();
    final cadence = AdaptiveReminderPolicy.cadenceFor(
      modeRefId: reminder.modeRefId,
      blockUrgencyScore: reminder.blockUrgencyScore,
    );

    if (reminder.pendingAction) {
      final preferred = reminder.nextPromptAtIso;
      final parsed = preferred == null ? null : DateTime.tryParse(preferred);
      if (parsed != null && parsed.isAfter(now)) return [parsed];
      final nextAt = now.add(Duration(minutes: cadence.initialSnoozeMinutes));
      return [nextAt];
    }

    final preferred = reminder.pendingAction ? reminder.nextPromptAtIso : reminder.scheduledAtIso;
    final parsed = preferred == null ? null : DateTime.tryParse(preferred);
    if (parsed == null) return const [];
    final out = <DateTime>[];
    if (parsed.isAfter(now)) {
      out.add(parsed);
    }
    if (!cadence.autoRepeatEnabled) return out;

    final offsets = AdaptiveReminderPolicy.autoRepeatOffsets(cadence);
    for (final offset in offsets) {
      final t = parsed.add(Duration(minutes: offset));
      if (t.isAfter(now)) out.add(t);
      if (out.length >= cadence.maxFutureNudges) break;
    }
    return out;
  }

  String _titleForReminder(ReminderConfig reminder) {
    final title = reminder.taskTitle?.trim();
    if (title == null || title.isEmpty) return 'Task Reminder';
    return title;
  }

  String _bodyForReminder(ReminderConfig reminder, {int slot = 0}) {
    final cadence = AdaptiveReminderPolicy.cadenceFor(
      modeRefId: reminder.modeRefId,
      blockUrgencyScore: reminder.blockUrgencyScore,
    );
    final currentLevel = reminder.pendingAction
        ? reminder.escalationLevel
        : slot.clamp(0, cadence.maxEscalationLevel);
    final step = AdaptiveReminderPolicy.nextStep(
      cadence: cadence,
      currentEscalationLevel: currentLevel,
      emergencyBypass: reminder.emergencyBypass,
    );
    if (step.enableNonEssentialActionGate) {
      final title = reminder.taskTitle?.trim();
      if (title != null && title.isNotEmpty) {
        return 'Action needed for "$title": start now or submit a logical reason.';
      }
      return 'Action needed: start now or submit a logical reason to continue.';
    }
    if (step.requireAppOpenNudge) {
      final title = reminder.taskTitle?.trim();
      if (title != null && title.isNotEmpty) {
        return 'Please open Coach for Life: start "$title" or provide a logical reason.';
      }
      return 'Please open Coach for Life: start this task or provide a logical reason.';
    }
    final title = reminder.taskTitle?.trim();
    if (title != null && title.isNotEmpty) return 'Time to start "$title".';
    return 'Time to start your planned task.';
  }
}
