import 'package:sidepal/core/local_db/isar_collections/isar_notification_ledger_entry.dart';
import 'package:sidepal/core/notifications/notification_ledger_repository.dart';
import 'package:sidepal/core/notifications/notification_ledger_state.dart';

/// Ledger stub for tests that construct [AttentionOrchestratorService]
/// (or fakes of it) without an open Isar instance.
class NoOpNotificationLedger implements NotificationLedgerRepository {
  @override
  Future<void> upsertEntry(IsarNotificationLedgerEntry entry) async {}

  @override
  Future<void> markCancelled(String entityId) async {}

  @override
  Future<void> markCancelledByNotifId(int notifId) async {}

  @override
  Future<void> markDelivered(int notifId) async {}

  @override
  Future<void> markInteraction(int notifId, String interactionType) async {}

  @override
  Future<IsarNotificationLedgerEntry?> findByNotifId(int notifId) async => null;

  @override
  Future<IsarNotificationLedgerEntry?> findByEntityId(String entityId) async => null;

  @override
  Future<List<IsarNotificationLedgerEntry>> getAllEntries() async => const [];

  @override
  Future<List<IsarNotificationLedgerEntry>> getByState(
    NotificationLedgerState state,
  ) async =>
      const [];

  @override
  Future<void> pruneOlderThan(Duration age) async {}
}
