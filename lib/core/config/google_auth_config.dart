/// Google Sign-In OAuth client IDs for Firebase Auth.
///
/// Do not commit real client IDs. Pass at build time:
/// ```bash
/// flutter run \
///   --dart-define=GOOGLE_IOS_CLIENT_ID=YOUR_IOS_CLIENT_ID.apps.googleusercontent.com \
///   --dart-define=GOOGLE_WEB_CLIENT_ID=YOUR_WEB_CLIENT_ID.apps.googleusercontent.com
/// ```
///
/// iOS client ID: `ios/Runner/GoogleService-Info.plist` → `CLIENT_ID`
/// Web client ID: Firebase Console → Authentication → Google → Web SDK configuration
abstract final class GoogleAuthConfig {
  static const String iosClientId = String.fromEnvironment(
    'GOOGLE_IOS_CLIENT_ID',
  );
  static const String webClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
  );

  static bool get hasIosClientId => iosClientId.trim().isNotEmpty;
  static bool get hasWebClientId => webClientId.trim().isNotEmpty;
}
