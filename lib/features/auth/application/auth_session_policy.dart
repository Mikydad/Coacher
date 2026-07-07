import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/notifications/local_notifications_service.dart';
import '../../../core/offline/offline_store.dart';
import '../../../core/sync/sync_cursor_store.dart';
import '../../../core/sync/sync_service.dart';

// ── Feature flag ──────────────────────────────────────────────────────────────

/// When `true`, cold-start skips anonymous sign-in and shows [AuthLandingScreen]
/// until the user signs in with a real account.
///
/// Flip via `--dart-define=REQUIRE_REGISTERED_AUTH=true` in your release build
/// script. Defaults to `false` during development so existing anonymous flow
/// is fully preserved with no regression.
const bool kRequireRegisteredAuth = bool.fromEnvironment(
  'REQUIRE_REGISTERED_AUTH',
  defaultValue: false,
);

// ── Prefs keys ────────────────────────────────────────────────────────────────

const String kLastSignedInUidPrefsKey = 'last_signed_in_uid';

// ── Policy ────────────────────────────────────────────────────────────────────

/// Static helpers that manage the local-session lifecycle:
/// persist the current uid, detect uid changes, and wipe all local data on
/// sign-out or account switch.
///
/// Pure static methods — no constructor needed.
abstract final class AuthSessionPolicy {
  // ── Uid persistence ──────────────────────────────────────────────────────────

  /// Read the uid from the last successful sign-in stored on this device.
  static Future<String?> getLastSignedInUid() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(kLastSignedInUidPrefsKey);
  }

  /// Store [uid] as the most recent signed-in uid.
  static Future<void> persistUid(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kLastSignedInUidPrefsKey, uid);
  }

  /// Returns `true` when [newUid] differs from the stored uid, indicating that
  /// a different account has signed in and local data must be wiped before use.
  ///
  /// Returns `false` on first install (nothing stored) to avoid a spurious wipe.
  static Future<bool> hasUidChanged(String newUid) async {
    final stored = await getLastSignedInUid();
    if (stored == null) return false; // first install — no prior uid
    return stored != newUid;
  }

  // ── Wipe ─────────────────────────────────────────────────────────────────────

  /// Wipe all local device state: Isar collections, notification schedule,
  /// and the prefs keys that guard first-launch seeding.
  ///
  /// Does **not** call `FirebaseAuth.signOut()` — the caller is responsible
  /// for that (so the order is: clear local → then sign out, giving the
  /// reactive [AuthGate] a clean state to present).
  static Future<void> clearLocalSession() async {
    // 1. Cancel all pending OS notifications.
    await LocalNotificationsService.instance.cancelAll();

    // 2. Wipe Isar (all collections).
    await OfflineStore.instance.clearAll();

    // 3. Drop any queued offline writes — they belong to the previous user
    //    and must never replay into the next account's Firestore tree.
    await SyncService.instance.clearQueue();

    // 3b. Drop sync cursors so the next account's first pull is a FULL pull
    //     (cursors describe the previous account's merge progress).
    await SyncCursorStore.clearAll();

    // 4. Clear the relevant SharedPreferences keys.
    //    NOTE: kLastSignedInUidPrefsKey is intentionally kept so that the next
    //    restart can detect whether a *different* account signed in and trigger
    //    another wipe if needed. Removing it here would cause every cold-start
    //    after a logout to look like a "new install" and loop-wipe indefinitely.
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.remove('isar_seeded_v1'),
      prefs.remove('notification_task_id_index_v1'),
    ]);
  }
}
