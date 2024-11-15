// lib/services/navigation_service.dart

import 'package:flutter/material.dart';
import 'package:wikileet/providers/user_provider.dart';
import 'package:wikileet/services/user_service.dart';
import '../main.dart';
import '../screens/family_selection_screen.dart';
import '../screens/main_navigation_screen.dart';

class NavigationService {
  final UserService _userService = UserService();
  bool _isNavigating = false;

  Future<void> checkFamilyGroupAndNavigate(String userId) async {
    if (_isNavigating) {
      print("Navigation already in progress, skipping...");
      return;
    }
    _isNavigating = true;
    print("Entered checkFamilyGroupAndNavigate");

    try {
      final userDoc = await _userService.getUserProfile(userId);
      if (userDoc == null ||
          userDoc.familyGroupId == null ||
          userDoc.houseId == null) {
        print(
            "Navigating to FamilySelectionScreen due to missing family or house info.");
        navigatorKey.currentState?.pushReplacement(
          MaterialPageRoute(
              builder: (context) => FamilySelectionScreen(userId: userId)),
        );
      } else {
        print("Navigating to MainNavigationScreen.");
        navigatorKey.currentState?.pushReplacement(
          MaterialPageRoute(builder: (context) => MainNavigationScreen()),
        );
      }
    } finally {
      _isNavigating = false;
    }
  }

  void listenToAuthChanges(UserProvider userProvider) {
    userProvider.addListener(() {
      if (userProvider.userId != null) {
        checkFamilyGroupAndNavigate(userProvider.userId!);
      }
    });
  }
}
