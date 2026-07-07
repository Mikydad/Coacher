import 'package:isar/isar.dart';

import '../local_db/isar_collections/isar_notification_ledger_entry.dart';
import 'notification_ledger_state.dart';

/// Plain-Dart repository for the notification ledger.
///
/// No Riverpod, no Flutter imports — takes an [Isar] instance in the
/// constructor and is injected wherever needed (e.g. [AttentionOrchestratorService],
/// [NotificationReconciliationService]).
class NotificationLedgerRepository {
  const NotificationLedgerRepository(this._isar);

  final Isar _isar;

  // ── Write operations ────────────────────────────────────────────────────────

  /// Insert or update a ledger entry. Uses Isar auto-increment id; callers
  /// should fetch an existing entry before upserting to preserve the [id].
  Future<void> upsertEntry(IsarNotificationLedgerEntry entry) async {
    await _isar.writeTxn(() async {
      await _isar.isarNotificationLedgerEntrys.put(entry);
    });
  }

  /// Transition an entry to [NotificationLedgerState.cancelled] by entityId.
  Future<void> markCancelled(String entityId) async {
    final entry = await findByEntityId(entityId);
    if (entry == null) return;
    entry
      ..state = NotificationLedgerState.cancelled.name
      ..cancelledAtMs = DateTime.now().millisecondsSinceEpoch
      ..updatedAtMs = DateTime.now().millisecondsSinceEpoch;
    await upsertEntry(entry);
  }

  /// Transition an entry to [NotificationLedgerState.delivered] by notifId.
  Future<void> markDelivered(int notifId) async {
    final entry = await findByNotifId(notifId);
    if (entry == null) return;
    entry
      ..state = NotificationLedgerState.delivered.name
      ..deliveredAtMs = DateTime.now().millisecondsSinceEpoch
      ..updatedAtMs = DateTime.now().millisecondsSinceEpoch;
    await upsertEntry(entry);
  }

  /// Record a user interaction (opened / dismissed / snoozed) by notifId.
  Future<void> markInteraction(int notifId, String interactionType) async {
    final entry = await findByNotifId(notifId);
    if (entry == null) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    entry
      ..interactionType = interactionType
      ..interactedAtMs = now
      ..updatedAtMs = now;
    // Positive interactions reset the ignored count.
    if (interactionType != NotificationLedgerState.ignored.name) {
      entry.ignoredCount = 0;
    }
    await upsertEntry(entry);
  }

  // ── Read operations ─────────────────────────────────────────────────────────

  /// Find an entry by OS notification ID (used when an OS callback fires).
  Future<IsarNotificationLedgerEntry?> findByNotifId(int notifId) async {
    return _isar.isarNotificationLedgerEntrys
        .where()
        .notifIdEqualTo(notifId)
        .findFirst();
  }

  /// Find the most recent entry for an entity (used for per-entity operations).
  Future<IsarNotificationLedgerEntry?> findByEntityId(String entityId) async {
    return _isar.isarNotificationLedgerEntrys
        .where()
        .entityIdEqualTo(entityId)
        .sortByUpdatedAtMsDesc()
        .findFirst();
  }

  /// Return all entries in a given [state] (used for boot reconciliation).
  Future<List<IsarNotificationLedgerEntry>> getByState(
    NotificationLedgerState state,
  ) async {
    return _isar.isarNotificationLedgerEntrys
        .where()
        .stateEqualTo(state.name)
        .findAll();
  }

  // ── Maintenance ─────────────────────────────────────────────────────────────

  /// Delete entries whose [IsarNotificationLedgerEntry.scheduledForMs] is
  /// older than [age]. Called during bootstrap to keep the ledger small.
  Future<void> pruneOlderThan(Duration age) async {
    final cutoffMs = DateTime.now().subtract(age).millisecondsSinceEpoch;
    await _isar.writeTxn(() async {
      await _isar.isarNotificationLedgerEntrys
          .where()
          .scheduledForMsLessThan(cutoffMs)
          .deleteAll();
    });
  }
}
