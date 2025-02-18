import 'package:flutter/material.dart';

class GoogleSignInButtonWrapper extends StatefulWidget {
  final Future<void> Function() onSignIn;

  const GoogleSignInButtonWrapper({super.key, required this.onSignIn});

  @override
  _GoogleSignInButtonWrapperState createState() => _GoogleSignInButtonWrapperState();
}

class _GoogleSignInButtonWrapperState extends State<GoogleSignInButtonWrapper> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: _isProcessing
          ? null
          : () async {
        setState(() {
          _isProcessing = true;
        });
        try {
          await widget.onSignIn();
        } catch (e) {
          print("Error during Google Sign-In: $e");
        } finally {
          if (mounted) {
            setState(() {
              _isProcessing = false;
            });
          }
        }
      },
      child: _isProcessing ? const CircularProgressIndicator() : const Text("Sign in with Google"),
    );
  }
}
