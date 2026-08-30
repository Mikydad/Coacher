import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'notification_ledger_repository.dart';
import 'notification_ledger_state.dart';

// ── Injectable abstractions for testability ───────────────────────────────────

/// The OS notification surface this service reconciles against.
///
/// **Both queues are required.** A notification scheduled for the future lives
/// only in the *pending* queue and never appears in the *delivered* tray, so
/// reconciling against the tray alone marks every correctly-armed future
/// reminder as lost — the root of the "reminders fire at app open" bug
/// (AUDIT §10 T1).
abstract interface class ActiveNotificationsSource {
  /// The delivered tray: notifications that have already fired and are still
  /// on screen.
  Future<List<ActiveNotification>> getActiveNotifications();

  /// Scheduled but not yet delivered — the queue iOS caps at 64.
  Future<List<PendingNotificationRequest>> getPendingNotificationRequests();

  Future<void> cancel(int id);
}

/// Minimal interface consumed by [NotificationReconciliationService].
abstract interface class OrchestratorReEvaluator {
  /// Re-arm [entityId] at [scheduledFor] — its **original** time.
  ///
  /// Implementations must never deliver immediately: a reminder that was armed
  /// for 9 PM and got lost from the OS queue is re-armed for 9 PM, or not at
  /// all (FR-R-01/FR-R-02).
  Future<void> reEvaluateIfAppropriate(
    String entityId, {
    DateTime? scheduledFor,
  });
}

// ─────────────────────────────────────────────────────────────────────────────

/// Runs once on each app cold start (called from app bootstrap, after Isar
/// is opened) to synchronise the OS notification queues with the ledger.
///
/// ## Algorithm
///
/// 1. Read **both** OS queues: pending (future) ∪ tray (delivered) = "armed".
/// 2. Fetch all ledger entries in `scheduled` or `delivered` state.
/// 3. A ledger entry in the pending queue is healthy — leave it alone. One in
///    the delivered tray has demonstrably fired, so it is stamped
///    `delivered`. An entry missing from **both** queues depends on its time:
///    - **still in the future** → mark cancelled and re-arm at its ORIGINAL
///      time. Never `showNow`.
///    - **already past** → **presumed fired** and stamped `delivered`. The OS
///      removes a scheduled local notification from the pending queue when it
///      fires, and local notifications fire whether or not the app is alive,
///      so "past its time and no longer pending" is the closest thing iOS
///      gives to a delivery callback (FR-R-81, fixing AUDIT §10 L1 —
///      `markDelivered` used to be reachable only from the `showNow` path, so
///      every scheduled reminder stayed `scheduled` forever and the delivery
///      counts undercounted). Boot must still never RE-deliver it; the task
///      state machine owns the Overdue/Expired decision.
/// 4. Cancel tray notifications the ledger has no live row for. "Live" means
///    any state except `cancelled`, so a row a snooze race left in `snoozed`
///    state keeps its visible notification (AUDIT §10 L2).
///
/// Runs async (`unawaited`) — must not block app launch.
class NotificationReconciliationService {
  NotificationReconciliationService({
    required this.ledger,
    required this.notifications,
    required this.orchestrator,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final NotificationLedgerRepository ledger;
  final ActiveNotificationsSource notifications;
  final OrchestratorReEvaluator orchestrator;
  final DateTime Function() _now;

  Future<void> reconcile() async {
    try {
      await _reconcile();
    } catch (e, st) {
      debugPrint(
        '[NotificationReconciliation] error during reconcile: $e\n$st',
      );
    }
  }

  /// Result of the most recent pass, for the reminder health row (FR-R-80).
  /// Session-scoped on purpose: reconciliation runs at launch, so "last
  /// result" and "this launch's result" are the same thing.
  static int? lastRunAtMs;
  static String? lastRunSummary;

  Future<void> _reconcile() async {
    // 1. Read both OS queues. A future reminder is in `pending`; one already
    //    on screen is in `active`. Either means the OS still has it.
    final active = await notifications.getActiveNotifications();
    final pendingRequests = await notifications.getPendingNotificationRequests();
    // 2. Fetch ledger entries the app believes are live.
    final scheduled = await ledger.getByState(
      NotificationLedgerState.scheduled,
    );
    final delivered = await ledger.getByState(
      NotificationLedgerState.delivered,
    );
    final believedLive = [...scheduled, ...delivered];

    // 3. Reconcile each row the app believes is live.
    final now = _now();
    final trayIds = {
      for (final n in active)
        if (n.id != null) n.id!,
    };
    final pendingIds = {for (final r in pendingRequests) r.id};
    var fired = 0;
    var lost = 0;

    for (final entry in believedLive) {
      // Still armed for the future — nothing to do.
      if (pendingIds.contains(entry.notifId)) continue;

      // Sitting in the tray: it demonstrably fired, at its scheduled time.
      if (trayIds.contains(entry.notifId)) {
        if (entry.state != NotificationLedgerState.delivered.name) {
          await ledger.markDelivered(
            entry.notifId,
            deliveredAtMs: entry.scheduledForMs,
          );
          fired++;
        }
        continue;
      }

      // A row with no stored time cannot be proved to lie in the future, so
      // it takes the presumed-fired branch — which never re-delivers.
      final scheduledForMs = entry.scheduledForMs;
      final scheduledFor = scheduledForMs == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(scheduledForMs);
      if (scheduledFor != null && scheduledFor.isAfter(now)) {
        // Genuinely lost: its time has not come and the OS no longer holds
        // it. Re-arm at the ORIGINAL time, never now.
        await ledger.markCancelledByNotifId(entry.notifId);
        lost++;
        debugPrint(
          '[NotificationReconciliation] notifId=${entry.notifId} '
          'entity=${entry.entityId} lost from both queues → re-arming at its '
          'original time $scheduledFor',
        );
        await orchestrator.reEvaluateIfAppropriate(
          entry.entityId,
          scheduledFor: scheduledFor,
        );
      } else {
        // Presumed fired (FR-R-81 / L1). Stamping `delivered` is what makes
        // the ledger's "reached the user" counts mean anything. It does NOT
        // re-deliver — the state machine decides Overdue vs Expired from the
        // occurrence, not from here.
        // Stamped with the slot's own time, not "now": a reminder that fired
        // at 2 PM and was noticed at 6 PM was delivered at 2 PM.
        await ledger.markDelivered(
          entry.notifId,
          deliveredAtMs: entry.scheduledForMs,
        );
        fired++;
        debugPrint(
          '[NotificationReconciliation] notifId=${entry.notifId} '
          'entity=${entry.entityId} was due $scheduledFor and is no longer '
          'pending → presumed delivered',
        );
      }
    }

    lastRunAtMs = now.millisecondsSinceEpoch;
    lastRunSummary = '$fired delivered, $lost re-armed';

    // 4. Tray notifications with no live ledger row (phantoms). Read the
    //    ledger AFTER step 3 so rows just re-armed count as live.
    final allEntries = await ledger.getAllEntries();
    final liveNotifIds = {
      for (final e in allEntries)
        if (e.state != NotificationLedgerState.cancelled.name) e.notifId,
    };
    for (final notif in active) {
      final id = notif.id;
      if (id != null && !liveNotifIds.contains(id)) {
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
