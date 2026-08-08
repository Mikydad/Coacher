import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/tier/tier_providers.dart';
import '../../../core/tier/upgrade_prompt.dart';
import '../../../core/utils/stable_id.dart';
import '../../reminders/domain/models/reminder_config.dart';

/// Reminder-toggle side effect: request notification permission and surface a
/// snackbar when it is denied. (Persistence for the save path lives beside
/// this — see `persistAddTaskReminder`.)
Future<void> ensureReminderPermissionWithNotice(
  BuildContext context,
  WidgetRef ref,
) async {
  final ok = await ref.read(reminderSyncServiceProvider).ensurePermissions();
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notification permission is disabled.')),
    );
  }
}

/// Upserts the task's reminder config and syncs notifications (save path).
/// Returns the persisted reminder id, or null when the free-tier gate withheld
/// a NEW reminder — the task itself is already saved; only the reminder is
/// skipped, and the tier sheet is shown here.
Future<String?> persistAddTaskReminder(
  BuildContext context,
  WidgetRef ref, {
  required String taskId,
  required String taskTitle,
  required String routineId,
  required String blockId,
  required String modeRefId,
  required bool reminderEnabled,
  required DateTime reminderTime,
  String? existingReminderId,
  int? reminderCreatedAtMs,
}) async {
  // New enabled reminder = one more active configuration — gate it (the
  // task itself is already saved; only the reminder is withheld).
  if (existingReminderId == null && reminderEnabled) {
    final tierGate = ref.read(tierGateProvider);
    if (!tierGate.isBypassed) {
      final all = await ref.read(reminderRepositoryProvider).listAllReminders();
      final activeCount = all.where((r) => r.enabled).length;
      if (!tierGate.canCreateReminder(activeCount)) {
        if (context.mounted) {
          await showTierLimitSheet(
            context,
            title: 'Reminder limit reached',
            message:
                'The free plan includes ${tierGate.limits.freeReminders} '
                'active reminders, so this task was saved without one. '
                'SidePal Pro removes the limit.',
          );
        }
        return null;
      }
    }
  }
  var blockUrgency = 50;
  try {
    final planning = ref.read(planningRepositoryProvider);
    final blocks = await planning.getBlocks(routineId);
    for (final b in blocks) {
      if (b.id == blockId) {
        blockUrgency = b.urgencyScore;
        break;
      }
    }
  } catch (e) {
    debugPrint('add_task_reminder_persistence: swallowed error: $e');
  }

  final now = DateTime.now().millisecondsSinceEpoch;
  final createdAt = reminderCreatedAtMs ?? now;
  final reminder = ReminderConfig(
    id: existingReminderId ?? StableId.generate('reminder'),
    taskId: taskId,
    taskTitle: taskTitle,
    enabled: reminderEnabled,
    scheduledAtIso: reminderEnabled ? reminderTime.toIso8601String() : null,
    modeRefId: modeRefId,
    blockUrgencyScore: blockUrgency,
    createdAtMs: createdAt,
    updatedAtMs: now,
  );
  await ref.read(reminderRepositoryProvider).upsertReminder(reminder);
  await ref.read(reminderSyncServiceProvider).syncForTaskIds([taskId]);
  return reminder.id;
}
