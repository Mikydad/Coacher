import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../firebase/firestore_client.dart';
import '../notifications/local_notifications_service.dart';
import '../notifications/notification_budget.dart';
import '../offline/offline_store.dart';
import '../sync/sync_service.dart';
import '../tier/tier_providers.dart';
import '../../features/auth/application/auth_providers.dart';
import '../../features/planning/application/routine_mode_policy_resolver.dart';
import '../../features/planning/data/isar_planning_repository.dart';
import '../../features/planning/data/planning_repository.dart';
import '../../features/execution/application/execution_controller.dart';
import '../../features/execution/data/execution_repository.dart';
import '../../features/execution/data/timer_runtime_cache.dart';
import '../../features/focus/data/focus_resume_store.dart';
import '../../features/scoring/application/scoring_controller.dart';
import '../../features/scoring/data/scoring_repository.dart';
import '../../features/goals/application/goal_reminder_sync_service.dart';
import '../../features/analytics/data/ai_summary_repository.dart';
import '../../features/analytics/data/analytics_repository.dart';
import '../../features/analytics/data/delivery_repository.dart';
import '../../features/analytics/data/feature_cache_repository.dart';
import '../../features/analytics/data/focus_repository.dart';
import '../../features/analytics/data/insight_cache_repository.dart';
import '../../features/analytics/data/isar_analytics_repository.dart';
import '../../features/reminders/application/attention_orchestrator_providers.dart';
import '../../features/reminders/application/reminder_sync_service.dart';
import '../../features/reminders/data/isar_reminder_repository.dart';
import '../../features/reminders/data/reminder_cache_store.dart';
import '../../features/reminders/application/reminder_occurrence_service.dart';
import '../../features/reminders/data/isar_reminder_occurrence_repository.dart';
import '../../features/reminders/data/reminder_occurrence_repository.dart';
import '../../features/reminders/data/reminder_repository.dart';
import '../../features/reminders/domain/models/reminder_occurrence.dart';
import '../../features/ai_assistant/data/ai_interaction_history_repository.dart';
import '../../features/community/application/circle_providers.dart';
import '../../features/community/application/user_circle_membership_service.dart';

/// Rebuilds whenever the signed-in uid changes so all downstream repositories
/// always use the correct uid-scoped Firestore path.
final firestoreClientProvider = Provider<FirestoreClient>((ref) {
  // Watch auth state so this provider invalidates on uid change.
  final uid =
      ref.watch(authStateProvider).valueOrNull?.uid ??
      FirebaseAuth.instance.currentUser?.uid;
  return FirestoreClient(uid: uid);
});
final localNotificationsServiceProvider = Provider<LocalNotificationsService>(
  (ref) => LocalNotificationsService.instance,
);

/// Guard against iOS's 64-pending-local-notification cap — consulted by the
/// AttentionOrchestrator before scheduling any future notification.
final notificationBudgetProvider = Provider<NotificationBudget>(
  (ref) => NotificationBudget(
    pending: ref.read(localNotificationsServiceProvider),
  ),
);
final offlineStoreProvider = Provider<OfflineStore>(
  (ref) => OfflineStore.instance,
);
final syncServiceProvider = Provider<SyncService>(
  (ref) => SyncService.instance,
);

final planningRepositoryProvider = Provider<PlanningRepository>((ref) {
  // watch (not read): rebuilds on uid change so the repository never holds a
  // FirestoreClient pinned to a previous account after a switch.
  final firestore = FirestorePlanningRepository(
    ref.watch(firestoreClientProvider),
  );
  return IsarPlanningRepository(firestore);
});
final routineModePolicyResolverProvider = Provider<RoutineModePolicyResolver>(
  (ref) => const RoutineModePolicyResolver(),
);

final executionRepositoryProvider = Provider<ExecutionRepository>(
  (ref) => FirestoreExecutionRepository(),
);

final timerRuntimeCacheProvider = Provider<TimerRuntimeCache>(
  (ref) => const TimerRuntimeCache(),
);

final focusResumeStoreProvider = Provider<FocusResumeStore>(
  (ref) => const FocusResumeStore(),
);

final activeExecutionTaskIdProvider = StateProvider<String>(
  (ref) => 'task_ui_architecture',
);
final activeExecutionTaskLabelProvider = StateProvider<String>(
  (ref) => 'Deep Work: UI Architecture',
);

