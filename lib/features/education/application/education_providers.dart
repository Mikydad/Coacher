import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'education_prefs.dart';

/// Which first-time feature cards were dismissed.
///
/// `null` means "prefs still loading" — cards render nothing in that state
/// so a dismissed card can never flash on screen while the disk read runs.
class EducationSeenCardsController extends StateNotifier<Set<String>?> {
  EducationSeenCardsController(this._prefs) : super(null) {
    _load();
  }

  final EducationPrefs _prefs;

  Future<void> _load() async {
    final seen = await _prefs.seenCards();
    if (mounted) state = seen;
  }

  Future<void> markSeen(String guideId) {
    // Optimistic: hide instantly, persist behind.
    state = {...?state, guideId};
    return _prefs.markCardSeen(guideId);
  }
}

final educationSeenCardsProvider =
    StateNotifierProvider<EducationSeenCardsController, Set<String>?>(
      (ref) => EducationSeenCardsController(ref.watch(educationPrefsProvider)),
    );

/// True only when prefs are loaded AND this card was never dismissed.
final showFeatureCardProvider = Provider.family<bool, String>((ref, guideId) {
  final seen = ref.watch(educationSeenCardsProvider);
  return seen != null && !seen.contains(guideId);
});
