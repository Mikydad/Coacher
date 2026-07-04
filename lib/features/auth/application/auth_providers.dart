import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_repository.dart';
import 'auth_repository_interface.dart';

/// The single [AuthRepository] instance for the app.
///
/// Typed as [AuthRepositoryInterface] so tests can inject lightweight fakes
/// without needing a real [FirebaseAuth] instance.
final authRepositoryProvider = Provider<AuthRepositoryInterface>(
  (_) => AuthRepository(),
);

/// Streams the current Firebase [User] (or `null` when signed out).
///
/// Watch this in [AuthGate] and any widget that needs to react to auth changes.
final authStateProvider = StreamProvider<User?>(
  (ref) => ref.read(authRepositoryProvider).authStateChanges(),
);

/// Set to `true` by an explicit user-initiated sign-out so that [AuthGate]
/// shows the [AuthLandingScreen] (Sign in / Create account / Continue as guest)
/// instead of silently re-creating an anonymous session.
///
/// In-memory only — resets to `false` on app restart and whenever a user signs
/// back in, so first-launch guest behaviour is preserved.
final pendingAuthLandingProvider = StateProvider<bool>((ref) => false);

/// The signed-in uid, or `null` when signed out.
///
/// User-scoped providers should `ref.watch` this so they rebuild (and drop
/// cached values) on logout / account switch instead of relying solely on
/// the manual invalidation list in `user_scoped_invalidation.dart`.
final authUidProvider = Provider<String?>((ref) {
  // VM unit tests run without Firebase; touching authStateProvider there
  // would throw [core/no-app] from FirebaseAuth.instance.
  if (Firebase.apps.isEmpty) return null;
  return ref.watch(authStateProvider).valueOrNull?.uid;
});

/// Convenience: `true` when a user is signed in (anonymous or registered).
final isSignedInProvider = Provider<bool>(
  (ref) => ref.watch(authStateProvider).valueOrNull != null,
);

/// Convenience: `true` only when signed in **and** not anonymous.
final isRegisteredProvider = Provider<bool>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  return user != null && !user.isAnonymous;
});
