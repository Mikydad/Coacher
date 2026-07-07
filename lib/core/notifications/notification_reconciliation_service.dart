import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'notification_ledger_repository.dart';
import 'notification_ledger_state.dart';

// ── Injectable abstractions for testability ───────────────────────────────────

/// Minimal interface consumed by [NotificationReconciliationService].
abstract interface class ActiveNotificationsSource {
  Future<List<ActiveNotification>> getActiveNotifications();
  Future<void> cancel(int id);
}

/// Minimal interface consumed by [NotificationReconciliationService].
abstract interface class OrchestratorReEvaluator {
  Future<void> reEvaluateIfAppropriate(String entityId);
}

// ─────────────────────────────────────────────────────────────────────────────

/// Runs once on each app cold start (called from app bootstrap, after Isar
/// is opened) to synchronise the OS notification tray with the ledger.
///
/// ## Algorithm
///
/// 1. Fetch the OS tray state via `getActiveNotifications()`.
/// 2. Fetch all ledger entries in `scheduled` or `delivered` state.
/// 3. For each pending ledger entry whose `notifId` is **NOT** in the tray:
///    - Mark the entry `cancelled` (the OS dismissed it while the app was dead).
///    - Ask the orchestrator to re-evaluate if re-delivery is appropriate.
/// 4. For each tray notification whose `notifId` is **NOT** in the ledger:
///    - Cancel it (unknown phantom notification).
///
/// Runs async (`unawaited`) — must not block app launch.
class NotificationReconciliationService {
  const NotificationReconciliationService({
    required this.ledger,
    required this.notifications,
    required this.orchestrator,
  });

  final NotificationLedgerRepository ledger;
  final ActiveNotificationsSource notifications;
  final OrchestratorReEvaluator orchestrator;

  Future<void> reconcile() async {
    try {
      await _reconcile();
    } catch (e, st) {
      debugPrint(
        '[NotificationReconciliation] error during reconcile: $e\n$st',
      );
    }
  }

  Future<void> _reconcile() async {
    // 1. Read OS tray.
    final active = await notifications.getActiveNotifications();
    final activeIds = {
      for (final n in active)
        if (n.id != null) n.id!,
    };

    // 2. Fetch pending ledger entries.
    final scheduled = await ledger.getByState(
      NotificationLedgerState.scheduled,
    );
    final delivered = await ledger.getByState(
      NotificationLedgerState.delivered,
    );
    final pending = [...scheduled, ...delivered];

    // 3. Ledger entries missing from the OS tray.
    for (final entry in pending) {
      if (!activeIds.contains(entry.notifId)) {
        debugPrint(
          '[NotificationReconciliation] notifId=${entry.notifId} '
          'entity=${entry.entityId} not in tray → marking cancelled',
        );
        await ledger.markCancelled(entry.entityId);
        await orchestrator.reEvaluateIfAppropriate(entry.entityId);
      }
    }

    // 4. OS tray notifications missing from the ledger (phantom).
    final ledgerNotifIds = {for (final e in pending) e.notifId};
    for (final notif in active) {
      final id = notif.id;
      if (id != null && !ledgerNotifIds.contains(id)) {
        debugPrint(
          '[NotificationReconciliation] notifId=$id '
          'not in ledger → cancelling phantom notification',
        );
        try {
          await notifications.cancel(id);
        } catch (e) {
          debugPrint(
            'notification_reconciliation_service: swallowed error: $e',
          );
        }
      }
    }
  }
}
