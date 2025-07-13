// lib/wrapper.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:wikileet/providers/user_provider.dart';
import 'package:wikileet/providers/family_group_provider.dart';  // Added missing import
import 'package:wikileet/services/auth_service.dart';
import 'package:wikileet/viewmodels/family_viewmodel.dart';
import 'screens/login_screen.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/no_family_group_screen.dart';

class Wrapper extends StatefulWidget {
  const Wrapper({super.key});

  @override
  State<Wrapper> createState() => _WrapperState();
}

class _WrapperState extends State<Wrapper> {
  String? _lastUserId;
  String? _lastFamilyGroupId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
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

        // Only proceed if the user ID changed
        if (_lastUserId != user.uid) {
          _lastUserId = user.uid;
          final familyGroupProvider = Provider.of<FamilyGroupProvider>(context, listen: false);
          final userProvider = Provider.of<UserProvider>(context, listen: false);
          
          // Initialize providers only if needed
          if (!familyGroupProvider.isInitialized) {
            familyGroupProvider.initializeStream(user.uid);
          }
        }
        
        final userProvider = Provider.of<UserProvider>(context);
        final familyGroupProvider = Provider.of<FamilyGroupProvider>(context);

        // Show loading while providers are initializing
        if (familyGroupProvider.isLoading || !userProvider.isInitialized) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final hasFamilyGroup = userProvider.familyGroupId != null;

        // Only initialize FamilyViewModel if family group changed
        if (hasFamilyGroup && _lastFamilyGroupId != userProvider.familyGroupId) {
          _lastFamilyGroupId = userProvider.familyGroupId;
          Provider.of<FamilyViewModel>(context, listen: false)
              .getUserFamilyGroup(user.uid);
        }

        if (!hasFamilyGroup) {
          return const NoFamilyGroupScreen();
        }

        return const MainNavigationScreen();
      },
    );
  }
}
