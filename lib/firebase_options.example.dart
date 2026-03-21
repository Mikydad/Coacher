import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Copy this file to `firebase_options.dart` and fill in values from Firebase
/// Console or from `GoogleService-Info.plist` after copying the example plist
/// to `ios/Runner/GoogleService-Info.plist`.
///
/// Command line: `dart run flutterfire configure`
class DefaultFirebaseOptions {
  const DefaultFirebaseOptions._();

  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for this platform yet.',
        );
    }
  }

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'REPLACE_WITH_FIREBASE_IOS_API_KEY',
    appId: 'REPLACE_WITH_FIREBASE_IOS_APP_ID',
    messagingSenderId: 'REPLACE_WITH_FIREBASE_MESSAGING_SENDER_ID',
    projectId: 'REPLACE_WITH_FIREBASE_PROJECT_ID',
    storageBucket: 'REPLACE_WITH_FIREBASE_STORAGE_BUCKET',
    iosBundleId: 'com.example.coachForLife',
  );
}
