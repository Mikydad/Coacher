import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../firebase/firestore_client.dart';
import '../notifications/local_notifications_service.dart';
import '../offline/offline_store.dart';
import '../sync/sync_service.dart';
import '../../features/planning/application/routine_mode_policy_resolver.dart';
import '../../features/planning/data/isar_planning_repository.dart';
import '../../features/planning/data/planning_repository.dart';
import '../../features/execution/application/execution_controller.dart';
import '../../features/execution/data/execution_repository.dart';
import '../../features/execution/data/timer_runtime_cache.dart';
import '../../features/scoring/application/scoring_controller.dart';
import '../../features/scoring/data/scoring_repository.dart';
import '../../features/goals/application/goal_reminder_sync_service.dart';
import '../../features/reminders/application/reminder_sync_service.dart';
import '../../features/reminders/data/isar_reminder_repository.dart';
import '../../features/reminders/data/reminder_cache_store.dart';
import '../../features/reminders/data/reminder_repository.dart';

final firestoreClientProvider = Provider<FirestoreClient>((ref) => FirestoreClient());
final localNotificationsServiceProvider = Provider<LocalNotificationsService>(
  (ref) => LocalNotificationsService.instance,
);
final offlineStoreProvider = Provider<OfflineStore>((ref) => OfflineStore.instance);
final syncServiceProvider = Provider<SyncService>((ref) => SyncService.instance);

final planningRepositoryProvider = Provider<PlanningRepository>((ref) {
  final firestore = FirestorePlanningRepository(ref.read(firestoreClientProvider));
  return IsarPlanningRepository(firestore);
});
final routineModePolicyResolverProvider = Provider<RoutineModePolicyResolver>(
  (ref) => const RoutineModePolicyResolver(),
);

final executionRepositoryProvider = Provider<ExecutionRepository>(
  (ref) => FirestoreExecutionRepository(),
);

final timerRuntimeCacheProvider = Provider<TimerRuntimeCache>((ref) => const TimerRuntimeCache());

final activeExecutionTaskIdProvider = StateProvider<String>((ref) => 'task_ui_architecture');
final activeExecutionTaskLabelProvider = StateProvider<String>((ref) => 'Deep Work: UI Architecture');

final executionControllerProvider = StateNotifierProvider<ExecutionController, ExecutionState>((ref) {
  return ExecutionController(
    repository: ref.read(executionRepositoryProvider),
    runtimeCache: ref.read(timerRuntimeCacheProvider),
    initialTaskId: ref.read(activeExecutionTaskIdProvider),
    initialTaskLabel: ref.read(activeExecutionTaskLabelProvider),
  );
});

final scoringRepositoryProvider = Provider<ScoringRepository>((ref) => FirestoreScoringRepository());
final scoringControllerProvider = Provider<ScoringController>(
  (ref) => ScoringController(ref.read(scoringRepositoryProvider)),
);

final reminderRepositoryProvider = Provider<ReminderRepository>(
  (ref) => IsarReminderRepository(FirestoreReminderRepository()),
);

@Deprecated('Reminders live in Isar via ReminderRepository; this store is unused.')
final reminderCacheStoreProvider = Provider<ReminderCacheStore>((ref) => const ReminderCacheStore());
final reminderSyncServiceProvider = Provider<ReminderSyncService>(
  (ref) => ReminderSyncService(
    repository: ref.read(reminderRepositoryProvider),
    notifications: LocalReminderNotificationsPort(ref.read(localNotificationsServiceProvider)),
  ),
);

final goalReminderSyncServiceProvider = Provider<GoalReminderSyncService>(
  (ref) => GoalReminderSyncService(notifications: ref.read(localNotificationsServiceProvider)),
);
