import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/session/session_scope.dart';
import '../domain/auth_failure.dart';
import 'auth_providers.dart';
import 'auth_repository_interface.dart';
import 'auth_session_policy.dart';
import 'user_scoped_invalidation.dart';

/// Account deletion as ONE sequence whose lifetime is independent of the
/// settings screen (pre-launch audit H14).
///
/// The old path was: `delete()` → `if (!mounted) return` → wipe. AuthGate
/// unmounts the settings screen the moment auth turns null, so the wipe
/// could be skipped entirely, no provider was reset, and (guest policy)
/// AuthGate could start an anonymous session while the old data was still
/// on disk. This coordinator owns the order:
///
///  1. landing barrier — AuthGate shows the landing screen, never a silent
///     guest re-sign-in, once auth turns null;
///  2. session teardown begins (generation bump + provider reset) so no
///     in-flight job can persist after this point;
///  3. device transports are released WHILE STILL AUTHENTICATED — the push
///     token doc lives under the user's tree and the delete is rejected
///     once the Auth user is gone (the audit found the orphaned token still
///     fed the morning-brief cron);
///  4. the Auth user is deleted (the caller has already re-authenticated);
///  5. the local session is cleared unconditionally — no `mounted` guard.
///
/// On a delete failure the barrier is lifted and the session resumes; the
/// invalidated providers simply reload from the intact local data.
abstract final class AccountDeletionCoordinator {
  static Future<AuthFailure?> run({
    required AuthRepositoryInterface auth,
    ProviderContainer? container,
    Future<void> Function()? releaseTransports,
    Future<void> Function()? clearLocalSession,
  }) async {
    container?.read(pendingAuthLandingProvider.notifier).state = true;
    if (container != null) {
      invalidateUserScopedProvidersIn(container);
    } else {
      SessionScope.beginTeardown();
    }
    try {
      await (releaseTransports ?? AuthSessionPolicy.releaseDeviceTransports)();
    } catch (e) {
      debugPrint('[AccountDeletion] transport release failed: $e');
    }

    final failure = await auth.deleteAccount();
    if (failure != null) {
      SessionScope.endTeardown();
      container?.read(pendingAuthLandingProvider.notifier).state = false;
      return failure;
    }

    await (clearLocalSession ??
        () => AuthSessionPolicy.clearLocalSession(
          transportsAlreadyReleased: true,
        ))();
    return null;
  }
}
