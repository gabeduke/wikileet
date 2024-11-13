// login_screen.dart
import 'package:flutter/material.dart';
import 'package:wikileet/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _initiateSignInSilently();
  }

  Future<void> _initiateSignInSilently() async {
    try {
      await _authService.signInSilently();
    } catch (e) {
      print("Silent sign-in error: $e");
    }
  }

  Widget _buildGoogleSignInButton() {
    return ElevatedButton(
      onPressed: () async {
        try {
          await _authService.signInWithGoogle();
        } catch (e) {
          print("Google sign-in error: $e");
          // Show error to user
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
