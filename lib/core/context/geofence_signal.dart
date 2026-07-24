import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Home-exit geofence signal plumbing (humanizing Phase 6b, PRD §9
/// Tier 3).
///
/// Privacy contract, enforced by construction: ONE region ("home",
/// explicit one-time setup — settled with Miko 2026-07-24), no POI
/// regions, no tracking, no history. Raw coordinates cross the bridge
/// only during home setup and live device-local in UserDefaults; they
/// never enter Isar, Firestore, or an AI payload.
///
/// The user's choice is device-local and tri-state (undecided/enabled/
/// declined), same contract as the calendar and activity signals — but
/// the ASK is per-intention (PRD: "Want me to use your location for this
/// one?"), so the choice here only gates the machinery; each intention
/// opts in individually (see `geofence_arming.dart`).

@immutable
class HomeLocation {
  const HomeLocation({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;

  static HomeLocation? fromMap(Map<Object?, Object?>? map) {
    final lat = map?['latitude'];
    final lon = map?['longitude'];
    if (lat is! double || lon is! double) return null;
    return HomeLocation(latitude: lat, longitude: lon);
  }
}

enum GeofenceSignalChoice { undecided, enabled, declined }

/// Device-local persistence of the user's location decision.
class GeofenceSignalSettings {
  static const prefsKey = 'geofence_signal_choice_v1';

  Future<GeofenceSignalChoice> getChoice() async {
    final prefs = await SharedPreferences.getInstance();
    return switch (prefs.getString(prefsKey)) {
      'enabled' => GeofenceSignalChoice.enabled,
      'declined' => GeofenceSignalChoice.declined,
      _ => GeofenceSignalChoice.undecided,
    };
  }

  Future<void> setChoice(GeofenceSignalChoice choice) async {
    final prefs = await SharedPreferences.getInstance();
    if (choice == GeofenceSignalChoice.undecided) {
      await prefs.remove(prefsKey);
    } else {
      await prefs.setString(prefsKey, choice.name);
    }
  }
}

/// Thin wrapper over the native channel. Every call degrades to "signal
/// unavailable" on platforms without the channel (Android, tests).
class GeofenceSignalChannel {
  static const _channel = MethodChannel('sidepal/geofence_signal');

  /// 'notDetermined' | 'whenInUse' | 'always' | 'denied' | 'unavailable'.
  Future<String> getAuthorizationStatus() async {
    try {
      return await _channel.invokeMethod<String>('getAuthorizationStatus') ??
          'unavailable';
    } catch (_) {
      return 'unavailable';
    }
  }

  /// Runs the whenInUse → Always ladder; resolves with the final status.
  Future<String> requestAccess() async {
    try {
      return await _channel.invokeMethod<String>('requestAccess') ??
          'unavailable';
    } catch (_) {
      return 'unavailable';
    }
  }

  /// One-shot coordinates — home setup ONLY; never called elsewhere.
  Future<HomeLocation?> getCurrentLocation() async {
    try {
      final raw = await _channel.invokeMapMethod<Object?, Object?>(
        'getCurrentLocation',
      );
      return HomeLocation.fromMap(raw);
    } catch (e) {
      debugPrint('[GeofenceSignal] location read failed: $e');
      return null;
    }
  }

  Future<bool> setHome(HomeLocation home) async {
    try {
      return await _channel.invokeMethod<bool>('setHome', {
            'latitude': home.latitude,
            'longitude': home.longitude,
          }) ??
          false;
    } catch (_) {
      return false;
    }
  }

  Future<void> clearHome() async {
    try {
      await _channel.invokeMethod<void>('clearHome');
    } catch (_) {}
  }

  Future<bool> hasHome() async {
    try {
      return await _channel.invokeMethod<bool>('hasHome') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Replaces the native armed list wholesale — Dart owns the truth and
  /// re-syncs on every app open; native only consumes it at exit time.
  Future<void> setArmedIntents(List<Map<String, dynamic>> intents) async {
    try {
      await _channel.invokeMethod<void>('setArmedIntents', {
        'intents': intents,
      });
    } catch (e) {
      debugPrint('[GeofenceSignal] arm sync failed: $e');
    }
  }
}
