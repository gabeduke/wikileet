// lib/widgets/google_sign_in_button_wrapper.dart

import 'package:flutter/material.dart';

class GoogleSignInButtonWrapper extends StatelessWidget {
  final Future<void> Function() onSignIn;

  GoogleSignInButtonWrapper({required this.onSignIn});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        print("Google Sign-In button was pressed."); // Log the button press
        onSignIn();
      },
      child: Text("Sign in with Google"),
    );
  }
}
