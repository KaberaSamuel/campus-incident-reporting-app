// Run `dart pub global activate flutterfire_cli` then `flutterfire configure`
// to replace this file with your Firebase project values.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Campus Incidents is Android only.');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'Campus Incidents is Android only.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'REPLACE_ME_RUN_FLUTTERFIRE_CONFIGURE',
    appId: '1:000000000000:android:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'campus-incidents-dev',
    storageBucket: 'campus-incidents-dev.firebasestorage.app',
  );
}
