import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Getting Started onboarding lifecycle. Tri-state on purpose: 'active'
/// records that this account was judged NEW once — otherwise creating your
/// first task would make you look like an existing user on next launch.
/// Values: absent (never evaluated) | 'active' | 'done'.
const kOnboardingStatePrefsKey = 'education_onboarding_state_v1';

/// Guide ids whose first-time feature card was dismissed (device-level).
const _kSeenCardsKey = 'education_seen_cards_v1';

class EducationPrefs {
  Future<String?> onboardingState() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(kOnboardingStatePrefsKey);
  }

  Future<void> setOnboardingState(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kOnboardingStatePrefsKey, value);
  }

  Future<Set<String>> seenCards() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_kSeenCardsKey) ?? const []).toSet();
  }

  Future<void> markCardSeen(String guideId) async {
    final prefs = await SharedPreferences.getInstance();
    final seen = (prefs.getStringList(_kSeenCardsKey) ?? const []).toSet()
      ..add(guideId);
    await prefs.setStringList(_kSeenCardsKey, seen.toList()..sort());
  }
}

final educationPrefsProvider = Provider<EducationPrefs>(
  (_) => EducationPrefs(),
);
