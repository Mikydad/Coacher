/// How account deletion must re-authenticate before `User.delete()`
/// (pre-launch audit H13).
///
/// Firebase rejects `delete()` with `requires-recent-login` unless the
/// session is fresh, and the only in-flow way to freshen it is a
/// provider-appropriate re-authentication. Apple additionally REQUIRES the
/// authorization to be revoked on deletion, which needs a fresh Apple
/// authorization code — so Apple users always go through the native sheet.
enum DeletionReauth {
  /// Email + password dialog (existing flow).
  password,

  /// Native Sign in with Apple sheet → reauth → revoke authorization.
  apple,

  /// Google account picker → reauth.
  google,

  /// Anonymous / unknown provider: nothing to re-prove.
  none,
}

/// Picks the strategy from `User.providerData` provider ids. Apple wins
/// when present (revocation is mandatory), then Google, then password.
DeletionReauth deletionReauthFor(Iterable<String> providerIds) {
  final ids = providerIds.toSet();
  if (ids.contains('apple.com')) return DeletionReauth.apple;
  if (ids.contains('google.com')) return DeletionReauth.google;
  if (ids.contains('password')) return DeletionReauth.password;
  return DeletionReauth.none;
}
