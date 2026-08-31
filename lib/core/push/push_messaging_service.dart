import 'dart:async';
import 'dart:io' show Platform;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/notification_response_handler.dart'
    show requestCoachBriefNavigation;
import '../../features/intentions/application/intentions_providers.dart';
import '../../features/profile/application/profile_providers.dart';
import '../firebase/firestore_paths.dart';
import '../sync/outbox_writer.dart';
import '../utils/stable_id.dart';
import 'push_messaging_support.dart';

/// Background isolate handler (humanizing Phase 5). iOS does NOT deliver
/// data-only pushes to a force-quit app, so this fires only for warm/
/// backgrounded states where a `notification`-type push arrived with a data
/// payload. We do no work here — the client replans on next foreground via
/// the app-open heartbeat + resume recompute; a background isolate has no
/// navigator and must stay cheap.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Intentionally empty: correctness floor is the local alarm ladder; push
  // only improves timing while the app can act on it.
}

/// Owns FCM transport for the server rescue-net (Phase 5, PRD §8):
/// registers this device's token to a synced doc, stamps the app-open
/// heartbeat the sweep reads, and turns an app-alive data push into a local
/// replan **through the attention orchestrator** — a push can never bypass
/// the double-gate or fire into a focus override.
///
/// Every plugin call is guarded: with Firebase uninitialised (VM tests) or
/// on a platform without APNs configured, the service degrades to a no-op
/// and the local alarm ladder remains the correctness floor.
class PushMessagingService {
  PushMessagingService._();
  static final PushMessagingService instance = PushMessagingService._();

  static const _deviceIdKey = 'push_device_id_v1';
  static const _lastHeartbeatDayKey = 'push_last_heartbeat_day_v1';

  bool _wired = false;
  ProviderContainer? _container;

  /// Uid whose Firestore tree holds this device's token doc. Account
  /// boundary state (P1-01): a sign-in with a DIFFERENT uid must re-scope
  /// the token immediately instead of waiting for a process restart or an
  /// FCM token rotation.
  String? _registeredUid;

  /// Whether the [L-PUSH] rescue net has this device registered — read by the
  /// reminder health row (FR-R-80). Push is an ADDITIVE floor, never a
  /// dependency, so "not registered" is reported as context, not a fault.
  bool get isRegistered => _registeredUid != null;

