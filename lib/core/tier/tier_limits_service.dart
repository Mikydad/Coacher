import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

import 'tier_limits.dart';

/// Remote Config key holding the whole [TierLimits] blob as one JSON string.
/// Changing any limit is a Firebase-console edit — no app release.
const String kRemoteConfigTierLimits = 'tier_limits_v1';

/// Remote Config reader for tier limits, mirroring [AiRemoteConfigService]:
/// fetch-and-activate once, in-memory afterwards, never throws.
///
/// Deliberately does NOT call `setDefaults` — Remote Config defaults are a
/// single shared map per app, and a second `setDefaults` call would clobber
/// the AI service's `ai_enabled` default. Absence of a fetched value reads
/// as an empty string, which [TierLimits.parse] resolves to the compiled-in
/// [TierLimits.defaults].
class TierLimitsService {
  TierLimitsService._();
  static final TierLimitsService instance = TierLimitsService._();

  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    try {
      final rc = FirebaseRemoteConfig.instance;
      await rc.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: kDebugMode
              ? Duration.zero
              : const Duration(hours: 1),
        ),
      );
      await rc.fetchAndActivate();
      _initialized = true;
    } catch (e) {
      debugPrint('[TierLimitsService] Init failed: $e');
      // Mark initialized so we don't retry on every call in the same session.
      _initialized = true;
    }
  }

  /// Current limits: fetched value if available, [TierLimits.defaults]
  /// otherwise (offline, unfetched, or malformed console value).
  Future<TierLimits> limits() async {
    await _ensureInitialized();
    try {
      final raw = FirebaseRemoteConfig.instance.getString(
        kRemoteConfigTierLimits,
      );
      return TierLimits.parse(raw);
    } catch (e) {
      debugPrint('[TierLimitsService] Failed to read limits: $e');
      return TierLimits.defaults;
    }
  }

  /// Force a fresh fetch from Firebase — useful after a config push.
  Future<void> refresh() async {
    _initialized = false;
    await _ensureInitialized();
  }
}
