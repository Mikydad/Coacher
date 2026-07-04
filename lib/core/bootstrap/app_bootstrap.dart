import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/notification_response_handler.dart';
import '../../features/auth/application/auth_session_policy.dart';
import '../di/providers.dart';
import '../firebase/auth_initializer.dart';
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

class AppBootstrap {
  const AppBootstrap._();

  static Future<void> initialize(ProviderContainer container) async {
    // TEMP debug for notification-tap investigation.
    // ignore: avoid_print
    print('[NotifTap] bootstrap initialize start');
    await FirebaseInitializer.initialize();
    // Auth flow is owned by AuthGate in the widget tree. However, bootstrap
    // performs per-user Firestore work below (sync, goals, prune) that requires
    // an authenticated user. In guest mode (the default), ensure an anonymous
    // session exists here so that work succeeds. In registered-auth mode we do
    // NOT sign in — the per-user calls below are guarded to skip when signed
    // out, and AuthGate shows the landing screen instead.
    if (!kRequireRegisteredAuth) {
      await AuthInitializer.ensureSignedIn();
    }
    await LocalNotificationsService.instance.initialize(
      onDidReceiveNotificationResponse: (response) {
        unawaited(handleNotificationResponse(response, container));
      },
    );
    // Handle cold-start notification taps as early as possible. Navigation may
    // be deferred and flushed later when navigator is available.
    await LocalNotificationsService.instance.drainLaunchNotificationResponse(
      (response) => handleNotificationResponse(response, container),
    );
    // ignore: avoid_print
    print('[NotifTap] bootstrap launch-drain done');
    await OfflineStore.instance.initialize();
    ScheduleMutationCoordinator.instance.attachContainer(container);

    // Boot reconciliation — async, must not block app launch.
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

    // Per-user Firestore work — only when signed in. In registered-auth mode the
    // user may be signed out at boot (AuthGate shows the landing screen); these
    // calls must be skipped to avoid permission-denied crashing app launch.
    if (FirebaseAuth.instance.currentUser != null) {
      try {
        final goals =
            await container.read(goalsRepositoryProvider).fetchGoalsOnce();
        await container
            .read(goalReminderSyncServiceProvider)
            .applyForGoals(goals);
        final planningRepo = FirestorePlanningRepository(FirestoreClient());
        await AccountabilityRetentionWorker(
          planningRepo.pruneOldAccountabilityLogs,
        ).run(retentionDays: 30);
      } catch (e) {
        // Non-fatal maintenance work — never block app launch on failure.
      }
    }

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
  }
}
