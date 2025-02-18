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
        print('Wrapper: Auth state: ${snapshot.connectionState}, hasData: ${snapshot.hasData}');
        
        if (snapshot.connectionState == ConnectionState.waiting) {
          print('Wrapper: Auth state is waiting');
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;
        if (user == null) {
          print('Wrapper: No authenticated user found');
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

        print('Wrapper: User authenticated with ID: ${user.uid}');
        
        final familyGroupProvider = Provider.of<FamilyGroupProvider>(context);
        final userProvider = Provider.of<UserProvider>(context);
        final familyViewModel = Provider.of<FamilyViewModel>(context, listen: false);
        
        // Initialize providers if needed
        if (!familyGroupProvider.isInitialized) {
          print('Wrapper: Initializing family group provider');
          familyGroupProvider.initializeStream(user.uid);
        }

        // Show loading while providers are initializing or we're waiting for initial user data
        if (familyGroupProvider.isLoading || !userProvider.isInitialized) {
          print('Wrapper: Still loading... FGP loading: ${familyGroupProvider.isLoading}, UP initialized: ${userProvider.isInitialized}');
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Check if user has a family group
        final hasFamilyGroup = userProvider.familyGroupId != null;
        print('Wrapper: User familyGroupId: ${userProvider.familyGroupId}');

        if (hasFamilyGroup) {
          print('Wrapper: User has family group, initializing FamilyViewModel');
          // Initialize FamilyViewModel when user has a family group
          familyViewModel.getUserFamilyGroup(user.uid);
        }

        if (!hasFamilyGroup) {
          print('Wrapper: User has no family group, showing NoFamilyGroupScreen');
          return const NoFamilyGroupScreen();
        }

        print('Wrapper: User has family group, showing main navigation');
        return const MainNavigationScreen();
      },
    );
  }
}
