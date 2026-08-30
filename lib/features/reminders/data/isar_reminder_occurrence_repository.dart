import 'package:isar_community/isar.dart';

import '../../../core/firebase/firestore_paths.dart';
import '../../../core/local_db/isar_collections/isar_reminder_occurrence.dart';
import '../../../core/offline/offline_store.dart';
import '../../../core/sync/outbox_writer.dart';
import '../domain/models/reminder_occurrence.dart';
import '../domain/models/reminder_occurrence_enums.dart';
import 'reminder_occurrence_repository.dart';

/// Local-first reminder occurrences: Isar is the source of truth, Firestore is
/// background replication through the outbox (never awaited on an interaction
/// path), last-write-wins on `updatedAtMs`.
class IsarReminderOccurrenceRepository
    implements ReminderOccurrenceRepository {
  const IsarReminderOccurrenceRepository();

  Isar get _isar => OfflineStore.instance.isar!;

  static const String _entityType = 'reminderOccurrence';

  static final String _resolvedState =
      ReminderOccurrenceState.resolved.toStorage();

  @override
  Stream<List<ReminderOccurrence>> watchUnresolved() {
    return _isar.isarReminderOccurrences
        .filter()
        .not()
        .stateEqualTo(_resolvedState)
        .sortByScheduledAtMs()
        .watch(fireImmediately: true)
        .map((rows) => rows.map((e) => e.toDomain()).toList());
  }

  @override
  Stream<List<ReminderOccurrence>> watchForEntity(String entityId) {
    return _isar.isarReminderOccurrences
        .filter()
        .entityIdEqualTo(entityId)
        .sortByScheduledAtMsDesc()
        .watch(fireImmediately: true)
        .map((rows) => rows.map((e) => e.toDomain()).toList());
  }

  @override
  Future<List<ReminderOccurrence>> listUnresolved() async {
    final rows = await _isar.isarReminderOccurrences
        .filter()
        .not()
        .stateEqualTo(_resolvedState)
        .sortByScheduledAtMs()
        .findAll();
    return rows.map((e) => e.toDomain()).toList();
  }

  @override
  Future<List<ReminderOccurrence>> listForEntity(String entityId) async {
    final rows = await _isar.isarReminderOccurrences
        .filter()
        .entityIdEqualTo(entityId)
        .sortByScheduledAtMsDesc()
        .findAll();
    return rows.map((e) => e.toDomain()).toList();
  }

  @override
  Future<ReminderOccurrence?> findByKey({
    required String entityKind,
    required String entityId,
    required String dateKey,
  }) async {
    final row = await _isar.isarReminderOccurrences
        .filter()
        .occurrenceKeyEqualTo(
          ReminderOccurrence.keyFor(entityKind, entityId, dateKey),
        )
        .findFirst();
    return row?.toDomain();
  }

  @override
  Future<List<ReminderOccurrence>> listInRange({
    required int startMs,
    required int endMs,
  }) async {
    final rows = await _isar.isarReminderOccurrences
        .filter()
        .scheduledAtMsBetween(startMs, endMs, includeUpper: false)
        .sortByScheduledAtMs()
        .findAll();
    return rows.map((e) => e.toDomain()).toList();
  }

  @override
  Future<void> upsert(ReminderOccurrence occurrence) async {
    occurrence.validate();
    await _isar.writeTxn(() async {
      await _isar.isarReminderOccurrences.putByOccurrenceKey(
        IsarReminderOccurrence.fromDomain(occurrence),
      );
    });
    await _replicate(occurrence);
  }

  @override
  Future<void> upsertAll(Iterable<ReminderOccurrence> occurrences) async {
    final list = occurrences.toList(growable: false);
    if (list.isEmpty) return;
    for (final o in list) {
      o.validate();
    }
    // One transaction for the whole sweep: an [L-ALIVE] pass that moves
    // twenty occurrences to overdue should be one write, not twenty.
    await _isar.writeTxn(() async {
      await _isar.isarReminderOccurrences.putAllByOccurrenceKey(
        list.map(IsarReminderOccurrence.fromDomain).toList(),
      );
    });
    for (final o in list) {
      await _replicate(o);
    }
  }

  @override
  Future<void> deleteForEntity(String entityId) async {
    final rows = await _isar.isarReminderOccurrences
        .filter()
        .entityIdEqualTo(entityId)
        .findAll();
    if (rows.isEmpty) return;
    await _isar.writeTxn(() async {
      await _isar.isarReminderOccurrences.deleteAll(
        rows.map((r) => r.id).toList(),
      );
    });
    for (final row in rows) {
      await outboxDelete(
        entityType: _entityType,
        documentPath:
            '${FirestorePaths.reminderOccurrences}/${row.occurrenceId}',
      );
    }
  }

  @override
  Future<void> pruneResolvedOlderThan(Duration age) async {
    final cutoffMs = DateTime.now().subtract(age).millisecondsSinceEpoch;
    final rows = await _isar.isarReminderOccurrences
        .filter()
        .stateEqualTo(_resolvedState)
        .scheduledAtMsLessThan(cutoffMs)
        .findAll();
    if (rows.isEmpty) return;
    // Local-only prune: the remote tree keeps the history the resolution-rate
    // metric reads, and re-pulling it is bounded by the merge cursor.
    await _isar.writeTxn(() async {
      await _isar.isarReminderOccurrences.deleteAll(
        rows.map((r) => r.id).toList(),
      );
    });
  }

  Future<void> _replicate(ReminderOccurrence o) => outboxUpsert(
    entityType: _entityType,
    documentPath: '${FirestorePaths.reminderOccurrences}/${o.id}',
    payload: o.toMap(),
  );
}
