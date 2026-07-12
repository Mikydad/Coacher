import 'dart:async';

import 'sync_service.dart';

/// Local-first Firestore replication (`OPTIMISTIC_UPDATES_AUDIT.md` Rule 1).
///
/// The caller has already committed the authoritative local write (Isar);
/// these helpers make the cloud copy eventually consistent by ALWAYS routing
/// through the offline outbox and kicking a background flush. Nothing here
/// waits on the network, so the UI thread is never held hostage by a slow or
/// dead connection.
///
/// Contrast with the old pattern (`await FirebaseFirestore.set(...)` with the
/// outbox as a catch-only fallback): `set()` resolves only on **server ack**,
/// which blocked every save for a full round-trip — and indefinitely offline,
/// because a dead connection doesn't throw, it just never completes.
///
/// Failure story: a flush that leaves ops behind sets
/// [SyncService.hasSyncIssue], surfaced app-wide by the thin amber
/// stuck-writes line. No per-call error handling needed.
Future<void> outboxUpsert({
  required String entityType,
  required String documentPath,
  required Map<String, dynamic> payload,
}) async {
  // Durable enqueue (disk-persisted) — milliseconds, no network.
  await SyncService.instance.enqueueUpsert(
    entityType: entityType,
    documentPath: documentPath,
    payload: payload,
  );
  // Push in the background; connectivity changes retry automatically.
  unawaited(SyncService.instance.processQueue());
}

/// Delete counterpart of [outboxUpsert].
Future<void> outboxDelete({
  required String entityType,
  required String documentPath,
}) async {
  await SyncService.instance.enqueueDelete(
    entityType: entityType,
    documentPath: documentPath,
  );
  unawaited(SyncService.instance.processQueue());
}
