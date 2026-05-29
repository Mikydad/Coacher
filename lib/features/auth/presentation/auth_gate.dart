import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/sync/sync_service.dart';
import '../../community/application/circle_providers.dart';
import '../../profile/application/profile_providers.dart';
import '../application/auth_providers.dart';
import '../application/auth_session_policy.dart';
import 'auth_landing_screen.dart';
import 'forgot_password_screen.dart';
import 'login_screen.dart';
import 'sign_up_screen.dart';

/// Root auth gate — sits above [FirstLaunchGate] in the widget tree.
///
/// ## Behaviour
///
/// | Auth state | `kRequireRegisteredAuth` | Result |
/// |---|---|---|
/// | Loading | any | Full-screen spinner |
/// | Signed in | any | `child` (the existing app subtree) |
/// | Signed out | `false` | Trigger anonymous sign-in; spinner while pending |
/// | Signed out | `true` | [AuthLandingScreen] |
///
/// When a user signs in, [AuthGate] also:
/// 1. Detects uid changes and wipes local state before showing the app.
/// 2. Runs a forced remote sync after a uid change.
/// 3. Always persists the current uid for future uid-change detection.
class AuthGate extends ConsumerStatefulWidget {
  const AuthGate({super.key, required this.child});

  /// The app subtree shown when the user is signed in.
  final Widget child;

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate> {
  bool _signingInAnonymously = false;
  bool _handlingUidChange = false;

  @override
  void initState() {
    super.initState();
    // Listen immediately — no addPostFrameCallback — so we never miss the first
    // synchronous emission from Firebase's persisted session cache.
    ref.listenManual(authStateProvider, (_, next) {
      next.whenData(_onAuthStateChanged);
    }, fireImmediately: true);
  }

  Future<void> _onAuthStateChanged(dynamic user) async {
    if (user == null) {
      // Signed out — handle below in build(); nothing to persist.
      return;
    }

    // A user is signed in — clear any pending "show landing" intent so the app
    // proceeds normally and a future cold-start auto-restores guest mode.
    ref.read(pendingAuthLandingProvider.notifier).state = false;

    // Avoid re-entrant uid-change handling.
    if (_handlingUidChange) return;

    final uid = (user as dynamic).uid as String;
    final changed = await AuthSessionPolicy.hasUidChanged(uid);

    if (changed && mounted) {
      setState(() => _handlingUidChange = true);
      try {
        invalidateCircleScopedProviders(ref);
        await AuthSessionPolicy.clearLocalSession();
        await SyncService.instance.syncFromRemote(force: true);
      } finally {
        if (mounted) setState(() => _handlingUidChange = false);
      }
    }

    await AuthSessionPolicy.persistUid(uid);

    // Use the latest Firebase user (displayName may be set after Google profile sync).
    final fresh = ref.read(authRepositoryProvider).currentUser;
    await _syncLocalDisplayNameFromAuth(fresh ?? user);
  }

  /// Profile screen reads display name from Isar — seed it from Firebase after
  /// Google/email sign-in when the user has not set a local name yet.
  Future<void> _syncLocalDisplayNameFromAuth(dynamic user) async {
    final name = (user as dynamic).displayName as String?;
    if (name == null || name.trim().isEmpty) return;
    try {
      await ref
          .read(profilePreferenceServiceProvider)
          .syncDisplayNameFromAuthIfEmpty(name.trim());
    } catch (e, st) {
      debugPrint('[AuthGate] sync local display name failed: $e\n$st');
    }
  }

  Future<void> _triggerAnonymousSignIn() async {
    if (_signingInAnonymously) return;
    setState(() => _signingInAnonymously = true);
    try {
      final (_, user) = await ref.read(authRepositoryProvider).signInAnonymously();
      // Persist the new uid immediately so the next restart does not treat it
      // as a uid change (which would trigger an unnecessary local-data wipe).
      if (user != null) await AuthSessionPolicy.persistUid(user.uid);
    } finally {
      if (mounted) setState(() => _signingInAnonymously = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authAsync = ref.watch(authStateProvider);

    return authAsync.when(
      loading: _buildSpinner,
      error: (e, _) => _buildSpinner(), // fail gracefully — show spinner
      data: (user) {
        // Uid-change wipe in progress — keep spinner visible.
        if (_handlingUidChange) return _buildSpinner();

        if (user != null) {
          return widget.child;
        }

        // Signed out. Show the landing screen when registered auth is required
        // OR when the user explicitly logged out (so logout is meaningful even
        // in guest mode).
        final showLanding =
            kRequireRegisteredAuth || ref.watch(pendingAuthLandingProvider);
        if (showLanding) {
          return const _AuthFlowApp();
        }

        // First-launch guest mode → anonymous sign-in.
        if (!_signingInAnonymously) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _triggerAnonymousSignIn(),
          );
        }
        return _buildSpinner();
      },
    );
  }

  Widget _buildSpinner() {
    return const Directionality(
      textDirection: TextDirection.ltr,
      child: Material(
        color: Color(0xFF050806),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                color: Color(0xFFB7FF00),
                strokeWidth: 2,
              ),
              SizedBox(height: 20),
              Text(
                'Loading your plan…',
                style: TextStyle(color: Colors.white70, fontSize: 15),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Self-contained [MaterialApp] for the signed-out auth flow.
///
/// [AuthGate] lives **above** the main app's [MaterialApp], so when it needs to
/// show the auth screens it must supply its own [MaterialApp] to provide a
/// [Navigator], [Directionality], theme, and the auth route table. When the
/// user signs in, [AuthGate] rebuilds and swaps this out for the main app.
class _AuthFlowApp extends StatelessWidget {
  const _AuthFlowApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Coach for Life',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF050806),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFB7FF00),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const AuthLandingScreen(),
      routes: {
        LoginScreen.routeName: (context) {
          final email =
              ModalRoute.of(context)?.settings.arguments as String?;
          return LoginScreen(prefillEmail: email);
        },
        SignUpScreen.routeName: (_) => const SignUpScreen(),
        ForgotPasswordScreen.routeName: (context) {
          final email =
              ModalRoute.of(context)?.settings.arguments as String?;
          return ForgotPasswordScreen(prefillEmail: email);
        },
      },
    );
  }
}
