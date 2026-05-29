/// Google Sign-In OAuth client IDs for Firebase Auth.
///
/// **Web client ID** (required for Firebase to verify Google id tokens on mobile):
/// Firebase Console → Authentication → Sign-in method → Google → expand
/// "Web SDK configuration" and copy the Web client ID.
///
/// Pass at build time:
/// `flutter run --dart-define=GOOGLE_WEB_CLIENT_ID=8992228827-xxxx.apps.googleusercontent.com`
///
/// Or replace [webClientIdDefault] below for local dev.
abstract final class GoogleAuthConfig {
  /// iOS OAuth client from `ios/Runner/GoogleService-Info.plist` → `CLIENT_ID`.
  static const String iosClientId =
      'REPLACE_WITH_IOS_OAUTH_CLIENT_ID';

  /// Set via `--dart-define` or replace for local runs without dart-define.
  static const String webClientIdDefault =
      'REPLACE_WITH_WEB_OAUTH_CLIENT_ID';

  static const String webClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue: webClientIdDefault,
  );

  static bool get hasWebClientId => webClientId.trim().isNotEmpty;
}
