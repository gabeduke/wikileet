import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  @override
  void initState() {
    super.initState();
    _initiateSignInSilently();
  }

  // Automatically try to sign in the user silently if they're already authenticated
  Future<void> _initiateSignInSilently() async {
    try {
      final googleUser = await _googleSignIn.signInSilently();
      if (googleUser != null) {
        print("Silent sign-in successful: ${googleUser.email}");
        _authenticateWithFirebase(googleUser);
      }
    } catch (e) {
      print("Silent sign-in error: $e");
    }
  }

  // Authenticate with Firebase
  Future<void> _authenticateWithFirebase(GoogleSignInAccount googleUser) async {
    try {
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
    } catch (e) {
      print("Firebase authentication error: $e");
    }
  }

  // Render Google Sign-In Button
  Widget _buildGoogleSignInButton() {
    return ElevatedButton(
      onPressed: () async {
        try {
          final googleUser = await _googleSignIn.signIn();
          if (googleUser != null) {
            _authenticateWithFirebase(googleUser);
          }
        } catch (e) {
          print("Google sign-in error: $e");
        }
      },
      child: Text("Sign in with Google"),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Login")),
      body: Center(
        child: _buildGoogleSignInButton(),
      ),
    );
  }
}
