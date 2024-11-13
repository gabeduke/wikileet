import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'package:wikileet/services/auth_service.dart';
import 'package:wikileet/services/user_service.dart';
import '../widgets/google_signin_button_wrapper.dart';
import 'family_selection_screen.dart';
import 'main_navigation_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    _initiateSignInSilently();
  }

  Future<void> _initiateSignInSilently() async {
    try {
      final googleUser = await _authService.signInSilently();

      if (googleUser == null) {
        print("Silent sign-in failed: No active session.");
        return;
      }

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        await _checkFamilyGroupAndNavigate(currentUser.uid);
      }
    } catch (e) {
      print("Silent sign-in error: $e");
    }
  }

  Future<void> _checkFamilyGroupAndNavigate(String userId) async {
    final userDoc = await _userService.getUserProfile(userId);

    if (!mounted) return;

    if (userDoc == null || userDoc.familyGroupId == null || userDoc.houseId == null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => FamilySelectionScreen(userId: userId)),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => MainNavigationScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Login")),
      body: Center(
        child: GoogleSignInButtonWrapper(
          onSignIn: _handleGoogleSignIn,
        ),
      ),
    );
  }

  Future<void> _handleGoogleSignIn() async {
    try {
      final user = await _authService.signInWithGoogle();
      if (user != null) {
        await _checkFamilyGroupAndNavigate(user.uid);
      }
    } catch (e) {
      print("Google sign-in error: $e");
    }
  }
}
