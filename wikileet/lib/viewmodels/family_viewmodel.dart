// lib/viewmodels/family_viewmodel.dart

import 'package:flutter/material.dart';
import 'package:wikileet/services/family_service.dart';
import 'package:wikileet/services/user_service.dart';
import 'package:wikileet/models/user.dart'; // Assuming a User model exists

class FamilyViewModel with ChangeNotifier {
  final FamilyService _familyService = FamilyService();
  final UserService _userService = UserService();

  String? familyId;
  List<User> familyMembers = [];
  bool isLoading = false;
  String? errorMessage; // To store error messages

  // Load the family ID for the user by email
  Future<void> loadFamilyForUser(String email) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      familyId = await _familyService.getFamilyIdForUser(email);
      if (familyId != null) {
        await loadFamilyMembers();
      } else {
        // No family ID found
        familyMembers = [];
      }
    } catch (e) {
      errorMessage = 'Failed to load family data.';
      print('Error in loadFamilyForUser: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Load family members with full profile details for the current family
  Future<void> loadFamilyMembers() async {
    try {
      if (familyId != null) {
        List<String> memberIds = await _familyService.getFamilyMembers(familyId!);
        familyMembers = await Future.wait(
          memberIds.map((id) async {
            try {
              return await _userService.getUserProfile(id) ??
                  User(uid: id, displayName: "Unknown", email: "");
            } catch (e) {
              print('Error fetching user profile for $id: $e');
              return User(uid: id, displayName: "Unknown", email: "");
            }
          }),
        );
      } else {
        familyMembers = [];
      }
    } catch (e) {
      errorMessage = 'Failed to load family members.';
      print('Error in loadFamilyMembers: $e');
    }
  }
}
