import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../auth/application/auth_providers.dart';

/// Legacy device-wide key. No longer read — deleted on init so a flag set
/// under the old (unscoped) scheme can't leak into a signed-in account.
const String _kLegacyPrefsKey = 'tester_mode_enabled_v1';

String _prefsKeyForUid(String uid) => 'tester_mode_enabled_v2_$uid';

/// Result of a tester-mode toggle attempt, so the UI can message correctly.
enum TesterToggleOutcome { enabled, disabled, accountRequired, notAllowlisted }

/// Server allowlist (pre-launch audit M11, decision 2026-09-15 D5): tester
/// mode is GRANTED per account through `tester_allowlist/{uid}` (owner-read,
/// written only from the console), so the seven-tap gesture is a request,
/// not a grant — a curious customer or reviewer cannot unlock the billed
/// AI recompute button or the tester surfaces. Without Firebase (VM tests)
/// the check passes so controller behaviour stays testable.
Future<bool> defaultTesterAllowlistCheck(String uid) async {
  if (Firebase.apps.isEmpty) return true;
  try {
    final snap = await FirebaseFirestore.instance
        .doc('tester_allowlist/$uid')
        .get()
        .timeout(const Duration(seconds: 6));
    return snap.exists;
  } catch (e) {
    debugPrint('[TesterMode] allowlist check failed: $e');
    return false;
  }
}

/// Whether the current **account** belongs to a beta tester.
///
/// Tester mode is a per-account privilege, not a device setting:
///   * Stored per uid, so accounts are isolated.
///   * Only effective for registered (non-anonymous) accounts.
///   * Cannot be enabled from an anonymous/guest session — so it can never be
///     switched on while browsing as a guest and then carried into a real
///     account (the anonymous→registered upgrade preserves the uid).
///
/// When on, the floating bug-report bubble is shown on every screen. Toggled
/// by tapping the Profile version footer [SevenTapDetector.target] times.
class TesterModeController extends StateNotifier<bool> {
  TesterModeController([this._ref, Future<bool> Function(String uid)? isAllowlisted])
    : _isAllowlisted = isAllowlisted ?? defaultTesterAllowlistCheck,
      super(false) {
    _init();
  }

  final Ref? _ref;
  final Future<bool> Function(String uid) _isAllowlisted;

  String? _uid;
  bool _registered = false;
  bool _enabledForAccount = false;

  void _init() {
    // Test-constructed instances (no ref) set state directly and must not
    // touch SharedPreferences or auth.
    final ref = _ref;
    if (ref == null) return;
    _purgeLegacyKey();
    // React to both the signed-in uid (account isolation) and whether that
    // account is registered (anonymous/guest sessions never qualify).
    ref.listen<String?>(authUidProvider, (_, uid) {
      _recompute(uid, ref.read(isRegisteredProvider));
    }, fireImmediately: true);
    ref.listen<bool>(isRegisteredProvider, (_, registered) {
      _recompute(ref.read(authUidProvider), registered);
    }, fireImmediately: true);
  }

  Future<void> _purgeLegacyKey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kLegacyPrefsKey);
  }

  Future<void> _recompute(String? uid, bool registered) async {
    final uidChanged = uid != _uid;
    _uid = uid;
    _registered = registered;

    // Anonymous or signed-out: tester mode is never effective. Do not read any
    // stored flag — this is what stops guest state carrying into an account.
    if (uid == null || !registered) {
      _enabledForAccount = false;
      if (mounted) state = false;
      return;
    }

    if (uidChanged || !_enabledForAccount) {
      final prefs = await SharedPreferences.getInstance();
      _enabledForAccount = prefs.getBool(_prefsKeyForUid(uid)) ?? false;
    }
    if (mounted) state = _enabledForAccount;
  }

  /// Flips tester mode for the signed-in account. Ignored for anonymous or
  /// signed-out sessions, returning [TesterToggleOutcome.accountRequired].
  Future<TesterToggleOutcome> toggle() async {
    final uid = _uid;
    if (uid == null || !_registered) {
      return TesterToggleOutcome.accountRequired;
    }
    // Enabling needs the server grant; disabling never does.
    if (!_enabledForAccount && !await _isAllowlisted(uid)) {
      return TesterToggleOutcome.notAllowlisted;
    }
    if (_uid != uid) return TesterToggleOutcome.accountRequired;
    _enabledForAccount = !_enabledForAccount;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKeyForUid(uid), _enabledForAccount);
    if (mounted) state = _enabledForAccount;
    return _enabledForAccount
        ? TesterToggleOutcome.enabled
        : TesterToggleOutcome.disabled;
  }
}

final testerModeProvider = StateNotifierProvider<TesterModeController, bool>(
  (ref) => TesterModeController(ref),
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
