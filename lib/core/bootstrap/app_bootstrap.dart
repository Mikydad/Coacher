import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/notification_response_handler.dart';
import '../../features/auth/application/auth_session_policy.dart';
import '../di/providers.dart';
import '../firebase/firebase_initializer.dart';
import '../firebase/firestore_client.dart';
import '../notifications/local_notifications_service.dart';
import '../notifications/notification_ledger_repository.dart';
import '../../features/reminders/data/isar_reminder_occurrence_repository.dart';
import '../notifications/notification_reconciliation_service.dart';
import '../offline/offline_store.dart';
import '../push/push_messaging_service.dart';
import '../sync/sync_service.dart';
import '../../features/goals/application/goals_providers.dart';
import '../../features/planning/application/accountability_retention_worker.dart';
import '../../features/planning/data/planning_repository.dart';
import '../../features/community/application/community_bridge_coordinator.dart';
import '../../features/ai_assistant/application/ai_assistant_providers.dart';
import '../../features/memory/application/memory_providers.dart';
import '../../features/reminders/application/attention_orchestrator_providers.dart';
import '../../features/thinking/application/thinking_providers.dart';
import '../runtime/schedule_mutation_coordinator.dart';

/// App startup is split in two so the first frame is never blocked on the
/// network:
///
/// - [initializePreFrame] — awaited before `runApp`. Only what the first
///   frame genuinely needs: Firebase (Crashlytics + AuthGate depend on it)
///   and the Isar store the first screens read from.
/// - [completeDeferred] — kicked off after the first frame. Notification
///   wiring, sync, reminder scheduling, and per-user Firestore maintenance.
///   AuthGate's spinner covers the async tail; per-user work waits for the
///   user AuthGate signs in (bootstrap never signs in itself — a competing
///   anonymous sign-in would look like a uid change and wipe local data).
class AppBootstrap {
  const AppBootstrap._();

  static Future<void> initializePreFrame(ProviderContainer container) async {
    // TEMP debug for notification-tap investigation.
    // ignore: avoid_print
    print('[NotifTap] bootstrap initialize start');
    await FirebaseInitializer.initialize();
    await OfflineStore.instance.initialize();
    ScheduleMutationCoordinator.instance.attachContainer(container);
  }

  static Future<void> completeDeferred(ProviderContainer container) async {
    await LocalNotificationsService.instance.initialize(
      onDidReceiveNotificationResponse: (response) {
        unawaited(handleNotificationResponse(response, container));
      },
    );
    // Cold-start notification taps: the plugin retains the launch response,
    // so draining one frame after startup still catches it. Navigation is
    // deferred internally until a navigator exists.
    await LocalNotificationsService.instance.drainLaunchNotificationResponse(
      (response) => handleNotificationResponse(response, container),
    );
    // ignore: avoid_print
    print('[NotifTap] bootstrap launch-drain done');

    // Boot reconciliation — async, must not block anything.
    final ledger = NotificationLedgerRepository(OfflineStore.instance.isar!);
    unawaited(
      NotificationReconciliationService(
        ledger: ledger,
        notifications: LocalNotificationsService.instance,
        orchestrator: container.read(attentionOrchestratorServiceProvider),
      ).reconcile(),
    );
    // Prune ledger entries older than 72 hours.
    unawaited(ledger.pruneOlderThan(const Duration(hours: 72)));
    // Resolved reminder occurrences age out too (audit D1: the prune method
    // existed with zero callers, so history grew forever). Thirty days keeps
    // everything the success metrics and the consecutive-reschedule streak
    // read; unresolved rows are never touched.
    unawaited(
      const IsarReminderOccurrenceRepository().pruneResolvedOlderThan(
        const Duration(days: 30),
      ),
    );

    await SyncService.instance.initialize();
    await container.read(reminderSyncServiceProvider).scheduleFromCache();

    // Push transport for the server rescue-net (Phase 5): register this
    // device's token + stamp the app-open heartbeat. No-op without Firebase
    // or APNs; the local alarm ladder stays the correctness floor.
    unawaited(PushMessagingService.instance.initialize(container));
    unawaited(PushMessagingService.instance.recordHeartbeat());

    // Summarize-then-purge (Phase 2, §5.2) replaces the blind 48h delete:
    // sessions are distilled into memory before their raw turns purge; if
    // extraction can't run, the purge defers up to 7 days, then writes a
    // deterministic truncation summary. Continuity is never silently lost.
    unawaited(container.read(memoryExtractionServiceProvider).runMaintenance());

    // Thinking Loop (Phase 7, §12): one budgeted reflection pass per
    // device-day over the full local picture, and only when the inputs
    // actually changed. Failures silent-skip and retry on the next open.
    unawaited(container.read(thinkingLoopServiceProvider).reflectIfDue());

    // Purge dismissed proactive suggestion logs older than 7 days (Phase 4).
    unawaited(
      container.read(dismissedSuggestionRepositoryProvider).purgeOldEntries(),
    );

    // AI batch hygiene (fix-wave Phase 2): roll back batches a crash left
    // stranded mid-execution (their per-action inverse logs are the repair
    // record — §8 E8), then prune batch records older than 7 days / beyond
    // the newest 20 (pruneOld had shipped with zero callers, so snapshots
    // of personal data accumulated forever).
    unawaited(
      container.read(aiActionExecutorProvider).sweepStrandedBatches().then(
            (_) =>
                container.read(aiActionBatchRepositoryProvider).pruneOld(),
          ),
    );

    // Community bridges (activity feed + challenge progress) — read-only
    // observers restarted by AuthGate on account switch so their per-user
    // dedupe state never leaks across sessions.
    CommunityBridgeCoordinator.instance.restart(container);
    // Circle streak evaluation — called once on app start / foreground.
    unawaited(
      CommunityBridgeCoordinator.instance.evaluateCircleStreaks(container),
    );

    // Per-user Firestore maintenance — needs an authenticated user. In guest
    // mode AuthGate signs in anonymously moments after the first frame; wait
    // for that user instead of racing it with our own sign-in call.
    final user = await _awaitSignedInUser();
    if (user != null) {
      try {
        final goals = await container
            .read(goalsRepositoryProvider)
            .fetchGoalsOnce();
        await container
            .read(goalReminderSyncServiceProvider)
            .applyForGoals(goals);
        final planningRepo = FirestorePlanningRepository(FirestoreClient());
        await AccountabilityRetentionWorker(
          planningRepo.pruneOldAccountabilityLogs,
        ).run(retentionDays: 30);
      } catch (e) {
        // Non-fatal maintenance work — never block on failure.
      }
    }
  }

  /// Waits for AuthGate to produce a signed-in user. In registered-auth mode
  /// a signed-out boot shows the landing screen and no sign-in is imminent,
  /// so skip immediately (matches the old behavior of skipping per-user work
  /// when signed out). The timeout covers offline guest boots where the
  /// anonymous sign-in fails.
  static Future<User?> _awaitSignedInUser() async {
    final current = FirebaseAuth.instance.currentUser;
    if (current != null) return current;
    if (kRequireRegisteredAuth) return null;
    try {
      return await FirebaseAuth.instance
          .authStateChanges()
          .firstWhere((u) => u != null)
          .timeout(const Duration(seconds: 30));
    } on TimeoutException {
      return null;
    }
  }
}
