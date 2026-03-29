import 'package:flutter/foundation.dart';

import '../../../core/notifications/local_notifications_service.dart';
import 'adaptive_reminder_policy.dart';
import '../data/reminder_cache_store.dart';
import '../data/reminder_repository.dart';
import '../domain/models/reminder_config.dart';

abstract class ReminderNotificationsPort {
  Future<bool> requestPermissionsIfNeeded();
  int idFromTaskId(String taskId);
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
  int idFromTaskId(String taskId) => _inner.idFromTaskId(taskId);

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
    required ReminderCacheStore cacheStore,
    required ReminderNotificationsPort notifications,
    DateTime Function()? now,
  }) : _repository = repository,
       _cacheStore = cacheStore,
       _notifications = notifications,
       _now = now ?? DateTime.now;

  final ReminderRepository _repository;
  final ReminderCacheStore _cacheStore;
  final ReminderNotificationsPort _notifications;
  final DateTime Function() _now;

  Future<bool> ensurePermissions() => _notifications.requestPermissionsIfNeeded();

  Future<void> syncForTaskIds(List<String> taskIds) async {
    final reminders = await _repository.getRemindersForTasks(taskIds);
    await _cacheStore.save(reminders);
    await _applyReminders(reminders);
  }

  Future<void> scheduleFromCache() async {
    final reminders = await _cacheStore.load();
    await _applyReminders(reminders);
  }

  Future<void> markTaskStarted(String taskId) => _resolveReminder(taskId, keepEnabled: false);

  Future<void> markLogicalReasonProvided(String taskId) => _resolveReminder(taskId, keepEnabled: false);

  Future<void> requestSnooze(String taskId, {bool emergencyBypass = false}) async {
    final reminders = await _cacheStore.load();
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
    await _cacheStore.save(reminders);
    await _upsertQuietly(updated);
    await _applyReminders(reminders);
  }

  Future<void> _resolveReminder(String taskId, {required bool keepEnabled}) async {
    final reminders = await _cacheStore.load();
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
    await _cacheStore.save(reminders);
    await _upsertQuietly(updated);
    await _notifications.cancel(_notifications.idFromTaskId(taskId));
    if (keepEnabled) {
      await _applyReminders(reminders);
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
      final id = _notifications.idFromTaskId(reminder.taskId);
      await _notifications.cancel(id);
      if (!reminder.enabled) continue;
      final when = _nextReminderTime(reminder);
      if (when == null) continue;
      debugPrint(
        'Scheduling reminder: task=${reminder.taskId} at=$when notifId=$id escalation=${reminder.escalationLevel}',
      );
      try {
        await _notifications.schedule(
          id: id,
          title: 'Task Reminder',
          body: _bodyForReminder(reminder),
          when: when,
          payload: 'task:${Uri.encodeComponent(reminder.taskId)}',
        );
      } catch (e, st) {
        debugPrint('Reminder schedule failed: task=${reminder.taskId} error=$e');
        debugPrint('$st');
      }
    }
  }

  DateTime? _nextReminderTime(ReminderConfig reminder) {
    final now = _now();
    final preferred = reminder.pendingAction ? reminder.nextPromptAtIso : reminder.scheduledAtIso;
    final parsed = preferred == null ? null : DateTime.tryParse(preferred);
    if (parsed != null && parsed.isAfter(now)) return parsed;

    // Stale schedule recovery: if action is pending, compute a new adaptive prompt.
    if (!reminder.pendingAction) return parsed;
    final cadence = AdaptiveReminderPolicy.cadenceFor(
      modeRefId: reminder.modeRefId,
      blockUrgencyScore: reminder.blockUrgencyScore,
    );
    return now.add(Duration(minutes: cadence.initialSnoozeMinutes));
  }

  String _bodyForReminder(ReminderConfig reminder) {
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
      return 'Action needed: start now or submit a logical reason to continue.';
    }
    if (step.requireAppOpenNudge) {
      return 'Please open Coach for Life: start this task or provide a logical reason.';
    }
    return 'Time to start your planned task.';
  }
}
