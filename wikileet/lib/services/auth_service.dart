// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  // Sign in with Google
  Future<auth.UserCredential?> signInWithGoogle() async {
    try {
      print("Starting Google Sign-In...");
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) {
        print("Google Sign-In canceled by user.");
        return null;
      }

      print("Google Sign-In successful: ${googleUser.email}");
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      print("Signing into Firebase with Google credentials...");
      return await auth.FirebaseAuth.instance.signInWithCredential(credential);
    } catch (e) {
      print("Google Sign-In error: $e");
      return null;
    }
  }

// Other authentication methods can be added here
}
