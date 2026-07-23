import 'package:isar_community/isar.dart';

import '../../../core/firebase/firestore_paths.dart';
import '../../../core/local_db/isar_collections/isar_intention.dart';
import '../../../core/offline/offline_store.dart';
import '../../../core/sync/outbox_writer.dart';
import '../domain/models/intention.dart';

/// Local-first intentions: Isar is the source of truth, replication happens
/// through the outbox (push) and RemoteIsarMerge (pull, LWW on updatedAtMs).
/// Deletion is a soft tombstone (`active: false`) — the row stays for LWW.
class IntentionsRepository {
  IntentionsRepository();

  Isar get _isar => OfflineStore.instance.isar!;

  static int _now() => DateTime.now().millisecondsSinceEpoch;

  Stream<List<Intention>> watchIntentions() {
    return _isar.isarIntentions
        .where()
        .sortByUpdatedAtMsDesc()
        .watch(fireImmediately: true)
        .map(
          (rows) => rows
              .map((e) => e.toDomain())
              .where((i) => i.active)
              .toList(growable: false),
        );
  }

  Future<List<Intention>> fetchIntentionsOnce() async {
    final rows = await _isar.isarIntentions
        .where()
        .sortByUpdatedAtMsDesc()
        .findAll();
    return rows
        .map((e) => e.toDomain())
        .where((i) => i.active)
        .toList(growable: false);
  }

  Future<Intention?> getIntention(String intentionId) async {
    final row = await _isar.isarIntentions
        .filter()
        .intentionIdEqualTo(intentionId)
        .findFirst();
    final domain = row?.toDomain();
    if (domain == null || !domain.active) return null;
    return domain;
  }

  Future<void> upsertIntention(Intention intention) async {
    intention.validate();
    await _isar.writeTxn(() async {
      await _isar.isarIntentions.putByIntentionId(
        IsarIntention.fromDomain(intention),
      );
    });
    await outboxUpsert(
      entityType: 'intention',
      documentPath: FirestorePaths.intentionDocument(intention.id),
      payload: intention.toMap(),
    );
  }

  /// Status transition that re-stamps updatedAtMs and replicates.
  Future<Intention?> updateStatus(
    String intentionId,
    IntentionStatus status, {
    int? completedAtMs,
    bool bumpNudgeCount = false,
    bool bumpSnoozeCount = false,
  }) async {
    final current = await getIntention(intentionId);
    if (current == null) return null;
    final updated = current.copyWith(
      status: status,
      completedAtMs: completedAtMs ?? current.completedAtMs,
      nudgeCount: bumpNudgeCount ? current.nudgeCount + 1 : null,
      snoozeCount: bumpSnoozeCount ? current.snoozeCount + 1 : null,
      updatedAtMs: _now(),
    );
    await upsertIntention(updated);
    return updated;
  }

  /// Soft delete: tombstone row kept locally + replicated so the delete
  /// wins LWW against stale edits from other devices.
  Future<void> deleteIntention(String intentionId) async {
    final row = await _isar.isarIntentions
        .filter()
        .intentionIdEqualTo(intentionId)
        .findFirst();
    if (row == null) return;
    final tombstone = row.toDomain().copyWith(
      active: false,
      updatedAtMs: _now(),
    );
    await _isar.writeTxn(() async {
      await _isar.isarIntentions.putByIntentionId(
        IsarIntention.fromDomain(tombstone),
      );
    });
    await outboxUpsert(
      entityType: 'intention',
      documentPath: FirestorePaths.intentionDocument(intentionId),
      payload: tombstone.toMap(),
    );
  }
}
