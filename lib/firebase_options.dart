import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform => android;

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: "AIzaSyA3hFTY6-BiuZeAqQMi-4fR9ZRaaKG-EzQ",
    appId: "1:825803543303:android:6a8140bcaed452f2b0eba2",
    messagingSenderId: "825803543303",
    projectId: "tabunganku-a6c40",
    storageBucket: "tabunganku-a6c40.firebasestorage.app",
  );
}
