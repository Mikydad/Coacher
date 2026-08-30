import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/firebase/firestore_paths.dart';
import '../domain/models/reminder_occurrence.dart';

/// Parses a Firestore occurrence document (falls back to the doc id).
ReminderOccurrence reminderOccurrenceFromFirestoreDoc(
  QueryDocumentSnapshot<Map<String, dynamic>> doc,
) {
  final m = Map<String, dynamic>.from(doc.data());
  final fieldId = m['id'];
  m['id'] = fieldId is String && fieldId.trim().isNotEmpty
      ? fieldId.trim()
      : doc.id;
  return ReminderOccurrence.fromMap(m);
}

abstract class ReminderOccurrenceRepository {
  /// Live view of everything the state machine still owns — anything not
  /// `resolved`. Backs the Recovery Card, so it must be a watch stream, not a
  /// refetch (CLAUDE.md: the local write IS the update).
  Stream<List<ReminderOccurrence>> watchUnresolved();

  /// Live view of one entity's occurrences, newest first.
  Stream<List<ReminderOccurrence>> watchForEntity(String entityId);

  Future<List<ReminderOccurrence>> listUnresolved();

  /// Every occurrence for [entityId], resolved or not.
  Future<List<ReminderOccurrence>> listForEntity(String entityId);

  /// The occurrence for this entity on this local day, if one exists.
  Future<ReminderOccurrence?> findByKey({
    required String entityKind,
    required String entityId,
    required String dateKey,
  });

  /// Occurrences scheduled in `[startMs, endMs)`, any state.
  Future<List<ReminderOccurrence>> listInRange({
    required int startMs,
    required int endMs,
  });

  Future<void> upsert(ReminderOccurrence occurrence);

  /// Batch upsert — the [L-ALIVE] sweep writes its whole changed set at once.
  Future<void> upsertAll(Iterable<ReminderOccurrence> occurrences);

  /// Removes every occurrence for a deleted entity, locally and remotely.
  Future<void> deleteForEntity(String entityId);

  /// Drops resolved occurrences older than [age]. History is useful for the
  /// resolution-rate metric, not forever.
  Future<void> pruneResolvedOlderThan(Duration age);
}

/// Read-through for the remote tree. Writes go through the outbox in
/// [IsarReminderOccurrenceRepository]; this exists so the merge phase and a
/// remote-only fallback share one parse.
class FirestoreReminderOccurrenceRepository {
  Future<List<ReminderOccurrence>> fetchAll() async {
    final snap = await FirebaseFirestore.instance
        .collection(FirestorePaths.reminderOccurrences)
        .get();
    return snap.docs.map(reminderOccurrenceFromFirestoreDoc).toList();
  }
}
