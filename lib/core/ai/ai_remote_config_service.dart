import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

/// Remote Config key for the OpenAI API key.
/// Set this key in the Firebase console under Remote Config.
const String kRemoteConfigOpenAiApiKey = 'openai_api_key';

/// Remote Config key for the AI model name override.
/// Defaults to gpt-4o-mini if absent or empty.
const String kRemoteConfigOpenAiModel = 'openai_model';

/// Minimum fetch interval for Remote Config in production.
const Duration kRemoteConfigFetchInterval = Duration(hours: 1);

/// Remote Config service for AI configuration values.
///
/// Design:
/// - Fetches and activates on first call; subsequent calls use in-memory cache.
/// - Returns empty string if the key is missing or fetch fails — callers must
///   treat an empty API key as "use mock/fallback".
/// - Never throws; all errors are caught and logged.
class AiRemoteConfigService {
  AiRemoteConfigService._();
  static final AiRemoteConfigService instance = AiRemoteConfigService._();

  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    try {
      final rc = FirebaseRemoteConfig.instance;
      await rc.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: kDebugMode
            ? Duration.zero         // instant refresh in debug
            : kRemoteConfigFetchInterval,
      ));
      // Sensible defaults so the app never crashes before first fetch.
      await rc.setDefaults(const {
        kRemoteConfigOpenAiApiKey: '',
        kRemoteConfigOpenAiModel: 'gpt-4o-mini',
      });
      await rc.fetchAndActivate();
      _initialized = true;
      debugPrint('[AiRemoteConfigService] Initialized and activated.');
    } catch (e) {
      debugPrint('[AiRemoteConfigService] Init failed: $e');
      // Mark initialized so we don't retry on every call in the same session.
      _initialized = true;
    }
  }

  /// Returns the OpenAI API key from Remote Config, or empty string if absent.
  Future<String> getOpenAiApiKey() async {
    await _ensureInitialized();
    try {
      return FirebaseRemoteConfig.instance
          .getString(kRemoteConfigOpenAiApiKey)
          .trim();
    } catch (e) {
      debugPrint('[AiRemoteConfigService] Failed to read API key: $e');
      return '';
    }
  }

  /// Returns the configured model name, defaulting to gpt-4o-mini.
  Future<String> getOpenAiModel() async {
    await _ensureInitialized();
    try {
      final model = FirebaseRemoteConfig.instance
          .getString(kRemoteConfigOpenAiModel)
          .trim();
      return model.isEmpty ? 'gpt-4o-mini' : model;
    } catch (e) {
      return 'gpt-4o-mini';
    }
  }

  /// Force a fresh fetch from Firebase — useful after a config push.
  Future<void> refresh() async {
    _initialized = false;
    await _ensureInitialized();
  }
}
