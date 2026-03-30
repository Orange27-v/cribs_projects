// File generated based on the Firebase configuration files
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyC4xgutAJjv9z8vw4ZHRsqx2pvvMQxa_oE',
    appId: '1:599897304581:web:c8498c2515632cbacc7f6c',
    messagingSenderId: '599897304581',
    projectId: 'cribsarenaapps',
    authDomain: 'cribsarenaapps.firebaseapp.com',
    storageBucket: 'cribsarenaapps.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC4xgutAJjv9z8vw4ZHRsqx2pvvMQxa_oE',
    appId: '1:599897304581:android:19334de5cfc451f3ae366c',
    messagingSenderId: '599897304581',
    projectId: 'cribsarenaapps',
    storageBucket: 'cribsarenaapps.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyC24eneN9abtRjzOX1WiQBfCMNDkUSGXok',
    appId: '1:599897304581:ios:8a741b6befbe16edae366c',
    messagingSenderId: '599897304581',
    projectId: 'cribsarenaapps',
    storageBucket: 'cribsarenaapps.appspot.com',
    iosBundleId: 'com.cribsarena.cribsarena',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyC24eneN9abtRjzOX1WiQBfCMNDkUSGXok',
    appId: '1:599897304581:ios:8a741b6befbe16edae366c',
    messagingSenderId: '599897304581',
    projectId: 'cribsarenaapps',
    storageBucket: 'cribsarenaapps.appspot.com',
    iosBundleId: 'com.cribsarena.cribsarena',
  );
}
