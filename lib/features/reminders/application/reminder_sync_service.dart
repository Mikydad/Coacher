import 'package:flutter/foundation.dart';

import '../../../core/notifications/local_notifications_service.dart';
import '../data/reminder_cache_store.dart';
import '../data/reminder_repository.dart';
import '../domain/models/reminder_config.dart';

class ReminderSyncService {
  ReminderSyncService({
    required ReminderRepository repository,
    required ReminderCacheStore cacheStore,
    required LocalNotificationsService notifications,
  }) : _repository = repository,
       _cacheStore = cacheStore,
       _notifications = notifications;

  final ReminderRepository _repository;
  final ReminderCacheStore _cacheStore;
  final LocalNotificationsService _notifications;

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

  Future<void> _applyReminders(List<ReminderConfig> reminders) async {
    for (final reminder in reminders) {
      final id = _notifications.idFromTaskId(reminder.taskId);
      await _notifications.cancel(id);
      if (!reminder.enabled || reminder.scheduledAtIso == null) continue;
      final when = DateTime.tryParse(reminder.scheduledAtIso!);
      if (when == null) continue;
      debugPrint('Scheduling reminder: task=${reminder.taskId} at=$when notifId=$id');
      await _notifications.schedule(
        id: id,
        title: 'Task Reminder',
        body: 'Time to start your planned task.',
        when: when,
      );
    }
  }
}
