import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

/// Remote Config key acting as a kill switch for all AI features.
/// When false, clients fall back to mock/deterministic behavior.
///
/// The OpenAI API key is NOT distributed to clients — it lives in Google
/// Secret Manager and is only readable by the `aiChat` Cloud Function proxy.
const String kRemoteConfigAiEnabled = 'ai_enabled';

/// Minimum fetch interval for Remote Config in production.
const Duration kRemoteConfigFetchInterval = Duration(hours: 1);

/// Remote Config service for AI configuration values.
///
/// Design:
/// - Fetches and activates on first call; subsequent calls use in-memory cache.
/// - Never throws; all errors are caught and logged, and safe defaults are
///   returned (AI enabled — the Cloud Function is the real gate).
class AiRemoteConfigService {
  AiRemoteConfigService._();
  static final AiRemoteConfigService instance = AiRemoteConfigService._();

  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    try {
      final rc = FirebaseRemoteConfig.instance;
      await rc.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: kDebugMode
              ? Duration
                    .zero // instant refresh in debug
              : kRemoteConfigFetchInterval,
        ),
      );
      // Sensible defaults so the app never crashes before first fetch.
      await rc.setDefaults(const {kRemoteConfigAiEnabled: true});
      await rc.fetchAndActivate();
      _initialized = true;
      debugPrint('[AiRemoteConfigService] Initialized and activated.');
    } catch (e) {
      debugPrint('[AiRemoteConfigService] Init failed: $e');
      // Mark initialized so we don't retry on every call in the same session.
      _initialized = true;
    }
  }

  bool _lastKnownAiEnabled = true;

  /// Whether AI features are enabled. Acts as a remote kill switch; when
  /// false, callers must use their honest/deterministic fallbacks.
  Future<bool> isAiEnabled() async {
    await _ensureInitialized();
    try {
      _lastKnownAiEnabled = FirebaseRemoteConfig.instance.getBool(
        kRemoteConfigAiEnabled,
      );
      return _lastKnownAiEnabled;
    } catch (e) {
      debugPrint('[AiRemoteConfigService] Failed to read ai_enabled: $e');
      return true;
    }
  }

  /// Synchronous view of the last [isAiEnabled] read (default true before
  /// any read). For sync call sites that cannot await — e.g. the voice
  /// streaming gate, which must respect the kill switch the async client
  /// build already honored (fix-wave Phase 0, GPT-5.6 G13).
  bool get lastKnownAiEnabled => _lastKnownAiEnabled;

  /// Force a fresh fetch from Firebase — useful after a config push.
  Future<void> refresh() async {
    _initialized = false;
    await _ensureInitialized();
  }
}
