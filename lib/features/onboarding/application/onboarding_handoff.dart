import 'package:shared_preferences/shared_preferences.dart';

/// What the onboarding flow asked the app to do once an account exists.
///
/// The flow runs ABOVE AuthGate (decision log 2026-07-12), so anything that
/// needs a uid — replicating the profile through the outbox, creating the
/// first goal — has to wait for the anonymous sign-in that follows the flow.
/// The flow leaves this device-level marker; `OnboardingHandoffBridge`
/// (main tab shell) consumes it exactly once.
enum OnboardingHandoffKind {
  /// Replicate the saved profile, nothing more ("Not now" / Go to Home).
  syncOnly,

  /// Replicate, then open the first-goal picker and the ready screen.
  firstGoal,
}

abstract final class OnboardingHandoff {
  static const String prefsKey = 'onboarding_handoff_v1';

  static Future<void> schedule(OnboardingHandoffKind kind) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefsKey, kind.name);
  }

  /// Reads and clears the marker. Null when nothing is pending.
  static Future<OnboardingHandoffKind?> consume() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(prefsKey);
    if (raw == null) return null;
    await prefs.remove(prefsKey);
    for (final k in OnboardingHandoffKind.values) {
      if (k.name == raw) return k;
    }
    return null;
  }
}
