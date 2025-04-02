// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for ios - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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
    apiKey: 'AIzaSyAi-sZCFQWMR0k1tT4Z2Y_WaW2fWtvpR_s',
    appId: '1:606642618462:web:775a687fda4c615dc9f4cf',
    messagingSenderId: '606642618462',
    projectId: 'gachon-noti-v2-fc11a',
    authDomain: 'gachon-noti-v2-fc11a.firebaseapp.com',
    storageBucket: 'gachon-noti-v2-fc11a.firebasestorage.app',
    measurementId: 'G-ST627Z69RV',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCB5Vgg7EPI3cCuADXGVtCTCV3q7HBn-8c',
    appId: '1:606642618462:android:3892b2a51aa35ffdc9f4cf',
    messagingSenderId: '606642618462',
    projectId: 'gachon-noti-v2-fc11a',
    storageBucket: 'gachon-noti-v2-fc11a.firebasestorage.app',
  );
}
