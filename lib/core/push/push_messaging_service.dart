import 'dart:async';
import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/intentions/application/intentions_providers.dart';
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

  /// Wires token registration + message handlers. Safe to call more than
  /// once; only the first call takes effect.
  Future<void> initialize(ProviderContainer container) async {
    _container = container;
    if (_wired || !_firebaseReady) return;
    _wired = true;
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      FirebaseMessaging.onMessage.listen(_onForegroundMessage);
      messaging.onTokenRefresh.listen((token) {
        unawaited(_registerToken(token));
      });
      final token = await messaging.getToken();
      if (token != null) await _registerToken(token);
    } catch (e) {
      debugPrint('[Push] initialize skipped: $e');
    }
  }

  /// App-open heartbeat: the freshness signal the sweep uses to choose a
  /// quiet data push over a louder notification-fallback push. Throttled to
  /// once per local day so a chatty foreground cycle doesn't churn the doc.
  Future<void> recordHeartbeat({DateTime? now}) async {
    if (!_firebaseReady) return;
    final today = dayKey(now ?? DateTime.now());
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getString(_lastHeartbeatDayKey) == today) return;
      final deviceId = await _deviceId(prefs);
      await outboxUpsert(
        entityType: 'deviceToken',
        documentPath: FirestorePaths.deviceTokenDocument(deviceId),
        payload: heartbeatPayload(
          nowMs: (now ?? DateTime.now()).millisecondsSinceEpoch,
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
        ),
      );
    } catch (e) {
      debugPrint('[Push] token register skipped: $e');
    }
  }

  /// App-alive data push → replan locally through the orchestrator. We only
  /// act on our own rescue payloads; everything else is ignored.
  void _onForegroundMessage(RemoteMessage message) {
    if (!isRescueReplan(message.data)) return;
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
