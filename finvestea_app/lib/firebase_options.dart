// firebase_options.dart — removed (app is now fully frontend/local)
// firebase_options.dart
//
// Generated from android/app/google-services.json.
// For iOS: run `flutterfire configure` after adding GoogleService-Info.plist,
// then replace the ios FirebaseOptions block below.
//
// DO NOT commit real API keys to a public repo — use environment variables
// or Firebase App Check in production.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web. '
        'Run `flutterfire configure` to add web support.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        // TODO: Add GoogleService-Info.plist for iOS and replace these values
        // by running: flutterfire configure
        throw UnsupportedError(
          'iOS Firebase options are not configured yet. '
          'Add GoogleService-Info.plist and run `flutterfire configure`.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // ── Android ──────────────────────────────────────────────────────────────
  // Values extracted from android/app/google-services.json
  // Project: finvestea-app  |  Package: com.example.finvestea_app
  static const FirebaseOptions android = FirebaseOptions(
    // apiKey: 'AIzaSyCfBs82eCzjSc1II3Wi1bzySG8rPE1saYQ',
    apiKey: 'AIzaSyAwxNOwIJFSv2GaN9Q2cBmT-qaidFUXNCI',
    // appId: '1:370137706029:android:271531cdc47164c87292a4',
    appId: '1:1041825244657:android:5e9e1a7a4dcbb2d5d61050',
    // messagingSenderId: '370137706029',
    messagingSenderId: '1041825244657',
    // projectId: 'finvestea-app',
    projectId: 'finvesteatask',
    // storageBucket: 'finvestea-app.firebasestorage.app',
    storageBucket: 'finvesteatask.firebasestorage.app',
  );
}
