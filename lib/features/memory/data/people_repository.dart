import 'package:isar_community/isar.dart';

import '../../../core/firebase/firestore_paths.dart';
import '../../../core/local_db/isar_collections/isar_person.dart';
import '../../../core/offline/offline_store.dart';
import '../../../core/sync/outbox_writer.dart';
import '../domain/models/person.dart';

/// Local-first people: same sync contract as memory facts (outbox push,
/// RemoteIsarMerge pull, LWW, soft tombstone).
class PeopleRepository {
  PeopleRepository();

  Isar get _isar => OfflineStore.instance.isar!;

  static int _now() => DateTime.now().millisecondsSinceEpoch;

  Stream<List<Person>> watchPeople() {
    return _isar.isarPersons
        .where()
        .sortByUpdatedAtMsDesc()
        .watch(fireImmediately: true)
        .map(
          (rows) => rows
              .map((e) => e.toDomain())
              .where((p) => p.active)
              .toList(growable: false),
        );
  }

  Future<List<Person>> fetchPeopleOnce() async {
    final rows = await _isar.isarPersons
        .where()
        .sortByUpdatedAtMsDesc()
        .findAll();
    return rows
        .map((e) => e.toDomain())
        .where((p) => p.active)
        .toList(growable: false);
  }

  Future<Person?> getPerson(String personId) async {
    final row = await _isar.isarPersons
        .filter()
        .personIdEqualTo(personId)
        .findFirst();
    final domain = row?.toDomain();
    if (domain == null || !domain.active) return null;
    return domain;
  }

  /// Case-insensitive lookup by display name or alias — extraction dedupe
  /// ("my sister Sarah" must not create a second Sarah).
  Future<Person?> findByReference(String reference) async {
    final needle = reference.trim().toLowerCase();
    if (needle.isEmpty) return null;
    final people = await fetchPeopleOnce();
    for (final p in people) {
      if (p.displayName.toLowerCase() == needle) return p;
    }
    for (final p in people) {
      if (p.aliases.any((a) => a.toLowerCase() == needle)) return p;
    }
    return null;
  }

  Future<void> upsertPerson(Person person) async {
    person.validate();
    await _isar.writeTxn(() async {
      await _isar.isarPersons.putByPersonId(IsarPerson.fromDomain(person));
    });
    await outboxUpsert(
      entityType: 'person',
      documentPath: FirestorePaths.personDocument(person.id),
      payload: person.toMap(),
    );
  }

  /// Deterministic [Person.lastInteractionAtMs] bump — called when an
  /// intention referencing this person completes, or a conversation
  /// mentions them. Never LLM-estimated. Monotonic: an older timestamp
  /// never overwrites a newer one.
  Future<void> recordInteraction(String personId, int atMs) async {
    final current = await getPerson(personId);
    if (current == null) return;
    if (current.lastInteractionAtMs != null &&
        current.lastInteractionAtMs! >= atMs) {
      return;
    }
    await upsertPerson(
      current.copyWith(lastInteractionAtMs: atMs, updatedAtMs: _now()),
    );
  }

  /// Soft delete: tombstone kept + replicated so it wins LWW.
  Future<void> deletePerson(String personId) async {
    final row = await _isar.isarPersons
        .filter()
        .personIdEqualTo(personId)
        .findFirst();
    if (row == null) return;
    final tombstone = row.toDomain().copyWith(
      active: false,
      updatedAtMs: _now(),
    );
    await _isar.writeTxn(() async {
      await _isar.isarPersons.putByPersonId(IsarPerson.fromDomain(tombstone));
    });
    await outboxUpsert(
      entityType: 'person',
      documentPath: FirestorePaths.personDocument(personId),
      payload: tombstone.toMap(),
    );
  }
}
