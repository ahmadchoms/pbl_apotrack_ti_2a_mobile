import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform => android;

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: "AIzaSyD1rN-YgLx4cp5uiIvVXDR-95Mv54RDmZo",
    appId: "1:184964236996:android:32dd77aa33228c2e62ab91",
    messagingSenderId: "184964236996",
    projectId: "apotrack-e1f7a",
    storageBucket: "apotrack-e1f7a.firebasestorage.app",
    // apiKey: String.fromEnvironment('FIREBASE_API_KEY'),
    // appId: String.fromEnvironment('FIREBASE_APP_ID'),
    // messagingSenderId: String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID'),
    // projectId: String.fromEnvironment('FIREBASE_PROJECT_ID'),
    // storageBucket: String.fromEnvironment('FIREBASE_STORAGE_BUCKET'),
  );
}
