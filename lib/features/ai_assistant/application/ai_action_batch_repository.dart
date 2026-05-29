import 'package:isar/isar.dart';

import '../../../core/local_db/isar_collections/isar_ai_action_batch.dart';
import 'ai_action_batch_state.dart';

/// Plain-Dart repository for persisting [IsarAiActionBatch] records.
///
/// Enables idempotency checks, undo, and history display in the AI screen.
class AiActionBatchRepository {
  const AiActionBatchRepository(this._isar);

  final Isar _isar;

  // ── Write operations ────────────────────────────────────────────────────────

  /// Persist a new batch record.
  Future<void> createBatch(IsarAiActionBatch batch) async {
    await _isar.writeTxn(() async {
      await _isar.isarAiActionBatchs.put(batch);
    });
  }

  /// Transition a batch to a new [state] and optionally update action ID lists
  /// and the [undoneAtMs] timestamp.
  Future<void> updateState(
    String batchId,
    AiActionBatchState state, {
    List<String>? succeeded,
    List<String>? failed,
    int? undoneAtMs,
  }) async {
    final existing = await findByBatchId(batchId);
    if (existing == null) return;

    existing
      ..state = state.name
      ..updatedAtMs = DateTime.now().millisecondsSinceEpoch;

    if (succeeded != null) existing.succeededActionIds = succeeded;
    if (failed != null) existing.failedActionIds = failed;
    if (undoneAtMs != null) existing.undoneAtMs = undoneAtMs;

    await _isar.writeTxn(() async {
      await _isar.isarAiActionBatchs.put(existing);
    });
  }

  // ── Read operations ─────────────────────────────────────────────────────────

  /// Find a batch by its UUID [batchId] (idempotency check).
  Future<IsarAiActionBatch?> findByBatchId(String batchId) async {
    return _isar.isarAiActionBatchs
        .where()
        .batchIdEqualTo(batchId)
        .findFirst();
  }

  /// Find the most recently created batch (for undo and history display).
  Future<IsarAiActionBatch?> findMostRecent() async {
    return _isar.isarAiActionBatchs
        .where()
        .sortByCreatedAtMsDesc()
        .findFirst();
  }

  /// List the most recent [limit] batches, newest first (for history UI).
  Future<List<IsarAiActionBatch>> listRecent({int limit = 5}) async {
    return _isar.isarAiActionBatchs
        .where()
        .sortByCreatedAtMsDesc()
        .limit(limit)
        .findAll();
  }

  // ── Maintenance ─────────────────────────────────────────────────────────────

  /// Delete batches older than 7 days or when total count exceeds 20.
  Future<void> pruneOld() async {
    final cutoffMs =
        DateTime.now().subtract(const Duration(days: 7)).millisecondsSinceEpoch;

    // Delete by age first.
    await _isar.writeTxn(() async {
      await _isar.isarAiActionBatchs
          .where()
          .createdAtMsLessThan(cutoffMs)
          .deleteAll();
    });

    // Then enforce count limit: keep only the 20 most recent.
    final all = await _isar.isarAiActionBatchs
        .where()
        .sortByCreatedAtMsDesc()
        .findAll();
    if (all.length > 20) {
      final toDelete = all.sublist(20).map((b) => b.id).toList();
      await _isar.writeTxn(() async {
        await _isar.isarAiActionBatchs.deleteAll(toDelete);
      });
    }
  }
}
