import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:isar/isar.dart';

import '../../../core/firebase/firestore_paths.dart';
import '../../../core/local_db/isar_collections/isar_reminder.dart';
import '../../../core/offline/offline_store.dart';
import '../../../core/sync/sync_service.dart';
import '../domain/models/reminder_config.dart';
import 'reminder_repository.dart';

/// Local-first reminders: Isar reads/writes with Firestore sync (same paths as
/// [FirestoreReminderRepository]). Remote rows for specific tasks are merged
/// with last-write-wins on [ReminderConfig.updatedAtMs].
class IsarReminderRepository implements ReminderRepository {
  IsarReminderRepository(this._remoteReader);

  final ReminderRepository _remoteReader;

  Isar get _isar => OfflineStore.instance.isar!;

  Future<void> _mergeFromRemoteIfNewer(ReminderConfig incoming) async {
    final existing = await _isar.isarReminders.filter().reminderIdEqualTo(incoming.id).findFirst();
    if (existing != null && existing.updatedAtMs >= incoming.updatedAtMs) return;
    await _isar.writeTxn(() async {
      await _isar.isarReminders.putByReminderId(IsarReminder.fromDomain(incoming));
    });
  }

  @override
  Future<List<ReminderConfig>> listAllReminders() async {
    final rows = await _isar.isarReminders.where().findAll();
    return rows.map((e) => e.toDomain()).toList();
  }

  @override
  Future<List<ReminderConfig>> getRemindersForTasks(List<String> taskIds) async {
    if (taskIds.isEmpty) return const [];
    final idSet = taskIds.toSet();
    final rows = await _isar.isarReminders.where().findAll();
    return rows.where((r) => idSet.contains(r.taskId)).map((e) => e.toDomain()).toList();
  }

  @override
  Future<void> hydrateFromRemoteForTasks(List<String> taskIds) async {
    if (taskIds.isEmpty) return;
    final remote = await _remoteReader.getRemindersForTasks(taskIds);
    for (final r in remote) {
      await _mergeFromRemoteIfNewer(r);
    }
  }

  @override
  Future<void> upsertReminder(ReminderConfig reminder) async {
    reminder.validate();
    await _isar.writeTxn(() async {
      await _isar.isarReminders.putByReminderId(IsarReminder.fromDomain(reminder));
    });
    final path = '${FirestorePaths.reminders}/${reminder.id}';
    final payload = reminder.toMap();
    try {
      await FirebaseFirestore.instance.doc(path).set(payload, SetOptions(merge: true));
    } catch (_) {
      await SyncService.instance.enqueueUpsert(
        entityType: 'reminder',
        documentPath: path,
        payload: payload,
      );
    }
  }
}
