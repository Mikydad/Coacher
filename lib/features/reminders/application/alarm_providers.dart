import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';

import '../../../core/local_db/isar_collections/isar_reminder.dart';
import '../../../core/offline/offline_store.dart';
import '../domain/models/reminder_alert_mode.dart';

/// Task ids whose enabled reminder rings as an alarm (feat/alarm-mode).
///
/// An Isar watch stream, so a task row's alarm glyph updates the instant the
/// editor saves — the local write IS the update (CLAUDE.md). Empty until
/// Isar is open, which is only ever the first frames of a cold start.
final alarmTaskIdsProvider = StreamProvider<Set<String>>((ref) {
  final isar = OfflineStore.instance.isar;
  if (isar == null) return Stream.value(const <String>{});
  return isar.isarReminders
      .filter()
      .enabledEqualTo(true)
      .alertModeEqualTo(ReminderAlertMode.alarm.toStorage())
      .watch(fireImmediately: true)
      .map((rows) => {for (final r in rows) r.taskId});
});
