import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:wikileet/services/user_service.dart';
import '../providers/user_provider.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);
  final UserService _userService = UserService();

  static bool _isGoogleSignInInitialized = false; // Initialization guard

  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Ensure GoogleSignIn is initialized once
  Future<void> _initializeGoogleSignIn() async {
    if (_isGoogleSignInInitialized) {
      print("GoogleSignIn already initialized.");
      return;
    }

    try {
      // Attempt silent sign-in to initialize GoogleSignIn
      await _googleSignIn.signInSilently();
      _isGoogleSignInInitialized = true;
      print("GoogleSignIn initialized successfully.");
    } catch (e) {
      print("Error initializing GoogleSignIn: $e");
    }
  }

  // Listen to auth state changes and update UserProvider accordingly
  void listenToAuthChanges(UserProvider userProvider) {
    _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        userProvider.setUserId(user.uid);
      } else {
        userProvider.clearUserId();
      }
    });
  }

  // Sign-in with Google, set userId in UserProvider, and return the authenticated user
  Future<User?> signInWithGoogle(UserProvider userProvider) async {
    await _initializeGoogleSignIn(); // Ensure initialization before sign-in

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
  Future<void> signOut(UserProvider userProvider) async {
    await _auth.signOut();
    await _googleSignIn.signOut();
  }
}
