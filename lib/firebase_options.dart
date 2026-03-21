import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

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
    apiKey: 'AIzaSyAmvl1srjITFrVJW4f7xuyXtODktw6MYyw',
    appId: '1:8992228827:ios:a09bd6e079e5b33e9553fe',
    messagingSenderId: '8992228827',
    projectId: 'coach4life-afaaa',
    storageBucket: 'coach4life-afaaa.firebasestorage.app',
    iosBundleId: 'com.example.coachForLife',
  );
}
