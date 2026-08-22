/// Typed failures returned by [AuthRepository].
///
/// Use [AuthFailureX.toUserMessage] to convert to a displayable string.
sealed class AuthFailure {
  const AuthFailure();
}

/// No network / Firebase connection.
class NetworkFailure extends AuthFailure {
  const NetworkFailure();
}

/// Email/password combination did not match any account.
class InvalidCredentials extends AuthFailure {
  const InvalidCredentials();
}

/// The email address is already registered to another account.
class EmailAlreadyInUse extends AuthFailure {
  const EmailAlreadyInUse();
}

/// The password does not meet the minimum strength requirement.
class WeakPassword extends AuthFailure {
  const WeakPassword();
}

/// The operation requires a recent sign-in; the user must re-authenticate.
class RequiresRecentLogin extends AuthFailure {
  const RequiresRecentLogin();
}

/// User closed the sign-in sheet (Google, etc.) — not an error.
class AuthSignInCanceled extends AuthFailure {
  const AuthSignInCanceled();
}

/// Linking the anonymous account failed because the chosen Google/Apple
/// identity already belongs to an existing PathPal account (typically a
/// previous install or another device). The credential is cached in the
/// repository — [AuthRepositoryInterface.signInWithPendingLinkConflict]
/// switches to that account (the recovery path this failure exists for).
class CredentialAlreadyLinked extends AuthFailure {
  const CredentialAlreadyLinked({this.email, this.providerLabel});

  /// Email of the already-linked identity, when the provider reports it.
  final String? email;

  /// Human label for the provider ('Google' / 'Apple').
  final String? providerLabel;
}

/// An unexpected Firebase Auth error occurred.
class UnknownAuthFailure extends AuthFailure {
  const UnknownAuthFailure(this.message);
  final String message;
}

// ── User-readable strings ─────────────────────────────────────────────────────

extension AuthFailureX on AuthFailure {
  String toUserMessage() => switch (this) {
    InvalidCredentials() =>
      "That email or password doesn't match. Try again or reset your password.",
    EmailAlreadyInUse() =>
      'An account with this email already exists. Sign in instead.',
    WeakPassword() => 'Password must be at least 8 characters.',
    NetworkFailure() =>
      'No internet connection. Check your network and try again.',
    RequiresRecentLogin() => 'Please sign in again before making this change.',
    AuthSignInCanceled() => '',
    CredentialAlreadyLinked(:final providerLabel) =>
      'This ${providerLabel ?? 'sign-in'} account is already connected to an '
          'existing PathPal account.',
    UnknownAuthFailure(:final message) =>
      message.isEmpty ? 'Something went wrong. Please try again.' : message,
  };
}
