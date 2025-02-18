// lib/wrapper.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:wikileet/providers/user_provider.dart';
import 'package:wikileet/providers/family_group_provider.dart';  // Added missing import
import 'package:wikileet/services/auth_service.dart';
import 'package:wikileet/models/user.dart' as app_user;
import 'package:wikileet/viewmodels/family_viewmodel.dart';
import 'screens/login_screen.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/no_family_group_screen.dart';

class Wrapper extends StatelessWidget {
  const Wrapper({super.key});

  @override
  Widget build(BuildContext context) {
    print('Wrapper build called');
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        print('Auth state: ${snapshot.connectionState}, hasData: ${snapshot.hasData}');
        
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;
        if (user == null) {
          return LoginScreen(
            onSignIn: () async {
              try {
                await AuthService().signInWithGoogle(
                  Provider.of<UserProvider>(context, listen: false),
                );
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Failed to sign in: $e")),
                  );
                }
              }
            },
          );
        }

        print('User authenticated, checking family group');
        
        // Initialize and listen to family group provider
        final familyGroupProvider = Provider.of<FamilyGroupProvider>(context);
        
        // Initialize stream if needed
        if (!familyGroupProvider.isInitialized) {
          familyGroupProvider.initializeStream(user.uid);
        }

        // Show loading state while initializing or loading
        if (familyGroupProvider.isLoading) {
          print('FamilyGroupProvider is loading');
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // If initialized but no data, show no family group screen
        if (familyGroupProvider.isInitialized && !familyGroupProvider.hasData) {
          print('No family group data found');
          return const NoFamilyGroupScreen();
        }

        // We have data, show main navigation
        print('Family group data found, showing main navigation');
        return const MainNavigationScreen();
      },
    );
  }
}
