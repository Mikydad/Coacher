import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Getting Started onboarding lifecycle. Tri-state on purpose: 'active'
/// records that this account was judged NEW once — otherwise creating your
/// first task would make you look like an existing user on next launch.
/// Values: absent (never evaluated) | 'active' | 'done'.
///
/// Stored PER ACCOUNT since 2026-09-23 (`<prefix>:<uid>`): the verdict
/// belongs to the account it was made for, so an account switch can never
/// hand one account's "done" to the next, whatever order the wipe and the
/// provider rebuild happen in. A guest who registers keeps the same uid
/// (anonymous link), so their tour carries over as it should.
const kOnboardingStatePrefsKey = 'education_onboarding_state_v1';

/// The pre-2026-09-23 device-level key. Read once as a fallback for the
/// account signed in at upgrade time (the wipe removed it on every earlier
/// switch, so it can only describe that account), then deleted.
const kLegacyOnboardingStatePrefsKey = kOnboardingStatePrefsKey;

String onboardingStatePrefsKeyFor(String uid) =>
    '$kOnboardingStatePrefsKey:$uid';

/// Guide ids whose first-time feature card was dismissed (device-level).
const _kSeenCardsKey = 'education_seen_cards_v1';

class EducationPrefs {
  Future<String?> onboardingState(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final scoped = prefs.getString(onboardingStatePrefsKeyFor(uid));
    if (scoped != null) return scoped;
    // One-time migration of the device-level value to this account.
    final legacy = prefs.getString(kLegacyOnboardingStatePrefsKey);
    if (legacy == null) return null;
    await prefs.setString(onboardingStatePrefsKeyFor(uid), legacy);
    await prefs.remove(kLegacyOnboardingStatePrefsKey);
    return legacy;
  }

  Future<void> setOnboardingState(String uid, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(onboardingStatePrefsKeyFor(uid), value);
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
