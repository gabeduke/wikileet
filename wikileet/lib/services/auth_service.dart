import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:wikileet/services/user_service.dart';
import '../providers/user_provider.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);
  final UserService _userService = UserService();

  // Sign-in with Google, set userId in UserProvider, and return the authenticated user
  Future<User?> signInWithGoogle(UserProvider userProvider) async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // User canceled sign-in

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        // Ensure user exists in Firestore
        await _userService.addUserIfNotExist(user);

        // Directly set the userId in UserProvider
        userProvider.setUserId(user.uid);
      }

      return user;
    } catch (e) {
      print("Google sign-in error: $e");
      rethrow;
    }
  }

  // Sign out from Firebase and Google
  Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
  }
}
