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
import '../notifications/notification_reconciliation_service.dart';
import '../offline/offline_store.dart';
import '../sync/sync_service.dart';
import '../../features/goals/application/goals_providers.dart';
import '../../features/planning/application/accountability_retention_worker.dart';
import '../../features/planning/data/planning_repository.dart';
import '../../features/community/application/community_bridge_coordinator.dart';
import '../../features/ai_assistant/application/ai_assistant_providers.dart';
import '../../features/reminders/application/attention_orchestrator_providers.dart';
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

    await SyncService.instance.initialize();
    await container.read(reminderSyncServiceProvider).scheduleFromCache();

    // Purge Coach AI interaction history older than 48 hours.
    unawaited(
      container
          .read(aiInteractionHistoryRepositoryProvider)
          .purgeBefore(DateTime.now().subtract(const Duration(hours: 48))),
    );

    // Purge dismissed proactive suggestion logs older than 7 days (Phase 4).
    unawaited(
      container.read(dismissedSuggestionRepositoryProvider).purgeOldEntries(),
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
