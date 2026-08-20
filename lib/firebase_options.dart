import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Firebase options from dart-defines, with Android values baked from
/// `android/app/google-services.json` so release APKs get FCM without CI flags.
///
/// Override any platform with:
/// ```
/// flutter run --dart-define=FIREBASE_API_KEY=... --dart-define=FIREBASE_APP_ID=... \
///   --dart-define=FIREBASE_MESSAGING_SENDER_ID=... --dart-define=FIREBASE_PROJECT_ID=... \
///   --dart-define=FIREBASE_STORAGE_BUCKET=...
/// ```
class DefaultFirebaseOptions {
  static const apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const appId = String.fromEnvironment('FIREBASE_APP_ID');
  static const messagingSenderId =
      String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
  static const projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const storageBucket = String.fromEnvironment('FIREBASE_STORAGE_BUCKET');

  static const _androidApiKey = 'AIzaSyDdzFV9IlyJlKUHxWSw6IP0ixi9YE5ahag';
  static const _androidAppId = '1:1041974530298:android:19a08f42603cd160a4b943';
  static const _androidSenderId = '1041974530298';
  static const _androidProjectId = 'ekaadh-71c90';
  static const _androidBucket = 'ekaadh-71c90.firebasestorage.app';

  static bool get _definesComplete =>
      apiKey.isNotEmpty &&
      appId.isNotEmpty &&
      messagingSenderId.isNotEmpty &&
      projectId.isNotEmpty;

  static bool get isConfigured {
    if (_definesComplete) return true;
    return !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  }

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return android;
    }
  }

  static FirebaseOptions get android {
    if (_definesComplete) {
      return const FirebaseOptions(
        apiKey: apiKey,
        appId: appId,
        messagingSenderId: messagingSenderId,
        projectId: projectId,
        storageBucket: storageBucket,
      );
    }
    return const FirebaseOptions(
      apiKey: _androidApiKey,
      appId: _androidAppId,
      messagingSenderId: _androidSenderId,
      projectId: _androidProjectId,
      storageBucket: _androidBucket,
    );
  }

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: apiKey,
    appId: appId,
    messagingSenderId: messagingSenderId,
    projectId: projectId,
    storageBucket: storageBucket,
    iosBundleId: 'com.ekaadh.ekaadhMobile',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: apiKey,
    appId: appId,
    messagingSenderId: messagingSenderId,
    projectId: projectId,
    storageBucket: storageBucket,
  );
}
