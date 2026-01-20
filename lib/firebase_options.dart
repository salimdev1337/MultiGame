import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
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
        return windows;
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
    apiKey: "AIzaSyDoMDTGfuFiHGMzr5BSai61RxQlbJ6zeVk",
    authDomain: "multigame-54c9b.firebaseapp.com",
    projectId: "multigame-54c9b",
    storageBucket: "multigame-54c9b.firebasestorage.app",
    messagingSenderId: "780046114067",
    appId: "1:780046114067:web:f0d2bc07ad6f956d76cee6",
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBoNph_meOLqaRCZCVZwkJJpdy5nKo6jO0',
    appId: '1:780046114067:android:5bd1a4459b646acf76cee6',
    messagingSenderId: '780046114067',
    projectId: 'multigame-54c9b',
    storageBucket: 'multigame-54c9b.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBoNph_meOLqaRCZCVZwkJJpdy5nKo6jO0',
    appId: '1:780046114067:ios:placeholder76cee6',
    messagingSenderId: '780046114067',
    projectId: 'multigame-54c9b',
    storageBucket: 'multigame-54c9b.firebasestorage.app',
    iosBundleId: 'com.example.multigame',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBoNph_meOLqaRCZCVZwkJJpdy5nKo6jO0',
    appId: '1:780046114067:ios:placeholder76cee6',
    messagingSenderId: '780046114067',
    projectId: 'multigame-54c9b',
    storageBucket: 'multigame-54c9b.firebasestorage.app',
    iosBundleId: 'com.example.multigame',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: "AIzaSyDoMDTGfuFiHGMzr5BSai61RxQlbJ6zeVk",
    appId: "1:780046114067:web:f0d2bc07ad6f956d76cee6",
    messagingSenderId: "780046114067",
    projectId: "multigame-54c9b",
    authDomain: "multigame-54c9b.firebaseapp.com",
    storageBucket: "multigame-54c9b.firebasestorage.app",
  );
}
