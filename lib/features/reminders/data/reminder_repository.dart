import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/firebase/firestore_paths.dart';
import '../../../core/sync/sync_service.dart';
import '../domain/models/reminder_config.dart';

/// Parses a Firestore reminder document (uses [QueryDocumentSnapshot.id] when `id` is absent).
ReminderConfig reminderConfigFromFirestoreDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
  final m = Map<String, dynamic>.from(doc.data());
  m['createdAtMs'] = (m['createdAtMs'] as num?)?.toInt() ?? 0;
  m['updatedAtMs'] = (m['updatedAtMs'] as num?)?.toInt() ?? 0;
  final fieldId = m['id'];
  final id = fieldId is String && fieldId.trim().isNotEmpty
      ? fieldId.trim()
      : (fieldId != null && '$fieldId'.trim().isNotEmpty ? '$fieldId'.trim() : doc.id);
  m['id'] = id;
  return ReminderConfig.fromMap(m);
}

abstract class ReminderRepository {
  /// All reminders stored locally (e.g. Isar).
  Future<List<ReminderConfig>> listAllReminders();

  Future<List<ReminderConfig>> getRemindersForTasks(List<String> taskIds);

  /// Merges Firestore rows for [taskIds] into local storage (LWW on [updatedAtMs]).
  /// No-op for purely remote repositories.
  Future<void> hydrateFromRemoteForTasks(List<String> taskIds);

  Future<void> upsertReminder(ReminderConfig reminder);
}

class FirestoreReminderRepository implements ReminderRepository {
  @override
  Future<List<ReminderConfig>> listAllReminders() async {
    final snap = await FirebaseFirestore.instance.collection(FirestorePaths.reminders).get();
    return snap.docs.map(reminderConfigFromFirestoreDoc).toList();
  }

  @override
  Future<void> hydrateFromRemoteForTasks(List<String> taskIds) async {}

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
      result.addAll(snap.docs.map(reminderConfigFromFirestoreDoc));
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
