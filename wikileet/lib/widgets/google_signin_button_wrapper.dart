// lib/widgets/google_sign_in_button_wrapper.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:io' show Platform;

class GoogleSignInButtonWrapper extends StatelessWidget {
  final Future<void> Function() onSignIn;

  GoogleSignInButtonWrapper({required this.onSignIn});

  @override
  Widget build(BuildContext context) {
    // Use a platform check to render appropriately for Web vs. other platforms
    if (kIsWeb) {
      // Web-specific button rendering using Google Identity Services
      return SizedBox(
        width: 200,
        height: 50,
        child: ElevatedButton(
          onPressed: onSignIn,
          child: Text("Sign in with Google"),
        ),
      );
    } else {
      // Default button for Android/iOS
      return ElevatedButton(
        onPressed: onSignIn,
        child: Text("Sign in with Google"),
      );
    }
  }
}
