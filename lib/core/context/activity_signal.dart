import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Activity-recognition snapshot (humanizing Phase 6a, PRD §9 Tier 2).
///
/// Privacy contract, enforced by construction: the native channel
/// (ios/Runner/ActivitySignal.swift) returns ONLY a coarse kind
/// (still/walking/…), a confidence label, and the reading's timestamp.
/// Readings are decision-time snapshots — there is NO background stream —
/// live in memory for one computation, and are never persisted anywhere.
///
/// The user's choice is device-local by design (a device permission must
/// not sync) and tri-state, exactly like the calendar signal: undecided →
/// the one-time ask may show; declined → remembered, never re-asked
/// (Profile toggle can re-enable); enabled → signal flows when the OS
/// grant allows.

/// Coarse activity kinds — the ONLY motion shape that crosses the bridge.
enum ActivityKind { still, walking, running, cycling, driving, unknown }

/// One decision-time motion reading.
@immutable
class ActivityReading {
  const ActivityReading({
    required this.kind,
    required this.confidence,
    required this.capturedAtMs,
  });

  final ActivityKind kind;

  /// 'high' | 'medium' | 'low' — from Core Motion, forwarded verbatim.
  final String confidence;

  /// When the reading was taken (native query time — the state itself may
  /// have begun long before; a 40-minute walk is still a current walk).
  final int capturedAtMs;

  static ActivityReading? fromMap(Map<Object?, Object?> map) {
    final rawKind = map['kind'];
    final capturedAtMs = map['capturedAtMs'];
    if (rawKind is! String || capturedAtMs is! int) return null;
    final kind = ActivityKind.values.asNameMap()[rawKind];
    if (kind == null) return null;
    return ActivityReading(
      kind: kind,
      confidence: map['confidence'] is String
          ? map['confidence'] as String
          : 'low',
      capturedAtMs: capturedAtMs,
    );
  }

  @override
  String toString() =>
      'ActivityReading(${kind.name}, $confidence, $capturedAtMs)';
}

enum ActivitySignalChoice { undecided, enabled, declined }

/// Device-local persistence of the user's motion decision.
class ActivitySignalSettings {
  static const prefsKey = 'activity_signal_choice_v1';

  Future<ActivitySignalChoice> getChoice() async {
    final prefs = await SharedPreferences.getInstance();
    return switch (prefs.getString(prefsKey)) {
      'enabled' => ActivitySignalChoice.enabled,
      'declined' => ActivitySignalChoice.declined,
      _ => ActivitySignalChoice.undecided,
    };
  }

  Future<void> setChoice(ActivitySignalChoice choice) async {
    final prefs = await SharedPreferences.getInstance();
    if (choice == ActivitySignalChoice.undecided) {
      await prefs.remove(prefsKey);
    } else {
      await prefs.setString(prefsKey, choice.name);
    }
  }
}

/// Thin wrapper over the native channel. Every call degrades to "signal
/// unavailable" on platforms without the channel (Android, tests).
class ActivitySignalChannel {
  static const _channel = MethodChannel('sidepal/activity_signal');

  /// 'notDetermined' | 'denied' | 'authorized' | 'unavailable'.
  Future<String> getAuthorizationStatus() async {
    try {
      return await _channel.invokeMethod<String>('getAuthorizationStatus') ??
          'unavailable';
    } catch (_) {
      return 'unavailable';
    }
  }

  Future<bool> requestAccess() async {
    try {
      return await _channel.invokeMethod<bool>('requestAccess') ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<ActivityReading?> getCurrentActivity({
    Duration lookback = const Duration(minutes: 10),
  }) async {
    try {
      // CoreMotion can stall indefinitely on a wedged pedometer daemon;
      // a signal that late is useless, so degrade to "no signal" instead
      // of holding every downstream decision hostage.
      final raw = await _channel
          .invokeMapMethod<Object?, Object?>('getCurrentActivity', {
            'lookbackMs': lookback.inMilliseconds,
          })
          .timeout(const Duration(seconds: 2));
      if (raw == null) return null;
      return ActivityReading.fromMap(raw);
    } catch (e) {
      debugPrint('[ActivitySignal] read failed: $e');
      return null;
    }
  }
}

/// The one consumer-facing API: choice + OS grant + read, with nullable
/// degradation — `null` means "the signal doesn't exist right now" and
/// callers decide without it. Provenance honesty follows automatically:
/// copy can only say "you're walking" when a reading actually exists.
class ActivitySignalService {
  ActivitySignalService({
    ActivitySignalSettings? settings,
    ActivitySignalChannel? channel,
  }) : _settings = settings ?? ActivitySignalSettings(),
       _channel = channel ?? ActivitySignalChannel();

  final ActivitySignalSettings _settings;
  final ActivitySignalChannel _channel;

  /// A reading older than this is a memory of a state, not the state.
  static const staleAfter = Duration(minutes: 15);

  Future<ActivitySignalChoice> getChoice() => _settings.getChoice();

  /// Whether the ask card may show: user undecided AND the OS could still
  /// grant (not already denied at system level, channel present).
  Future<bool> shouldOfferAsk() async {
    if (await _settings.getChoice() != ActivitySignalChoice.undecided) {
      return false;
    }
    final status = await _channel.getAuthorizationStatus();
    return status == 'notDetermined' || status == 'authorized';
  }

  /// User said yes: request the OS grant (the first Core Motion query IS
  /// the prompt), remember the outcome. Returns true when live.
  Future<bool> enable() async {
    final status = await _channel.getAuthorizationStatus();
    var granted = status == 'authorized';
    if (status == 'notDetermined') {
      granted = await _channel.requestAccess();
    }
    await _settings.setChoice(
      granted ? ActivitySignalChoice.enabled : ActivitySignalChoice.declined,
    );
    return granted;
  }

  /// User said no (card "Not now" or Profile toggle off) — remembered,
  /// never re-asked.
  Future<void> decline() =>
      _settings.setChoice(ActivitySignalChoice.declined);

  /// The current coarse activity, or **null when the signal is
  /// unavailable** (declined, undecided, OS-denied, non-iOS, stale, or
  /// low-confidence). Fresh + confident or nothing — a wrong "you're
  /// driving" is worse than silence.
  Future<ActivityReading?> currentActivity({DateTime? now}) async {
    if (await _settings.getChoice() != ActivitySignalChoice.enabled) {
      return null;
    }
    if (await _channel.getAuthorizationStatus() != 'authorized') return null;
    final reading = await _channel.getCurrentActivity();
    if (reading == null) return null;
    if (reading.confidence == 'low') return null;
    if (reading.kind == ActivityKind.unknown) return null;
    final nowMs = (now ?? DateTime.now()).millisecondsSinceEpoch;
    if (nowMs - reading.capturedAtMs > staleAfter.inMilliseconds) return null;
    return reading;
  }
}
