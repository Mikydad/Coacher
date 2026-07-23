import 'package:isar_community/isar.dart';

import '../../../core/local_db/isar_collections/isar_memory_session_state.dart';
import '../../../core/offline/offline_store.dart';

/// LOCAL-ONLY bookkeeping for summarize-then-purge (§5.2). No outbox, no
/// pull — this records what THIS device has extracted.
class MemorySessionStateRepository {
  MemorySessionStateRepository();

  Isar get _isar => OfflineStore.instance.isar!;

  static int _now() => DateTime.now().millisecondsSinceEpoch;

  Future<IsarMemorySessionState?> getBySessionId(String sessionId) {
    return _isar.isarMemorySessionStates
        .filter()
        .sessionIdEqualTo(sessionId)
        .findFirst();
  }

  /// Marks a session as awaiting extraction (idempotent; refreshes
  /// [lastInteractionAtMs] so the inactivity clock restarts on new turns).
  Future<void> markPending(String sessionId, int lastInteractionAtMs) async {
    final existing = await getBySessionId(sessionId);
    if (existing != null && existing.status != 'pending') return;
    final row = existing ?? (IsarMemorySessionState()..sessionId = sessionId);
    row
      ..status = 'pending'
      ..lastInteractionAtMs = lastInteractionAtMs
      ..attemptCount = existing?.attemptCount ?? 0
      ..updatedAtMs = _now();
    await _isar.writeTxn(() async {
      await _isar.isarMemorySessionStates.putBySessionId(row);
    });
  }

  Future<void> markExtracted(String sessionId) =>
      _setStatus(sessionId, 'extracted');

  Future<void> markTruncated(String sessionId) =>
      _setStatus(sessionId, 'truncated');

  Future<void> bumpAttemptCount(String sessionId) async {
    final row = await getBySessionId(sessionId);
    if (row == null) return;
    row
      ..attemptCount = row.attemptCount + 1
      ..updatedAtMs = _now();
    await _isar.writeTxn(() async {
      await _isar.isarMemorySessionStates.putBySessionId(row);
    });
  }

  Future<List<IsarMemorySessionState>> pendingSessions() {
    return _isar.isarMemorySessionStates
        .filter()
        .statusEqualTo('pending')
        .findAll();
  }

  /// Removes bookkeeping rows for sessions whose raw turns are gone.
  Future<void> deleteBefore(int cutoffMs) async {
    await _isar.writeTxn(() async {
      await _isar.isarMemorySessionStates
          .filter()
          .lastInteractionAtMsLessThan(cutoffMs)
          .not()
          .statusEqualTo('pending')
          .deleteAll();
    });
  }

  Future<void> _setStatus(String sessionId, String status) async {
    final row = await getBySessionId(sessionId);
    if (row == null) return;
    row
      ..status = status
      ..updatedAtMs = _now();
    await _isar.writeTxn(() async {
      await _isar.isarMemorySessionStates.putBySessionId(row);
    });
  }
}