final executionControllerProvider =
    StateNotifierProvider<ExecutionController, ExecutionState>((ref) {
      return ExecutionController(
        repository: ref.read(executionRepositoryProvider),
        runtimeCache: ref.read(timerRuntimeCacheProvider),
        resumeStore: ref.read(focusResumeStoreProvider),
        initialTaskId: ref.read(activeExecutionTaskIdProvider),
        initialTaskLabel: ref.read(activeExecutionTaskLabelProvider),
      );
    });

final scoringRepositoryProvider = Provider<ScoringRepository>(
  (ref) => FirestoreScoringRepository(),
);
final scoringControllerProvider = Provider<ScoringController>(
  (ref) => ScoringController(ref.read(scoringRepositoryProvider)),
);

final reminderRepositoryProvider = Provider<ReminderRepository>(
  (ref) => IsarReminderRepository(FirestoreReminderRepository()),
);

/// Reminder occurrences — the state machine's unit (PRD §3.1).
final reminderOccurrenceRepositoryProvider =
    Provider<ReminderOccurrenceRepository>(
      (ref) => const IsarReminderOccurrenceRepository(),
    );

/// The [L-ALIVE] layer: advances occurrences and backfills missing ones.
final reminderOccurrenceServiceProvider = Provider<ReminderOccurrenceService>(
  (ref) => ReminderOccurrenceService(
    occurrences: ref.read(reminderOccurrenceRepositoryProvider),
    reminders: ref.read(reminderRepositoryProvider),
  ),
);

/// Everything the state machine still owns, straight off the Isar watch
/// stream. The Recovery Card reads this — never an invalidate-and-refetch;
/// the local write IS the update.
final unresolvedReminderOccurrencesProvider =
    StreamProvider<List<ReminderOccurrence>>(
      (ref) => ref.watch(reminderOccurrenceRepositoryProvider).watchUnresolved(),
    );

@Deprecated(
  'Reminders live in Isar via ReminderRepository; this store is unused.',
)
final reminderCacheStoreProvider = Provider<ReminderCacheStore>(
  (ref) => const ReminderCacheStore(),
);
final reminderSyncServiceProvider = Provider<ReminderSyncService>(
  (ref) => ReminderSyncService(
    repository: ref.read(reminderRepositoryProvider),
    notifications: LocalReminderNotificationsPort(
      ref.read(localNotificationsServiceProvider),
    ),
    orchestratorService: ref.read(attentionOrchestratorServiceProvider),
    occurrenceService: ref.read(reminderOccurrenceServiceProvider),
  ),
);

final goalReminderSyncServiceProvider = Provider<GoalReminderSyncService>(
  (ref) => GoalReminderSyncService(
    notifications: ref.read(localNotificationsServiceProvider),
    orchestrator: ref.read(attentionOrchestratorServiceProvider),
    occurrenceService: ref.read(reminderOccurrenceServiceProvider),
  ),
);

final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  return IsarAnalyticsRepository(FirestoreAnalyticsRepository());
});

final featureCacheRepositoryProvider = Provider<FeatureCacheRepository>((ref) {
  return IsarFeatureCacheRepository();
});

final insightCacheRepositoryProvider = Provider<InsightCacheRepository>((ref) {
  return IsarInsightCacheRepository();
});

final deliveryRepositoryProvider = Provider<DeliveryRepository>((ref) {
  return IsarDeliveryRepository();
});

final focusRepositoryProvider = Provider<FocusRepository>((ref) {
  return IsarFocusRepository();
});

final aiSummaryRepositoryProvider = Provider<AiSummaryRepository>((ref) {
  return IsarAiSummaryRepository();
});

// ── AI Assistant ─────────────────────────────────────────────────────────────

final aiInteractionHistoryRepositoryProvider =
    Provider<AiInteractionHistoryRepository>(
      (ref) => AiInteractionHistoryRepository(ref.read(offlineStoreProvider)),
    );

// ── Community / Accountability Circles ───────────────────────────────────────

final userCircleMembershipServiceProvider =
    Provider<UserCircleMembershipService>((ref) {
      return UserCircleMembershipService(
        memberRepo: ref.read(circleMemberRepositoryProvider),
        circleRepo: ref.read(circleRepositoryProvider),
        currentUserId: () => FirebaseAuth.instance.currentUser?.uid ?? '',
        currentDisplayName: () =>
            FirebaseAuth.instance.currentUser?.displayName ?? 'User',
        maxCirclesPerUser: () => ref
            .read(tierGateProvider)
            .maxJoinedCircles(
              legacyLimit: UserCircleMembershipService.kMaxCirclesPerUser,
            ),
      );
    });
