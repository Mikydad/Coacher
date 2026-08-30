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
/// 3. A ledger entry whose `notifId` is armed is healthy — leave it alone.
///    An entry missing from **both** queues is genuinely gone, and what
///    happens next depends on its time:
///    - **still in the future** → mark cancelled and re-arm at its ORIGINAL
///      time. Never `showNow`.
///    - **already past** → mark cancelled and stop. The task state machine
///      (Phase R2) owns the Overdue/Expired decision; boot must not deliver a
///      reminder whose moment has passed.
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

  Future<void> _reconcile() async {
    // 1. Read both OS queues. A future reminder is in `pending`; one already
    //    on screen is in `active`. Either means the OS still has it.
    final active = await notifications.getActiveNotifications();
    final pendingRequests = await notifications.getPendingNotificationRequests();
    final armedIds = <int>{
      for (final n in active)
        if (n.id != null) n.id!,
      for (final r in pendingRequests) r.id,
    };

    // 2. Fetch ledger entries the app believes are live.
    final scheduled = await ledger.getByState(
      NotificationLedgerState.scheduled,
    );
    final delivered = await ledger.getByState(
      NotificationLedgerState.delivered,
    );
    final believedLive = [...scheduled, ...delivered];

    // 3. Ledger entries the OS has in neither queue.
    final now = _now();
    for (final entry in believedLive) {
      if (armedIds.contains(entry.notifId)) continue;

      // A row with no stored time cannot be proved to be in the future, so it
      // takes the conservative branch below: cancelled, never delivered.
      final scheduledForMs = entry.scheduledForMs;
      final scheduledFor = scheduledForMs == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(scheduledForMs);
      // Cancel by notifId, not entityId: an intention ladder holds several
      // slots under one entity, and the entity-scoped write would take out
      // this slot's healthy siblings.
      await ledger.markCancelledByNotifId(entry.notifId);

      if (scheduledFor != null && scheduledFor.isAfter(now)) {
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
        // R2 seam: the reminder's moment has passed. Delivering it now would
        // be the T1 misfire. The state machine decides Overdue vs Expired.
        debugPrint(
          '[NotificationReconciliation] notifId=${entry.notifId} '
          'entity=${entry.entityId} was due $scheduledFor and never '
          'delivered → cancelled, left for the state machine',
        );
      }
    }

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
