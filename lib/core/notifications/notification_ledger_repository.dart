import 'package:isar_community/isar.dart';

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

  /// Transition an entry to [NotificationLedgerState.cancelled] by notifId.
  /// Slot-scoped cancel for entities with several pending notifications
  /// (intention ladders) — the entityId variant would only hit the latest.
  Future<void> markCancelledByNotifId(int notifId) async {
    final entry = await findByNotifId(notifId);
    if (entry == null) return;
    entry
      ..state = NotificationLedgerState.cancelled.name
      ..cancelledAtMs = DateTime.now().millisecondsSinceEpoch
      ..updatedAtMs = DateTime.now().millisecondsSinceEpoch;
    await upsertEntry(entry);
  }

  /// Transition an entry to [NotificationLedgerState.delivered] by notifId.
  /// Stamp a slot as having reached the user.
  ///
  /// [deliveredAtMs] is the moment it actually fired. Boot-time fired
  /// detection passes the slot's own scheduled time, because a reminder that
  /// fired at 2 PM and was noticed at 6 PM was delivered at 2 PM — "when we
  /// noticed" would make every delivery metric a measure of app-open
  /// frequency. Omit it only when delivery is happening right now
  /// (the `showNow` path).
  ///
  /// ## The slot lifecycle (FR-R-81)
  ///
  /// It is spread across three fields on purpose, not one state enum:
  /// - [IsarNotificationLedgerEntry.state] — where the SLOT is: `scheduled` →
  ///   `delivered` → `cancelled`, with `snoozed` as the re-plan branch.
  /// - `interactionType` / `interactedAtMs` — what the USER did with it
  ///   (opened, dismissed, snoozed). Orthogonal: a slot can be delivered and
  ///   opened, or delivered and ignored.
  /// - `ignoredCount` — how many times it went unanswered, reset by any
  ///   positive interaction.
  ///
  /// Collapsing these into one enum would lose the distinction between "the
  /// OS no longer holds this" and "the user did something about it".
  Future<void> markDelivered(int notifId, {int? deliveredAtMs}) async {
    final entry = await findByNotifId(notifId);
    if (entry == null) return;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    entry
      ..state = NotificationLedgerState.delivered.name
      ..deliveredAtMs = deliveredAtMs ?? entry.deliveredAtMs ?? nowMs
      ..updatedAtMs = nowMs;
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

  /// All ledger entries (pruned to ~recent history by [pruneOlderThan]).
  /// Used by the opportunity planner to derive engagement-by-hour.
  Future<List<IsarNotificationLedgerEntry>> getAllEntries() async {
    return _isar.isarNotificationLedgerEntrys.where().findAll();
  }

  /// "Delivery claims" for [entityKind] whose scheduled time falls inside
  /// [startMs]..[endMs] (inclusive): rows still pending, plus rows that
  /// actually reached the user (deliveredAtMs stamped — even if the slot
  /// was later replaced). Rows cancelled BEFORE delivery are free, so a
  /// replan never counts its own replaced slots.
  ///
  /// Powers the daily intention-nudge caps (P1-06).
  Future<List<IsarNotificationLedgerEntry>> getDeliveryClaimsByKindInRange({
    required String entityKind,
    required int startMs,
    required int endMs,
  }) async {
    final rows = await _isar.isarNotificationLedgerEntrys
        .filter()
        .entityKindEqualTo(entityKind)
        .scheduledForMsBetween(startMs, endMs)
        .findAll();
    return rows
        .where(
          (r) =>
              r.deliveredAtMs != null ||
              r.state != NotificationLedgerState.cancelled.name,
        )
        .toList(growable: false);
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
