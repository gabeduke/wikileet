// lib/wrapper.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/login_screen.dart';
import 'screens/main_app_screen.dart';

class Wrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(), // Listen to auth state changes
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Show a loading spinner
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasData) {
          // User is signed in
          return MainAppScreen();
        } else {
          // User is not signed in
          return LoginScreen();
        }
      },
    );
  }
}
