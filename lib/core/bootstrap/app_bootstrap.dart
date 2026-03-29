import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/notification_response_handler.dart';
import '../di/providers.dart';
import '../firebase/firebase_initializer.dart';
import '../firebase/auth_initializer.dart';
import '../firebase/firestore_client.dart';
import '../notifications/local_notifications_service.dart';
import '../offline/offline_store.dart';
import '../sync/sync_service.dart';
import '../../features/goals/data/goals_repository.dart';
import '../../features/planning/application/accountability_retention_worker.dart';
import '../../features/planning/data/planning_repository.dart';

class AppBootstrap {
  const AppBootstrap._();

  static Future<void> initialize(ProviderContainer container) async {
    await FirebaseInitializer.initialize();
    await AuthInitializer.ensureSignedIn();
    await LocalNotificationsService.instance.initialize(
      onDidReceiveNotificationResponse: (response) {
        unawaited(handleNotificationResponse(response, container));
      },
    );
    await OfflineStore.instance.initialize();
    await SyncService.instance.initialize();
    await container.read(reminderSyncServiceProvider).scheduleFromCache();
    final goalsRepo = FirestoreGoalsRepository(FirestoreClient());
    final goals = await goalsRepo.fetchGoalsOnce();
    await container.read(goalReminderSyncServiceProvider).applyForGoals(goals);
    final planningRepo = FirestorePlanningRepository(FirestoreClient());
    await AccountabilityRetentionWorker(planningRepo.pruneOldAccountabilityLogs).run(retentionDays: 30);
  }
}
