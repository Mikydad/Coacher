import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/direction_periods.dart';
import 'direction_providers.dart';

/// The month-rollover prompt (decision 7): ONE dismissible Home card at the
/// start of a month — "What's your focus for September?" — and nothing for
/// quarters or years. No notification, no badge, no dot.
///
/// Direction is not something SidePal asks the user to accomplish. It is
/// something SidePal remembers while helping them. The card asks once,
/// then gets out of the way.

/// Per-account prefs key: the month key (`2026-09`) the card was handled
/// for. MUST stay registered in `AuthSessionPolicy.clearLocalSession` and
/// the controller in `invalidateUserScopedProviders`.
const String kDirectionMonthCardHandledPrefsKey =
    'direction_month_card_handled_v1';

enum NewMonthPromptDecision {
  /// Show the card.
  show,

  /// Nothing to show.
  hide,

  /// First evaluation ever on this account/device: record the current
  /// month as handled and show nothing. The card is a *rollover* prompt,
  /// not an onboarding prompt — day-one discovery is the Goals strip and
  /// the Profile row.
  seed,
}

/// Pure visibility rule (§7.1 of the implementation PRD).
NewMonthPromptDecision decideNewMonthPrompt({
  required bool loaded,
  required String? handledMonthKey,
  required String currentMonthKey,
  required bool monthHasText,
}) {
  if (!loaded) return NewMonthPromptDecision.hide;
  if (handledMonthKey == null) return NewMonthPromptDecision.seed;
  if (handledMonthKey == currentMonthKey) return NewMonthPromptDecision.hide;
  if (monthHasText) return NewMonthPromptDecision.hide;
  return NewMonthPromptDecision.show;
}

@immutable
class NewMonthPromptState {
  const NewMonthPromptState({required this.loaded, required this.handledMonthKey});

  static const initial = NewMonthPromptState(loaded: false, handledMonthKey: null);

  final bool loaded;
  final String? handledMonthKey;
}

/// Prefs-backed "handled for month X" flag. Seeds itself on first load so a
/// fresh install never sees the card until an actual rollover.
class NewMonthPromptController extends StateNotifier<NewMonthPromptState> {
  NewMonthPromptController({DateTime Function()? now})
    : _now = now ?? DateTime.now,
      super(NewMonthPromptState.initial) {
    _load();
  }

  final DateTime Function() _now;

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      var key = prefs.getString(kDirectionMonthCardHandledPrefsKey);
      if (key == null) {
        key = DirectionPeriods.keyFor(DirectionHorizon.month, _now());
        await prefs.setString(kDirectionMonthCardHandledPrefsKey, key);
      }
      if (!mounted) return;
      state = NewMonthPromptState(loaded: true, handledMonthKey: key);
    } catch (e) {
      debugPrint('[NewMonthPrompt] load failed: $e');
      if (!mounted) return;
      // Fail closed: no prefs → no card (never nag because storage broke).
      state = NewMonthPromptState(
        loaded: true,
        handledMonthKey: DirectionPeriods.keyFor(
          DirectionHorizon.month,
          _now(),
        ),
      );
    }
  }

  /// Dismissed, opened, or the month got a direction by any path.
  Future<void> markHandled(String monthKey) async {
    if (state.handledMonthKey == monthKey && state.loaded) return;
    state = NewMonthPromptState(loaded: true, handledMonthKey: monthKey);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(kDirectionMonthCardHandledPrefsKey, monthKey);
    } catch (e) {
      debugPrint('[NewMonthPrompt] persist failed: $e');
    }
  }
}

final newMonthPromptControllerProvider =
    StateNotifierProvider<NewMonthPromptController, NewMonthPromptState>(
      (ref) => NewMonthPromptController(),
    );

/// True exactly when the Home card should render. Derived from the prefs
/// flag, the clock and the month slot — a new month appears on the first
/// clock tick after midnight, no restart needed.
final showNewMonthDirectionCardProvider = Provider<bool>((ref) {
  final st = ref.watch(newMonthPromptControllerProvider);
  final now = ref.watch(directionClockProvider);
  final monthKey = DirectionPeriods.keyFor(DirectionHorizon.month, now);
  final slot = ref.watch(currentDirectionProvider)[DirectionHorizon.month];
  final decision = decideNewMonthPrompt(
    loaded: st.loaded,
    handledMonthKey: st.handledMonthKey,
    currentMonthKey: monthKey,
    monthHasText: slot?.hasText ?? false,
  );
  return decision == NewMonthPromptDecision.show;
});
