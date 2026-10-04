import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/bootstrap/first_screen_ready.dart';
import '../core/presentation/app_colors.dart';
import '../core/sync/sync_service.dart';
import '../features/auth/application/auth_session_policy.dart';
import 'notification_response_handler.dart';

/// Set to `true` once a first-launch seed pull has fully succeeded (PRD
/// §4.6) — or at once for an account created on this device, which has
/// nothing to pull. [AuthSessionPolicy.clearLocalSession] removes it, so a
/// uid change leads to exactly one new seed.
const String kIsarSeededV1PrefsKey = 'isar_seeded_v1';

/// Longest the gate holds the app for a seed (2026-09-22): network speed
/// no longer decides perceived startup. Most launches reveal earlier, when
/// the pull's critical phases land.
const Duration kFirstLaunchRevealCap = Duration(seconds: 5);

/// A seed a test can substitute for [SyncService.syncFromRemote]: resolves
/// with the pull's success and may complete `firstScreenReady` early.
typedef FirstLaunchSeed =
    Future<bool> Function(Completer<void> firstScreenReady);

/// First-launch seed gate — the ONE owner of the Firestore → Isar seed.
///
/// Reveals the app on the first of:
///  * the seeded flag is already set (every later launch);
///  * the signed-in account was created on this device moments ago
///    ([AuthSessionPolicy.consumeAccountCreated], with the metadata
///    fallback) — a brand-new uid has no remote data, so twenty empty
///    queries are skipped;
///  * the seed pull's critical phases have merged (what Home paints first);
///  * [kFirstLaunchRevealCap].
///
/// The pull keeps running behind the live UI — Isar watch streams fill the
/// screens as rows land — and the seeded flag is written only when the pull
/// succeeds, so a failed seed is simply tried again on the next launch.
class FirstLaunchGate extends StatefulWidget {
  const FirstLaunchGate({super.key, required this.child});

  final Widget child;

  /// Widget tests: replaces the SyncService pull.
  @visibleForTesting
  static FirstLaunchSeed? debugSeedForTests;

  /// Per-account "the seed question is settled" signal (2026-09-23): the
  /// gate mounted for [uid] has finished deciding — already seeded, fresh
  /// account, or the pull ended (success or not). Consumers that judge an
  /// account by its local rows (the Getting Started tour's new-vs-existing
  /// probe) await this instead of the reveal, because the reveal cap can
  /// show Home before an existing account's tasks have landed.
  ///
  /// A pending entry is shared: whoever asks first creates it, the mount
  /// for that uid completes it. Asking never reopens a settled question;
  /// only a new mount for that uid does — and
  /// [AuthSessionPolicy.clearLocalSession] forgets every answer along with
  /// the seeded flag, so an account that returns after a switch is seeded,
  /// and judged, afresh.
  static Future<void> seedSettledFor(String uid) =>
      (_seedSettled[uid] ??= Completer<void>()).future;

  static final Map<String, Completer<void>> _seedSettled = {};

  /// Gate mount for [uid]: adopts a pending question, replaces a settled one.
  static Completer<void> _beginFor(String uid) {
    final existing = _seedSettled[uid];
    if (existing != null && !existing.isCompleted) return existing;
    return _seedSettled[uid] = Completer<void>();
  }

  /// Every account's seed question is open again (account boundary).
  static void resetSeedSignals() => _seedSettled.clear();

  @override
  State<FirstLaunchGate> createState() => _FirstLaunchGateState();
}

class _FirstLaunchGateState extends State<FirstLaunchGate> {
  var _ready = false;
  Timer? _capTimer;
  Completer<void>? _seedSettled;

  @override
  void initState() {
    super.initState();
    final uid = SyncService.currentUid();
    if (uid != null) _seedSettled = FirstLaunchGate._beginFor(uid);
    unawaited(_bootstrap());
  }

  @override
  void dispose() {
    _capTimer?.cancel();
    super.dispose();
  }

  void _reveal(String reason, Stopwatch since) {
    FirstScreenReady.mark('$reason (${since.elapsedMilliseconds}ms)');
    if (!mounted) return;
    setState(() => _ready = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      flushPendingNotificationNavigationIntent();
    });
  }

  Future<void> _bootstrap() async {
    try {
      await _decideAndReveal();
    } finally {
      // Every exit — seeded, fresh, pull done, pull threw — settles the
      // account's seed question for [FirstLaunchGate.seedSettledFor].
      final settled = _seedSettled;
      if (settled != null && !settled.isCompleted) settled.complete();
    }
  }

  Future<void> _decideAndReveal() async {
    final since = Stopwatch()..start();
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    if (prefs.getBool(kIsarSeededV1PrefsKey) == true) {
      _reveal('already seeded', since);
      return;
    }

    if (await _isFreshAccount()) {
      await prefs.setBool(kIsarSeededV1PrefsKey, true);
      _reveal('fresh account, nothing to pull', since);
      return;
    }

    final firstScreen = Completer<void>();
    final pull = _seed(firstScreen);
    // Belt and braces: a pull that ends (success, failure, skip) releases
    // the gate even if nothing signalled the critical phases.
    unawaited(
      pull.whenComplete(() {
        if (!firstScreen.isCompleted) firstScreen.complete();
      }),
    );

    final reveal = Completer<String>();
    _capTimer = Timer(kFirstLaunchRevealCap, () {
      if (!reveal.isCompleted) reveal.complete('reveal cap');
    });
    unawaited(
      firstScreen.future.then((_) {
        if (!reveal.isCompleted) reveal.complete('critical phases merged');
      }),
    );
    final reason = await reveal.future;
    _capTimer?.cancel();
    _reveal(reason, since);

    // Honest flag: only a pull that finished counts as seeded.
    var ok = false;
    try {
      ok = await pull;
    } catch (e, st) {
      debugPrint('FirstLaunchGate: seed pull threw: $e\n$st');
    }
    if (ok) await prefs.setBool(kIsarSeededV1PrefsKey, true);
  }

  Future<bool> _seed(Completer<void> firstScreen) {
    final override = FirstLaunchGate.debugSeedForTests;
    if (override != null) return override(firstScreen);
    return SyncService.instance.syncFromRemote(
      force: true,
      firstScreenReady: firstScreen,
    );
  }

  /// An account created on this device moments ago: the sign-in marked it
  /// (`isNewUser`), or — for paths that don't surface that — Firebase's
  /// creation and last-sign-in stamps coincide.
  Future<bool> _isFreshAccount() async {
    final uid = SyncService.currentUid();
    if (uid == null) return false;
    if (await AuthSessionPolicy.consumeAccountCreated(uid)) return true;
    if (Firebase.apps.isEmpty) return false;
    final meta = FirebaseAuth.instance.currentUser?.metadata;
    return AuthSessionPolicy.looksFreshlyCreated(
      creationTime: meta?.creationTime,
      lastSignInTime: meta?.lastSignInTime,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      // Default [Material] uses a light surface — reads as a "blank white screen"
      // with a tiny spinner. Match the app shell so launch reads as intentional loading.
      return Directionality(
        textDirection: TextDirection.ltr,
        child: Material(
          color: AppColors.scaffold,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppColors.accent),
                SizedBox(height: 20),
                Text(
                  'Loading your plan…',
                  style: TextStyle(color: AppColors.fg70, fontSize: 15),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return widget.child;
  }
}
