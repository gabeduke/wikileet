// lib/wrapper.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:wikileet/providers/user_provider.dart';
import 'package:wikileet/services/auth_service.dart';
import 'screens/login_screen.dart';
import 'screens/main_navigation_screen.dart';

class Wrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasData) {
          return MainNavigationScreen();
        } else {
          return LoginScreen(
            onSignIn: () async {
              try {
                // Ensure sign-in logic is executed safely
                await AuthService().signInWithGoogle(Provider.of<UserProvider>(context, listen: false));
              } catch (e) {
                print("Error in Wrapper Sign-In: $e");
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Failed to sign in: $e")),
                );
              }
            },
          );
        }
      },
    );
  }
}
