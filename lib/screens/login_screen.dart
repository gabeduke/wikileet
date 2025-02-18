import 'package:flutter/material.dart';
import '../widgets/google_signin_button_wrapper.dart';

class LoginScreen extends StatefulWidget {
  final Future<void> Function() onSignIn;

  const LoginScreen({super.key, required this.onSignIn});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isSigningIn = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login")),
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
    if (_isSigningIn) return;

    setState(() {
      _isSigningIn = true;
    });

    try {
      await widget.onSignIn();
      print("Google Sign-In successful.");
    } catch (e) {
      print("Google sign-in error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error during sign-in: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSigningIn = false;
        });
      }
    }
  }
}
