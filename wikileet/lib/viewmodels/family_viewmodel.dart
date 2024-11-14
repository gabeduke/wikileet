// lib/viewmodels/family_viewmodel.dart

import 'package:flutter/material.dart';
import 'package:wikileet/services/family_service.dart';
import 'package:wikileet/services/user_service.dart';
import 'package:wikileet/models/user.dart';

import '../models/family_group.dart';
import '../models/family_member.dart';
import '../models/house.dart'; // Assuming a User model exists

class FamilyViewModel with ChangeNotifier {
  final FamilyService _familyService = FamilyService();
  final UserService _userService = UserService();

  String? familyId;
  String? houseId;
  List<User> familyMembers = [];
  List<User> houseMembers = [];
  bool isLoading = false;
  String? errorMessage;
  String? currentUserId;

  Future<void> loadFamilyForUser(String userId) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final user = await _userService.getUserProfile(userId);
      familyId = user?.familyGroupId;
      houseId = user?.houseId;

      if (familyId != null) {
        await loadFamilyMembers();
      } else {
        familyMembers = [];
      }

      if (houseId != null) {
        await loadHouseMembers();
      } else {
        houseMembers = [];
      }
    } catch (e) {
      errorMessage = 'Failed to load family data.';
      print('Error in loadFamilyForUser: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadFamilyMembers() async {
    try {
      if (familyId != null) {
        List<String> memberIds = await _familyService.getFamilyMembers(familyId!);
        familyMembers = await Future.wait(
          memberIds.map((id) async => await _userService.getUserProfile(id) ?? User(uid: id, displayName: "Unknown", email: "")),
        );
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
        List<String> memberIds = await _familyService.getHouseMembers(familyId!, houseId!);
        houseMembers = await Future.wait(
          memberIds.map((id) async => await _userService.getUserProfile(id) ?? User(uid: id, displayName: "Unknown", email: "")),
        );
      } else {
        houseMembers = [];
      }
    } catch (e) {
      errorMessage = 'Failed to load house members.';
      print('Error in loadHouseMembers: $e');
    }
  }

  Future<List<FamilyGroup>> getFamilyGroups() async {
    return await _familyService.getAllFamilyGroups();
  }

  Future<List<House>> getHouses(String id) async {
    return await _familyService.getHousesForFamilyGroup(id);
  }

  void updateHouse(String id, String id2, String newName) async {
    await _familyService.addMemberToHouse(id, id2, newName);
    loadHouseMembers();
  }

  deleteHouse(String id, String id2) async {
    await _familyService.addMemberToHouse(id, id2, "");
    loadHouseMembers();
  }

  void addHouse(String id, String name) async {
    await _familyService.addHouse(id, name);
    loadHouseMembers();
}

  void updateMember(String id, String id2, String newName) async {
    await _familyService.addMemberToHouse(id, id2, newName);
    loadHouseMembers();
  }

  deleteMember(String id, String id2) async {
    await _familyService.addMemberToHouse(id, id2, "");
    loadHouseMembers();
  }

  void addMember(String id, String name) async {
    await _familyService.addMemberToFamilyGroup(id, name);
    loadHouseMembers();
  }

  void addFamilyGroup(String name) async {
    await _familyService.addFamilyGroup(name);
    notifyListeners();
  }

}