  /// Wires token registration + message handlers. Safe to call more than
  /// once; only the first call takes effect.
  Future<void> initialize(ProviderContainer container) async {
    _container = container;
    if (_wired || !_firebaseReady) return;
    _wired = true;
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();
      // A rescue that arrives while the app is OPEN must not banner over
      // the user — the app replans instead (client-side dedupe). The OS
      // still displays it normally when the app is backgrounded/killed.
      await messaging.setForegroundNotificationPresentationOptions(
        alert: false,
        badge: false,
        sound: false,
      );
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      FirebaseMessaging.onMessage.listen(_onForegroundMessage);
      // Tap on a rescue notification (background → foreground): the app is
      // now alive, so the local ladder takes over — replan immediately.
      FirebaseMessaging.onMessageOpenedApp.listen(_onRescueInteraction);
      final launchMessage = await messaging.getInitialMessage();
      if (launchMessage != null) _onRescueInteraction(launchMessage);
      messaging.onTokenRefresh.listen((token) {
        unawaited(_registerToken(token));
      });
      // Account boundary (P1-01): re-scope the token when the signed-in
      // uid changes. authStateChanges emits the current user on listen,
      // which also covers the signed-out-boot race where the initial
      // registration was enqueued under the fallback uid and dropped.
      FirebaseAuth.instance.authStateChanges().listen((user) {
        unawaited(_onAuthChanged(user?.uid));
      });
      final token = await messaging.getToken();
      if (token != null) await _registerToken(token);
    } catch (e) {
      debugPrint('[Push] initialize skipped: $e');
    }
  }

  /// Sign-in with a different account than the token doc was written
  /// under: refresh the registration under the NEW user's tree and reset
  /// the heartbeat day gate so the new account is "seen today" at once.
  Future<void> _onAuthChanged(String? uid) async {
    if (uid == null || uid == _registeredUid) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_lastHeartbeatDayKey);
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) await _registerToken(token);
      await recordHeartbeat();
    } catch (e) {
      debugPrint('[Push] auth re-registration skipped: $e');
    }
  }

  /// Logout boundary (P1-01): remove this device's token doc from the
  /// OUTGOING user's tree so their rescue / morning-brief pushes can never
  /// appear on a device someone else now uses. Must be called while the
  /// outgoing user is still authenticated (before `signOut()`).
  ///
  /// Network-inherent by nature — the doc lives server-side and the outbox
  /// queue is about to be cleared — so this is a direct best-effort delete
  /// with a short timeout. An offline logout leaves the doc behind
  /// (accepted residual risk: the sweep prunes dead tokens on first
  /// failed send).
  Future<void> deregisterDevice() async {
    if (!_firebaseReady) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      // The next account must not inherit this account's heartbeat gate.
      await prefs.remove(_lastHeartbeatDayKey);
      _registeredUid = null;
      final deviceId = prefs.getString(_deviceIdKey);
      if (deviceId == null || deviceId.isEmpty) return;
      await FirebaseFirestore.instance
          .doc(FirestorePaths.deviceTokenDocument(deviceId))
          .delete()
          .timeout(const Duration(seconds: 3));
    } catch (e) {
      debugPrint('[Push] deregister skipped: $e');
    }
  }

  /// App-open heartbeat: the freshness signal the sweep uses to choose a
  /// quiet data push over a louder notification-fallback push. Throttled to
  /// once per local day so a chatty foreground cycle doesn't churn the doc.
  /// Throttle between heartbeat writes. Was once per local DAY — fine when
  /// the only reader was the morning brief, but the reminder rescue rules
  /// (task 13.1/13.3) read lastSeenMs as a 30-minute freshness signal: with
  /// a daily beat, a device alive all afternoon still looked dark and the
  /// crit-3 net could double an armed ladder. Twenty minutes keeps the beat
  /// inside the rules' window at one cheap outbox write per interval.
  static const Duration _kHeartbeatMinInterval = Duration(minutes: 20);
  int _lastHeartbeatMs = 0;

  Future<void> recordHeartbeat({DateTime? now}) async {
    if (!_firebaseReady) return;
    final nowDt = now ?? DateTime.now();
    final today = dayKey(nowDt);
    try {
      final prefs = await SharedPreferences.getInstance();
      final nowMs = nowDt.millisecondsSinceEpoch;
      if (nowMs - _lastHeartbeatMs < _kHeartbeatMinInterval.inMilliseconds) {
        return;
      }
      _lastHeartbeatMs = nowMs;
      final deviceId = await _deviceId(prefs);
      await outboxUpsert(
        entityType: 'deviceToken',
        documentPath: FirestorePaths.deviceTokenDocument(deviceId),
        payload: heartbeatPayload(
          nowMs: (now ?? DateTime.now()).millisecondsSinceEpoch,
          tzOffsetMinutes: (now ?? DateTime.now()).timeZoneOffset.inMinutes,
          morningBriefEnabled: await _morningBriefEnabled(),
        ),
      );
      await prefs.setString(_lastHeartbeatDayKey, today);
    } catch (e) {
      debugPrint('[Push] heartbeat skipped: $e');
    }
  }

  Future<void> _registerToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final deviceId = await _deviceId(prefs);
      await outboxUpsert(
        entityType: 'deviceToken',
        documentPath: FirestorePaths.deviceTokenDocument(deviceId),
        payload: deviceTokenPayload(
          token: token,
          platform: _platformName,
          nowMs: DateTime.now().millisecondsSinceEpoch,
          tzOffsetMinutes: DateTime.now().timeZoneOffset.inMinutes,
          morningBriefEnabled: await _morningBriefEnabled(),
        ),
      );
      // Remember which user's tree the write was scoped to, so a later
      // sign-in under a different uid triggers a re-registration.
      _registeredUid = FirestorePaths.activeUid;
    } catch (e) {
      debugPrint('[Push] token register skipped: $e');
    }
  }

  /// App-alive data push → replan locally through the orchestrator. A
  /// rescue NOTIFICATION arriving in foreground gets the same treatment
  /// (its banner is suppressed above — the replan IS the dedupe). Anything
  /// else is ignored.
  void _onForegroundMessage(RemoteMessage message) {
    if (!isRescueReplan(message.data) &&
        !isRescueNotification(message.data) &&
        !isReminderRescue(message.data)) {
      return;
    }
    _replan();
  }

  /// User tapped a server push (or launched the app from one). A rescue
  /// tap means the app is alive again — the local ladder resumes
  /// ownership, so replan; default navigation lands on Home where the
  /// Promises strip shows the closing intention. A morning-brief tap
  /// opens the Coach with the suggestions panel — the same destination
  /// as the in-app snackbar the push replaces.
  void _onRescueInteraction(RemoteMessage message) {
    if (isMorningBrief(message.data)) {
      requestCoachBriefNavigation();
      return;
    }
    if (!isRescueNotification(message.data) &&
        !isReminderRescue(message.data)) {
      return;
    }
    _replan();
  }

  /// The morning-brief opt-in lives per-device (the preference never
  /// synced), mirrored onto the deviceTokens doc. Toggling in Profile
  /// calls this immediately — waiting for tomorrow's heartbeat would
  /// mean a user who enables the brief and then doesn't open the app
  /// never gets one.
  Future<void> mirrorMorningBriefEnabled(bool enabled) async {
    if (!_firebaseReady) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final deviceId = await _deviceId(prefs);
      await outboxUpsert(
        entityType: 'deviceToken',
        documentPath: FirestorePaths.deviceTokenDocument(deviceId),
        payload: morningBriefFlagPayload(
          enabled: enabled,
          nowMs: DateTime.now().millisecondsSinceEpoch,
        ),
      );
    } catch (e) {
      debugPrint('[Push] brief flag mirror skipped: $e');
    }
  }

  Future<bool> _morningBriefEnabled() async {
    final container = _container;
    if (container == null) return false;
    try {
      final pref = await container
          .read(profilePreferenceRepositoryProvider)
          .getPreference();
      return pref?.morningBriefEnabled ?? false;
    } catch (_) {
      return false;
    }
  }

  void _replan() {
    final container = _container;
    if (container == null) return;
    unawaited(() async {
      try {
        // applyAll reschedules every plannable intention; each slot still
        // flows through AttentionOrchestrator.evaluate(), so overrides,
        // quiet hours, and the 64-cap all hold — the second gate.
        await container.read(intentionNudgeSyncServiceProvider).applyAll();
      } catch (e) {
        debugPrint('[Push] replan skipped: $e');
      }
    }());
  }

  Future<String> _deviceId(SharedPreferences prefs) async {
    final existing = prefs.getString(_deviceIdKey);
    if (existing != null && existing.isNotEmpty) return existing;
    final generated = StableId.generate('device');
    await prefs.setString(_deviceIdKey, generated);
    return generated;
  }

  bool get _firebaseReady => Firebase.apps.isNotEmpty;

  String get _platformName {
    if (kIsWeb) return 'web';
    if (Platform.isIOS) return 'ios';
    if (Platform.isAndroid) return 'android';
    return 'other';
  }
}
