import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_colors.dart';

const String _kPrefsKey = 'app_brightness_v1';

/// Initial brightness, resolved from prefs in `main()` BEFORE `runApp` so the
/// first frame already renders in the persisted mode (no dark→light flash).
Brightness appInitialBrightness = Brightness.dark;

/// Reads the persisted brightness and primes [AppColors.palette]. Called from
/// the pre-frame bootstrap path in `main()`.
Future<void> loadPersistedBrightness() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(_kPrefsKey);
  appInitialBrightness = raw == 'light' ? Brightness.light : Brightness.dark;
  AppColors.palette = appInitialBrightness == Brightness.light
      ? AppPalette.light
      : AppPalette.dark;
}

/// App-wide dark/light toggle (Obsidian Pulse / Obsidian Pulse Light).
///
/// The app root watches this, points [AppColors.palette] at the matching
/// palette, and rebuilds the whole tree (MaterialApp is keyed on the
/// brightness) — that full rebuild is what lets the static `AppColors.x`
/// lookups repaint everywhere without threading a BuildContext through
/// hundreds of call sites.
class ThemeBrightnessController extends StateNotifier<Brightness> {
  ThemeBrightnessController() : super(appInitialBrightness);

  Future<void> toggle() =>
      set(state == Brightness.dark ? Brightness.light : Brightness.dark);

  Future<void> set(Brightness value) async {
    if (value == state) return;
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kPrefsKey,
      value == Brightness.light ? 'light' : 'dark',
    );
  }
}

final themeBrightnessProvider =
    StateNotifierProvider<ThemeBrightnessController, Brightness>(
      (ref) => ThemeBrightnessController(),
    );
