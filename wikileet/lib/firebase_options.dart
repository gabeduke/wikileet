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
    apiKey: 'AIzaSyClJTARxa_PGC5JYgwtacYDzhk04g8C_eU',
    appId: '1:179879905839:web:4247bf5eb572e5147994da',
    messagingSenderId: '179879905839',
    projectId: 'wikileet',
    authDomain: 'wikileet.firebaseapp.com',
    databaseURL: 'https://wikileet.firebaseio.com',
    storageBucket: 'wikileet.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCuOimnxozeN25MG5qNZxmDhr4nTg8qIVI',
    appId: '1:179879905839:android:c1345a524a981ca67994da',
    messagingSenderId: '179879905839',
    projectId: 'wikileet',
    databaseURL: 'https://wikileet.firebaseio.com',
    storageBucket: 'wikileet.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBkyYy7Z6sDyZjgQuWBU7tApgwH7AW42nM',
    appId: '1:179879905839:ios:1addae05a98cc37c7994da',
    messagingSenderId: '179879905839',
    projectId: 'wikileet',
    databaseURL: 'https://wikileet.firebaseio.com',
    storageBucket: 'wikileet.appspot.com',
    iosClientId:
        '179879905839-p56trdr0cd1n97dku471l2k51qvirod0.apps.googleusercontent.com',
    iosBundleId: 'com.example.wikileet',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBkyYy7Z6sDyZjgQuWBU7tApgwH7AW42nM',
    appId: '1:179879905839:ios:1addae05a98cc37c7994da',
    messagingSenderId: '179879905839',
    projectId: 'wikileet',
    databaseURL: 'https://wikileet.firebaseio.com',
    storageBucket: 'wikileet.appspot.com',
    iosClientId:
        '179879905839-p56trdr0cd1n97dku471l2k51qvirod0.apps.googleusercontent.com',
    iosBundleId: 'com.example.wikileet',
  );
}
