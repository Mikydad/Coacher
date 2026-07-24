import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/context/geofence_signal.dart';
import '../domain/models/intention.dart';

/// Per-intention home-exit arming (humanizing Phase 6b, PRD §9 Tier 3).
///
/// The opt-in is PER INTENTION ("Want me to use your location for this
/// one?") and device-local — the geofence lives on this device, so the
/// synced intention record never carries it. Armed intents are written
/// to the native side with PRERENDERED copy because the exit event may
/// arrive with no Flutter engine alive; each fires at most once per
/// arming and Dart re-syncs (re-arms/prunes) on every replan.
///
/// Florist honesty rule (PRD §9): the copy says "Buy flowers on the
/// way?" — a claim about the USER's departure, which we measured —
/// never "you're near a florist", a POI claim we cannot make.

/// Native-fired nudges stay inside these local hours; an exit outside
/// them keeps the intent armed for the next departure.
const kGeofencePoliteStartHour = 8;
const kGeofencePoliteEndHour = 22;

/// "Buy flowers" → "Buy flowers on the way?" (title-cased action,
/// question form — suggestion-as-question, never a command).
Map<String, String> geofenceNudgeCopy(String title) {
  final action = title.trim().isEmpty ? 'your promise' : title.trim();
  final capitalized = action[0].toUpperCase() + action.substring(1);
  return {'title': 'Heading out?', 'body': '$capitalized on the way?'};
}

/// The armed-intent map the native side consumes at exit time.
Map<String, dynamic> armedIntentPayload(Intention intention) {
  final copy = geofenceNudgeCopy(intention.title);
  return {
    'intentionId': intention.id,
    'title': copy['title'],
    'body': copy['body'],
    'windowStartMs': intention.windowStartMs,
    'windowEndMs': intention.windowEndMs,
    'politeStartHour': kGeofencePoliteStartHour,
    'politeEndHour': kGeofencePoliteEndHour,
  };
}

/// Device-local set of intention ids the user opted into location for.
class GeofenceOptIns {
  static const prefsKey = 'geofence_opted_intents_v1';

  Future<Set<String>> ids() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(prefsKey) ?? const []).toSet();
  }

  Future<void> add(String intentionId) async {
    final prefs = await SharedPreferences.getInstance();
    final current = (prefs.getStringList(prefsKey) ?? const []).toSet();
    current.add(intentionId);
    await prefs.setStringList(prefsKey, current.toList());
  }

  Future<void> remove(String intentionId) async {
    final prefs = await SharedPreferences.getInstance();
    final current = (prefs.getStringList(prefsKey) ?? const []).toSet();
    current.remove(intentionId);
    await prefs.setStringList(prefsKey, current.toList());
  }

  Future<void> retainAll(Set<String> keep) async {
    final prefs = await SharedPreferences.getInstance();
    final current = (prefs.getStringList(prefsKey) ?? const []).toSet();
    final retained = current.intersection(keep);
    if (retained.length != current.length) {
      await prefs.setStringList(prefsKey, retained.toList());
    }
  }
}

/// The consumer-facing arming API: choice + grant + home + per-intention
/// opt-ins, with nullable-style degradation — when anything is missing
/// (declined, no grant, no home, non-iOS) the armed list is simply
/// empty and the time-based ladder remains the only nudge path.
class GeofenceArmingService {
  GeofenceArmingService({
    GeofenceSignalSettings? settings,
    GeofenceSignalChannel? channel,
    GeofenceOptIns? optIns,
    DateTime Function()? now,
  }) : _settings = settings ?? GeofenceSignalSettings(),
       _channel = channel ?? GeofenceSignalChannel(),
       _optIns = optIns ?? GeofenceOptIns(),
       _now = now ?? DateTime.now;

  final GeofenceSignalSettings _settings;
  final GeofenceSignalChannel _channel;
  final GeofenceOptIns _optIns;
  final DateTime Function() _now;

  Future<GeofenceSignalChoice> getChoice() => _settings.getChoice();

  /// Whether arming can work right now: enabled + OS grant + home set.
  Future<bool> isLive() async {
    if (await _settings.getChoice() != GeofenceSignalChoice.enabled) {
      return false;
    }
    final status = await _channel.getAuthorizationStatus();
    if (status != 'always' && status != 'whenInUse') return false;
    return _channel.hasHome();
  }

  /// User said yes (per-intention toggle or Profile switch): request the
  /// OS ladder, remember the outcome. Home setup is a separate step.
  Future<bool> enable() async {
    var status = await _channel.getAuthorizationStatus();
    if (status == 'notDetermined' || status == 'whenInUse') {
      status = await _channel.requestAccess();
    }
    final granted = status == 'always' || status == 'whenInUse';
    await _settings.setChoice(
      granted ? GeofenceSignalChoice.enabled : GeofenceSignalChoice.declined,
    );
    return granted;
  }

  /// Turning the signal off clears the native region AND the armed list —
  /// off means off, nothing keeps firing.
  Future<void> decline() async {
    await _settings.setChoice(GeofenceSignalChoice.declined);
    await _channel.setArmedIntents(const []);
    await _channel.clearHome();
  }

  Future<bool> hasHome() => _channel.hasHome();

  /// Explicit one-time home setup (settled: no inference, no silent
  /// "current location = home"): the caller shows the confirm UI ("Set
  /// your current location as home — do this while you're at home");
  /// this just executes the confirmed choice.
  Future<bool> setHomeToCurrentLocation() async {
    final location = await _channel.getCurrentLocation();
    if (location == null) return false;
    return _channel.setHome(location);
  }

  Future<Set<String>> optedInIds() => _optIns.ids();

  Future<void> optIn(String intentionId) => _optIns.add(intentionId);

  Future<void> optOut(String intentionId) async {
    await _optIns.remove(intentionId);
  }

  /// Recomputes the native armed list from current truth: opted-in ∩
  /// open ∩ window-not-expired. Called on every replan (applyAll) so
  /// completed/expired promises disarm on the next app open at latest.
  Future<void> syncArmed(List<Intention> intentions) async {
    if (!await isLive()) return;
    final nowMs = _now().millisecondsSinceEpoch;
    final opted = await _optIns.ids();
    final armable = intentions
        .where(
          (i) =>
              opted.contains(i.id) &&
              i.status == IntentionStatus.open &&
              i.windowEndMs > nowMs,
        )
        .toList(growable: false);
    // Prune opt-ins for promises that no longer exist or closed.
    await _optIns.retainAll(armable.map((i) => i.id).toSet());
    await _channel.setArmedIntents(
      armable.map(armedIntentPayload).toList(growable: false),
    );
  }
}
