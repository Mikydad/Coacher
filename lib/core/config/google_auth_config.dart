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
      '8992228827-cvai3u73029u2blkno7rg15268q13ocm.apps.googleusercontent.com';

  /// Set via `--dart-define` or replace for local runs without dart-define.
  static const String webClientIdDefault =
      '8992228827-o88ai8r7ercn3fitbq60tpplajl537d2.apps.googleusercontent.com';

  static const String webClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue: webClientIdDefault,
  );

  static bool get hasWebClientId => webClientId.trim().isNotEmpty;
}
