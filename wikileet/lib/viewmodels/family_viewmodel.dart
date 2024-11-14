// lib/viewmodels/family_viewmodel.dart

import 'package:flutter/material.dart';
import 'package:wikileet/models/family_group.dart';
import 'package:wikileet/services/family_service.dart';
import 'package:wikileet/services/user_service.dart';
import 'package:wikileet/models/user.dart';

import '../models/house.dart';

class FamilyViewModel with ChangeNotifier {
  final FamilyService _familyService = FamilyService();
  final UserService _userService = UserService();

  String? familyId;
  String? houseId;
  List<User> familyMembers = [];
  List<User> houseMembers = [];
  bool isLoading = false;
  String? errorMessage;

  // Admin authorization check (placeholder, implement actual logic)
  Future<bool> checkAdminAuthorization() async {
    // Replace with actual authorization check, e.g., verify user role
    return true; // Allow access for testing
  }

  Future<void> loadFamilyForUser(String userId) async {
    print('Loading family for user: $userId');
    _setLoading(true);

    try {
      final user = await _userService.getUserProfile(userId);
      familyId = user?.familyGroupId;
      houseId = user?.houseId;

      // Load members based on availability of familyId and houseId
      await Future.wait([
        if (familyId != null) loadFamilyMembers(),
        if (houseId != null) loadHouseMembers(),
      ]);

      print('Family ID: $familyId, House ID: $houseId');
    } catch (e) {
      errorMessage = 'Failed to load family data.';
      print('Error in loadFamilyForUser: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadFamilyMembers() async {
    try {
      if (familyId != null) {
        final memberIds = await _familyService.getFamilyMembers(familyId!);
        familyMembers = await _fetchUsersByIds(memberIds);
      } else {
        familyMembers = [];
      }
    } catch (e) {
      errorMessage = 'Failed to load family members.';
      print('Error in loadFamilyMembers: $e');
    }
  }

  Future<void> loadHouseMembers() async {
    try {
      if (houseId != null && familyId != null) {
        final memberIds = await _familyService.getHouseMembers(familyId!, houseId!);
        houseMembers = await _fetchUsersByIds(memberIds);
      } else {
        houseMembers = [];
      }
    } catch (e) {
      errorMessage = 'Failed to load house members.';
      print('Error in loadHouseMembers: $e');
    }
  }

  Future<List<User>> _fetchUsersByIds(List<String> userIds) async {
    return await Future.wait(userIds.map((id) async {
      return await _userService.getUserProfile(id) ?? User(uid: id, displayName: "Unknown", email: "");
    }));
  }

  Future<void> addMemberToFamily(String familyGroupId, String userId) async {
    await _familyService.addMemberToFamilyGroup(familyGroupId, userId);
    await loadFamilyMembers();
    notifyListeners();
  }

  Future<void> addMemberToHouse(String familyGroupId, String houseId, String userId) async {
    await _familyService.addMemberToHouse(familyGroupId, houseId, userId);
    await loadHouseMembers();
    notifyListeners();
  }

  void _setLoading(bool value) {
    isLoading = value;
    notifyListeners();
  }

  Future<List<FamilyGroup>> getFamilyGroups() async {
    return await _familyService.getAllFamilyGroups();
  }

  Future<List<House>> getHouses(String familyGroupId) async {
    return await _familyService.getHousesForFamilyGroup(familyGroupId);
  }

  Future<void> deleteFamilyGroup(String familyGroupId) async {
    await _familyService.deleteFamilyGroup(familyGroupId);
    notifyListeners();
  }

  Future<void> addFamilyGroup(String name) async {
    await _familyService.addFamilyGroup(name);
    notifyListeners();
  }

  Future<void> addHouse(String familyGroupId, String name) async {
    await _familyService.addHouse(familyGroupId, name);
    notifyListeners();
  }

  Future<void> deleteHouse(String familyGroupId, String houseId) async {
    await _familyService.deleteHouse(familyGroupId, houseId);
    notifyListeners();
  }

  Future<void> updateHouse(String familyGroupId, String houseId, String newName) async {
    await _familyService.updateHouseName(familyGroupId, houseId, newName);
    notifyListeners();
  }
}
