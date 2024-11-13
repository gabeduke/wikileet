// login_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wikileet/services/auth_service.dart';
import 'package:wikileet/viewmodels/family_viewmodel.dart';
import '../widgets/google_signin_button_wrapper.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Login")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GoogleSignInButtonWrapper(
              onSignIn: _handleGoogleSignIn,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleGoogleSignIn() async {
    print("Attempting Google Sign-In...");
    try {
      final user = await _authService.signInWithGoogle();
      if (user != null) {
        print("Google Sign-In successful, UID: ${user.uid}");

        if (mounted) {
          // Set `currentUserId` in `FamilyViewModel`
          Provider.of<FamilyViewModel>(context, listen: false).currentUserId = user.uid;
        }
      } else {
        print("Google Sign-In failed or canceled.");
      }
    } catch (e) {
      print("Google sign-in error: $e");
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}
