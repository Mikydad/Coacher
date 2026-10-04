import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/tier/tier_providers.dart';
import '../../../core/tier/upgrade_prompt.dart';
import '../../../core/utils/stable_id.dart';
import '../../planning/domain/sleep_task.dart';
import '../../reminders/application/alarm_kit_channel.dart';
import '../../reminders/application/reminder_classifier.dart';
import '../../reminders/domain/models/reminder_alert_mode.dart';
import '../../reminders/domain/models/reminder_config.dart';
import '../../reminders/domain/models/reminder_occurrence_enums.dart';

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

/// Alarm mode (2026-10-04): on iOS 26+ the first alarm switched on or saved
/// asks once to let SidePal schedule real alarms (AlarmKit — rings through
/// silent mode, Stop on the lock screen). Any standing answer, or no
/// AlarmKit at all, returns at once: no prompt, no wait. A "no" keeps the
/// notification rings.
Future<void> ensureAlarmKitPermission(WidgetRef ref) async {
  final kit = ref.read(alarmKitProvider);
  if (await kit.authorizationStatus() != AlarmKitAuthorization.notDetermined) {
    return;
  }
  await kit.requestAuthorization();
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

  /// Classification inputs (FR-R-20). Optional so callers that predate the
  /// classifier keep compiling; absent, the heuristic still runs on the title.
  int? durationMinutes,
  String? category,
  bool isHabitAnchor = false,

  /// A classification the USER chose in the editor. When present it wins and
  /// is stamped `ClassificationSource.user`, never to be overwritten by the
  /// heuristic or by AI (FR-R-21).
  ReminderTaxonomy? userTaxonomy,
  int? userCriticality,

  /// Alarm mode (feat/alarm-mode). For the Sleep category the alarm is the
  /// WAKE-UP — anchored at sleep end, i.e. `reminderTime + durationMinutes`;
  /// everything else rings at the reminder time itself.
  bool alarm = false,
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

  // Classify synchronously, offline, at save time (FR-R-20). The AI upgrade
  // (FR-R-22) refines this in the background later; it never blocks the save.
  final heuristic = ReminderClassifier.classify(
    title: taskTitle,
    hasReminderTime: reminderEnabled,
    durationMinutes: durationMinutes,
    category: category,
    isHabitAnchor: isHabitAnchor,
  );
  final userChose = userTaxonomy != null || userCriticality != null;

  // On edit this function rebuilds the config from scratch, which would reset
  // classificationSource to `heuristic` and quietly discard an earlier user
  // override. Carry the stored classification forward so withClassification
  // can see who last spoke (FR-R-21).
  ReminderConfig? previous;
  if (existingReminderId != null) {
    final all = await ref.read(reminderRepositoryProvider).listAllReminders();
    for (final r in all) {
      if (r.id == existingReminderId) {
        previous = r;
        break;
      }
    }
  }

  final alarmOffset = alarm && isSleepCategory(category)
      ? (durationMinutes ?? 0).clamp(0, 24 * 60)
      : 0;

  var reminder = ReminderConfig(
    id: existingReminderId ?? StableId.generate('reminder'),
    taskId: taskId,
    taskTitle: taskTitle,
    enabled: reminderEnabled,
    scheduledAtIso: reminderEnabled ? reminderTime.toIso8601String() : null,
    modeRefId: modeRefId,
    blockUrgencyScore: blockUrgency,
    alertMode: alarm
        ? ReminderAlertMode.alarm
        : ReminderAlertMode.notification,
    alarmOffsetMinutes: alarmOffset,
    taxonomy: previous?.taxonomy ?? ReminderTaxonomy.flexible,
    criticality: previous?.criticality ?? 1,
    classificationSource:
        previous?.classificationSource ?? ClassificationSource.heuristic,
    classifierVersion: previous?.classifierVersion,
    createdAtMs: createdAt,
    updatedAtMs: now,
  );

  // Precedence: the user's own choice, else the heuristic — and the heuristic
  // never overwrites an earlier user override (withClassification enforces
  // it). FR-R-23: neither path can touch `enabled`.
  reminder = reminder.withClassification(
    taxonomy: userTaxonomy ?? heuristic.taxonomy,
    criticality: userCriticality ?? heuristic.criticality,
    source: userChose
        ? ClassificationSource.user
        : ClassificationSource.heuristic,
    classifierVersion: userChose ? null : ReminderClassifier.version,
    updatedAtMs: now,
    force: userChose,
  );

  // AlarmKit (iOS 26+): ask before the sync arms the alarm, so a "yes" gets
  // a real system alarm on this very save. Covers Sleep's wake-up, which is
  // on by default and so never passes through the toggle's ask.
  if (alarm && reminderEnabled) await ensureAlarmKitPermission(ref);

  await ref.read(reminderRepositoryProvider).upsertReminder(reminder);
  await ref.read(reminderSyncServiceProvider).syncForTaskIds([taskId]);
  // FR-R-22: the AI upgrade rides behind the save, never on it. The sweep
  // batches every still-unclassified config in one call, degrades silently,
  // and cannot touch what the user chose above.
  unawaited(ref.read(reminderAiClassifierProvider).sweep());
  return reminder.id;
}
