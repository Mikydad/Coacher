import 'package:isar_community/isar.dart';

import '../../../core/firebase/firestore_paths.dart';
import '../../../core/local_db/isar_collections/isar_memory_fact.dart';
import '../../../core/offline/offline_store.dart';
import '../../../core/sync/outbox_writer.dart';
import '../domain/models/memory_fact.dart';

/// Local-first memory facts: Isar is the source of truth, replication
/// through the outbox (push) and RemoteIsarMerge (pull, LWW on updatedAtMs).
/// Delete/deactivate is a soft tombstone (`active: false`).
class MemoryFactsRepository {
  MemoryFactsRepository();

  Isar get _isar => OfflineStore.instance.isar!;

  static int _now() => DateTime.now().millisecondsSinceEpoch;

  /// All live facts, newest-updated first.
  Stream<List<MemoryFact>> watchFacts() {
    return _isar.isarMemoryFacts
        .where()
        .sortByUpdatedAtMsDesc()
        .watch(fireImmediately: true)
        .map(
          (rows) => rows
              .map((e) => e.toDomain())
              .where((f) => f.active)
              .toList(growable: false),
        );
  }

  Future<List<MemoryFact>> fetchFactsOnce() async {
    final rows = await _isar.isarMemoryFacts
        .where()
        .sortByUpdatedAtMsDesc()
        .findAll();
    return rows
        .map((e) => e.toDomain())
        .where((f) => f.active)
        .toList(growable: false);
  }

  Future<MemoryFact?> getFact(String factId) async {
    final row = await _isar.isarMemoryFacts
        .filter()
        .factIdEqualTo(factId)
        .findFirst();
    final domain = row?.toDomain();
    if (domain == null || !domain.active) return null;
    return domain;
  }

  Future<List<MemoryFact>> factsForPerson(String personId) async {
    final rows = await _isar.isarMemoryFacts
        .filter()
        .personIdEqualTo(personId)
        .findAll();
    return rows
        .map((e) => e.toDomain())
        .where((f) => f.active)
        .toList(growable: false);
  }

  Future<void> upsertFact(MemoryFact fact) async {
    fact.validate();
    await _isar.writeTxn(() async {
      await _isar.isarMemoryFacts.putByFactId(IsarMemoryFact.fromDomain(fact));
    });
    await outboxUpsert(
      entityType: 'memoryFact',
      documentPath: FirestorePaths.memoryFactDocument(fact.id),
      payload: fact.toMap(),
    );
  }

  /// ✓ Correct on an inferred fact — promotes provenance to userConfirmed.
  Future<MemoryFact?> confirmFact(String factId) async {
    final current = await getFact(factId);
    if (current == null) return null;
    final updated = current.copyWith(
      provenance: MemoryProvenance.userConfirmed,
      confidence: 1.0,
      updatedAtMs: _now(),
    );
    await upsertFact(updated);
    return updated;
  }

  /// Registers a contradiction; the second one deactivates the fact (§5.2).
  Future<MemoryFact?> registerContradiction(String factId) async {
    final current = await getFact(factId);
    if (current == null) return null;
    final count = current.contradictionCount + 1;
    final updated = current.copyWith(
      contradictionCount: count,
      active: count < 2,
      updatedAtMs: _now(),
    );
    await upsertFact(updated);
    return updated;
  }

  /// Stamps [MemoryFact.lastReferencedAtMs] after payload injection.
  ///
  /// STRICTLY LOCAL: neither bumps [MemoryFact.updatedAtMs] nor writes the
  /// outbox. Replicating a whole fact on every chat turn would let a stale
  /// copy from one device win LWW over an explicit user edit (✓ Correct /
  /// ✏ Edit / 🗑 Forget) made on another. The stamp is a ranking hint —
  /// per-device divergence is fine, and a remote pull overwriting it only
  /// resets a hint.
  Future<void> markReferenced(List<String> factIds) async {
    final now = _now();
    for (final id in factIds) {
      final current = await getFact(id);
      if (current == null) continue;
      final stamped = current.copyWith(lastReferencedAtMs: now);
      await _isar.writeTxn(() async {
        await _isar.isarMemoryFacts.putByFactId(
          IsarMemoryFact.fromDomain(stamped),
        );
      });
    }
  }

  /// Soft delete: tombstone kept + replicated so it wins LWW.
  Future<void> deleteFact(String factId) async {
    final row = await _isar.isarMemoryFacts
        .filter()
        .factIdEqualTo(factId)
        .findFirst();
    if (row == null) return;
    final tombstone = row.toDomain().copyWith(
      active: false,
      updatedAtMs: _now(),
    );
    await _isar.writeTxn(() async {
      await _isar.isarMemoryFacts.putByFactId(
        IsarMemoryFact.fromDomain(tombstone),
      );
    });
    await outboxUpsert(
      entityType: 'memoryFact',
      documentPath: FirestorePaths.memoryFactDocument(factId),
      payload: tombstone.toMap(),
    );
  }

  /// "Forget everything" — tombstones every live fact.
  Future<void> deleteAllFacts() async {
    final live = await fetchFactsOnce();
    for (final fact in live) {
      await deleteFact(fact.id);
    }
  }
}
