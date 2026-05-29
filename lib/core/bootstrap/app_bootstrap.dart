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
import '../../features/community/application/challenge_progress_sync_service.dart';
import '../../features/community/application/challenge_providers.dart';
import '../../features/community/application/circle_activity_bridge_service.dart';
import '../../features/community/application/circle_providers.dart';
import '../../features/community/application/circle_streak_service.dart';
import '../../features/community/application/user_circle_membership_service.dart';
import '../../features/ai_assistant/application/ai_assistant_providers.dart';
import '../../features/community/data/circle_repository.dart';
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

    // Community activity bridge — read-only observer; no existing flow modified.
    _startCircleActivityBridge(container);
    // Challenge progress sync — separate read-only observer; append-only.
    _startChallengeProgressSync(container);
    // Circle streak evaluation — called once on app start / foreground.
    unawaited(_evaluateCircleStreaks(container));
  }

  static void _startCircleActivityBridge(ProviderContainer container) {
    try {
      final bridge = CircleActivityBridgeService(
        feedRepo: container.read(activityFeedRepositoryProvider),
        membershipSvc: container.read(userCircleMembershipServiceProvider),
        currentUserId: () => FirebaseAuth.instance.currentUser?.uid ?? '',
        currentDisplayName: () =>
            FirebaseAuth.instance.currentUser?.displayName ?? 'User',
      );
      bridge.start(container);
      // The dispose callback is intentionally not stored — the bridge
      // runs for the lifetime of the app.
    } catch (e) {
      // Bridge failure must never crash the app.
    }
  }

  static void _startChallengeProgressSync(ProviderContainer container) {
    try {
      final sync = ChallengeProgressSyncService(
        challengeRepo: container.read(challengeRepositoryProvider),
        currentUserId: () => FirebaseAuth.instance.currentUser?.uid ?? '',
      );
      sync.start(container);
    } catch (e) {
      // Sync failure must never crash the app.
    }
  }

  static Future<void> _evaluateCircleStreaks(
      ProviderContainer container) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      if (uid.isEmpty) return;

      final circleIds = await container.read(myCircleIdsProvider.stream).first;
      if (circleIds.isEmpty) return;

      final streakService = CircleStreakService(
        circleRepo: FirestoreCircleRepository(),
        feedRepo: container.read(activityFeedRepositoryProvider),
      );
      await streakService.evaluateStreaks(circleIds);
    } catch (e) {
      // Streak evaluation failure must never crash the app.
    }
  }
}
