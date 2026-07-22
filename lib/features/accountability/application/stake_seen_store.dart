import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../auth/application/auth_providers.dart';

/// Marker keys for "the user has LOOKED at this state of this challenge".
/// One key per badge-worthy item; a state change mints a new key, so an
/// already-seen challenge re-arms the badge when something new happens
/// (invite → active day N → their-word each get their own marker).
class StakeSeenKeys {
  StakeSeenKeys._();

  static String invite(String challengeId) => 'invite_$challengeId';

  /// Per-day: seeing today's due evidence doesn't see tomorrow's.
  static String evidence(String challengeId, int unitIndex) =>
      'evidence_${challengeId}_$unitIndex';

  static String confirm(String challengeId) => 'confirm_$challengeId';
}

/// Device-local, per-account set of seen markers (like a notification
/// tray's read state — a fresh install shows pending items as new again).
/// Opening a challenge's detail screen marks its current badge-worthy
/// state seen; the badge counts only unseen items.
final stakeSeenProvider =
    StateNotifierProvider<StakeSeenController, Set<String>>(
  (ref) => StakeSeenController(ref),
);

class StakeSeenController extends StateNotifier<Set<String>> {
  StakeSeenController([this._ref]) : super(const {}) {
    _init();
  }

  final Ref? _ref;
  String? _uid;

  static String _prefsKey(String uid) => 'stake_seen_v1_$uid';

  void _init() {
    final ref = _ref;
    if (ref == null) return; // test-constructed: state managed directly
    ref.listen<String?>(authUidProvider, (_, uid) {
      _load(uid);
    }, fireImmediately: true);
  }

  Future<void> _load(String? uid) async {
    _uid = uid;
    if (uid == null || uid.isEmpty) {
      if (mounted) state = const {};
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final seen = (prefs.getStringList(_prefsKey(uid)) ?? const []).toSet();
    // Guard against a stale async load landing after an account switch.
    if (mounted && _uid == uid) state = seen;
  }

  /// Idempotent: already-seen keys cause no state change (and therefore no
  /// rebuild), so callers may invoke this on every screen build.
  Future<void> markSeen(Iterable<String> keys) async {
    final uid = _uid;
    if (uid == null || uid.isEmpty) return;
    final fresh = keys.where((k) => !state.contains(k)).toList();
    if (fresh.isEmpty) return;
    final next = {...state, ...fresh};
    if (mounted) state = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey(uid), next.toList());
  }
}
