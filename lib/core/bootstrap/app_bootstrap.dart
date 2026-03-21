import '../firebase/firebase_initializer.dart';
import '../firebase/auth_initializer.dart';
import '../notifications/local_notifications_service.dart';
import '../offline/offline_store.dart';
import '../sync/sync_service.dart';
import '../../features/reminders/application/reminder_sync_service.dart';
import '../../features/reminders/data/reminder_cache_store.dart';
import '../../features/reminders/data/reminder_repository.dart';

class AppBootstrap {
  const AppBootstrap._();

  static Future<void> initialize() async {
    await FirebaseInitializer.initialize();
    await AuthInitializer.ensureSignedIn();
    await LocalNotificationsService.instance.initialize();
    await OfflineStore.instance.initialize();
    await SyncService.instance.initialize();
    final reminderSync = ReminderSyncService(
      repository: FirestoreReminderRepository(),
      cacheStore: const ReminderCacheStore(),
      notifications: LocalNotificationsService.instance,
    );
    await reminderSync.scheduleFromCache();
  }
}
