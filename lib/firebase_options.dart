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
    apiKey: 'AIzaSyDy-_2nBFwd153-X8twivQZr0r7z8mEYJI',
    appId: '1:1097541906584:web:8df6c40546db1e034a60ed',
    messagingSenderId: '1097541906584',
    projectId: 'artspace-free',
    authDomain: 'artspace-free.firebaseapp.com',
    storageBucket: 'artspace-free.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBIoxJPiQNwYH7hBtkbdqMi5G9iqDu3hr4',
    appId: '1:1097541906584:android:842cfa5e0ea558814a60ed',
    messagingSenderId: '1097541906584',
    projectId: 'artspace-free',
    storageBucket: 'artspace-free.firebasestorage.app',
  );
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCdRmwBKv59OIUafq0VhSV9p-o1pefalQI',
    appId: '1:1097541906584:ios:562498eac7bb4e644a60ed',
    messagingSenderId: '1097541906584',
    projectId: 'artspace-free',
    storageBucket: 'artspace-free.firebasestorage.app',
    iosBundleId: 'com.example.newFlutter',
  );
  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCdRmwBKv59OIUafq0VhSV9p-o1pefalQI',
    appId: '1:1097541906584:ios:562498eac7bb4e644a60ed',
    messagingSenderId: '1097541906584',
    projectId: 'artspace-free',
    storageBucket: 'artspace-free.firebasestorage.app',
    iosBundleId: 'com.example.newFlutter',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDy-_2nBFwd153-X8twivQZr0r7z8mEYJI',
    appId: '1:1097541906584:web:6359557a139a4d624a60ed',
    messagingSenderId: '1097541906584',
    projectId: 'artspace-free',
    authDomain: 'artspace-free.firebaseapp.com',
    storageBucket: 'artspace-free.firebasestorage.app',
  );
}
