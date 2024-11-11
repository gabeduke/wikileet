// lib/view_models/family_view_model.dart

import 'package:flutter/material.dart';
import 'package:wikileet/services/family_service.dart';

class FamilyViewModel with ChangeNotifier {
  final FamilyService _familyService = FamilyService();
  String? familyId;
  List<String> familyMembers = [];

  // Load the family ID for the user by email
  Future<void> loadFamilyForUser(String email) async {
    familyId = await _familyService.getFamilyIdForUser(email);
    if (familyId != null) {
      await loadFamilyMembers();
    }
    notifyListeners();
  }

  // Load family members for the current family
  Future<void> loadFamilyMembers() async {
    if (familyId != null) {
      familyMembers = await _familyService.getFamilyMembers(familyId!);
      notifyListeners();
    }
  }
}
