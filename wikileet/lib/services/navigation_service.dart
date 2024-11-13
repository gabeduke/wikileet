// lib/services/navigation_service.dart

import 'package:flutter/material.dart';
import 'package:wikileet/services/user_service.dart';
import '../main.dart'; // Import the file where navigatorKey is defined
import '../screens/family_selection_screen.dart';
import '../screens/main_navigation_screen.dart';

class NavigationService {
  final UserService _userService = UserService();

  Future<void> checkFamilyGroupAndNavigate(String userId) async {
    print("Entered checkFamilyGroupAndNavigate");

    final userDoc = await _userService.getUserProfile(userId);
    if (userDoc == null) {
      print("User document is null for ID: $userId");
    } else {
      print("User document found for ID: $userId");
      print("User familyGroupId: ${userDoc.familyGroupId}");
      print("User houseId: ${userDoc.houseId}");
    }

    if (userDoc == null || userDoc.familyGroupId == null || userDoc.houseId == null) {
      print("Navigating to FamilySelectionScreen due to missing family or house info.");
      navigatorKey.currentState?.pushReplacement(
        MaterialPageRoute(builder: (context) => FamilySelectionScreen(userId: userId)),
      );
    } else {
      print("Navigating to MainNavigationScreen.");
      navigatorKey.currentState?.pushReplacement(
        MaterialPageRoute(builder: (context) => MainNavigationScreen()),
      );
    }
  }
}
