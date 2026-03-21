import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/firebase/firestore_paths.dart';
import '../../../core/sync/sync_service.dart';
import '../domain/models/reminder_config.dart';

abstract class ReminderRepository {
  Future<List<ReminderConfig>> getRemindersForTasks(List<String> taskIds);
  Future<void> upsertReminder(ReminderConfig reminder);
}

class FirestoreReminderRepository implements ReminderRepository {
  @override
  Future<List<ReminderConfig>> getRemindersForTasks(List<String> taskIds) async {
    if (taskIds.isEmpty) return const [];
    final result = <ReminderConfig>[];
    final chunks = <List<String>>[];
    for (var i = 0; i < taskIds.length; i += 10) {
      chunks.add(taskIds.sublist(i, i + 10 > taskIds.length ? taskIds.length : i + 10));
    }
    for (final chunk in chunks) {
      final snap = await FirebaseFirestore.instance
          .collection(FirestorePaths.reminders)
          .where('taskId', whereIn: chunk)
          .get();
      result.addAll(snap.docs.map((d) => ReminderConfig.fromMap(d.data())));
    }
    return result;
  }

  @override
  Future<void> upsertReminder(ReminderConfig reminder) async {
    reminder.validate();
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
