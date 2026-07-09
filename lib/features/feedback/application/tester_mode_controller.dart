import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _kPrefsKey = 'tester_mode_enabled_v1';

/// Whether this device belongs to a beta tester.
///
/// When on, the floating bug-report bubble is shown on every screen. Toggled
/// by tapping the Profile version footer [SevenTapDetector.target] times —
/// same build for everyone, enabled per device at install time.
class TesterModeController extends StateNotifier<bool> {
  TesterModeController() : super(false) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    // A brief false->true flick at boot is fine; the bubble simply appears.
    if (mounted) state = prefs.getBool(_kPrefsKey) ?? false;
  }

  Future<void> toggle() async {
    state = !state;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kPrefsKey, state);
  }
}

final testerModeProvider = StateNotifierProvider<TesterModeController, bool>(
  (ref) => TesterModeController(),
);

/// Counts rapid consecutive taps; fires after [target] within the window.
class SevenTapDetector {
  SevenTapDetector({this.target = 7, this.window = const Duration(seconds: 2)});

  final int target;

  /// Max gap between two taps before the count resets.
  final Duration window;

  int _count = 0;
  DateTime? _lastTap;

  /// Registers a tap at [now]; returns taps remaining (0 means "fire", and
  /// the detector resets itself for the next round).
  int registerTap(DateTime now) {
    final last = _lastTap;
    if (last == null || now.difference(last) > window) {
      _count = 0;
    }
    _lastTap = now;
    _count++;
    final remaining = target - _count;
    if (remaining <= 0) {
      _count = 0;
      _lastTap = null;
      return 0;
    }
    return remaining;
  }
}
