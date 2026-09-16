import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/notifications/local_notifications_service.dart';
import '../../../core/offline/offline_store.dart';
import '../../../core/push/push_messaging_service.dart';
import '../../../core/session/session_scope.dart';
import '../../../core/storage/app_storage_dir.dart';
import '../../../core/sync/sync_cursor_store.dart';
import '../../../core/sync/sync_service.dart';
import '../../analytics/application/announced_insight_store.dart';
import '../../direction/application/new_month_prompt.dart';
import '../../execution/data/timer_runtime_cache.dart';
import '../../focus/data/focus_resume_store.dart';
import '../../intentions/application/geofence_arming.dart';
import '../../memory/application/memory_extraction_service.dart';
import '../../reminders/application/recovery_triage_service.dart';
import '../../reminders/application/strategist_proposals_store.dart';
import '../../thinking/application/thinking_loop_service.dart';

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
  ///
  /// Order matters (pre-launch audit H2–H4, 2026-09-15):
  ///  * the session generation is bumped FIRST and synchronously, so every
  ///    job that captured a [SessionToken] before this line drops its
  ///    result instead of writing into the wiped store;
  ///  * in-flight writers (remote pull, memory extraction) are DRAINED
  ///    before the wipe — a timeout is not a cancellation;
  ///  * per-account disk caches outside Isar (timer resume file, focus
  ///    resume file, strategist proposals, announced insight, triage
  ///    counter) are cleared, not just the database.
  ///
  /// [transportsAlreadyReleased] — the deletion coordinator releases the
  /// device transports while the user is still authenticated (the push
  /// token doc delete is rejected once the Auth user is gone).
  static Future<void> clearLocalSession({
    bool transportsAlreadyReleased = false,
  }) async {
    SessionScope.beginTeardown();
    try {
      // 0. Account boundary for device-scoped transports (runs FIRST, while
      //    the outgoing user is still authenticated).
      if (!transportsAlreadyReleased) await releaseDeviceTransports();

      // 0b. Join writers that may still be mid-flight for the outgoing
      //     account. Their tokens are already stale (bumped above), so they
      //     abort at their next write; this just waits for that to happen
      //     before the store is cleared underneath them.
      await SyncService.instance.drainInFlightPull();
      await MemoryExtractionService.drainInFlight();

      // 1. Cancel all pending OS notifications.
      await LocalNotificationsService.instance.cancelAll();

      // 1b. Per-account files outside Isar (H4). BEFORE the Isar wipe and
      //     before any lazily recreated controller can reload them.
      await _clearFileCaches();

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
        // Onboarding is per-account (a different sign-in re-evaluates new vs
        // existing); seen feature cards stay device-level on purpose.
        prefs.remove('education_onboarding_state_v1'),
        // Thinking Loop cadence is per-account (P2-10): without this, user
        // A's morning reflection would make user B silently skip theirs for
        // the rest of the local day after an account switch.
        prefs.remove(ThinkingLoopService.lastDayPrefsKey),
        prefs.remove(ThinkingLoopService.inputsHashPrefsKey),
        prefs.remove(ThinkingLoopService.timeWeekDonePrefsKey),
        prefs.remove(ThinkingLoopService.timeMonthDonePrefsKey),
        // Direction's month-card flag is per-account (PRD/Direction §5.3).
        prefs.remove(kDirectionMonthCardHandledPrefsKey),
        // Audit H4: personal coaching copy and per-account counters that
        // used to survive into the next account's session.
        prefs.remove(StrategistProposalsStore.prefsKey),
        prefs.remove(AnnouncedInsightStore.prefsKey),
        prefs.remove(RecoveryTriageService.countPrefsKey),
      ]);
    } finally {
      SessionScope.endTeardown();
    }
  }

  /// Device transports that carry the outgoing account's identity:
  ///  - remove this device's push-token doc from the outgoing user's tree
  ///    so their rescue/brief pushes never reach the next user (P1-01;
  ///    best-effort with timeout, no-op without Firebase);
  ///  - disarm the native home-exit geofence, whose armed list carries the
  ///    outgoing user's intention copy and fires without Flutter alive
  ///    (P1-02; no-op without the iOS channel).
  /// Must run while the outgoing user is still authenticated.
  static Future<void> releaseDeviceTransports() async {
    await PushMessagingService.instance.deregisterDevice();
    await GeofenceArmingService().clearForLogout();
  }

  static Future<void> _clearFileCaches() async {
    Future<void> guard(String what, Future<void> Function() fn) async {
      try {
        await fn();
      } catch (e) {
        debugPrint('[AuthSessionPolicy] $what clear failed: $e');
      }
    }

    await guard('timer runtime cache', const TimerRuntimeCache().clear);
    await guard('focus resume store', FocusResumeStore.deleteFile);
    // Deprecated JSON reminder cache — nothing writes it any more, but an
    // upgraded install may still carry the previous account's copy.
    await guard('legacy reminder cache', () async {
      final dir = await getAppStorageDirectory();
      final file = File('${dir.path}/reminder_cache.json');
      if (await file.exists()) await file.delete();
    });
  }
}
