import 'dart:async';

import 'package:flutter/material.dart';
import 'package:wikileet/models/family_group.dart';
import 'package:wikileet/models/user.dart';
import 'package:wikileet/services/family_service.dart';
import 'package:wikileet/services/user_service.dart';

import '../models/house.dart';

class FamilyViewModel with ChangeNotifier {
  final FamilyService _familyService = FamilyService();
  final UserService _userService = UserService();

  String? familyId;
  String? houseId;
  List<User> familyMembers = [];
  List<User> houseMembers = [];
  List<FamilyGroup> familyGroups = [];
  bool isLoading = false;
  String? errorMessage;
  bool _isDataLoaded = false;

  StreamSubscription<FamilyGroup?>? _familyGroupSubscription;
  StreamSubscription<List<House>>? _housesSubscription;

  /// Subscribe to family group updates
  void _subscribeToFamilyGroup() {
    if (familyId == null) return;

    _familyGroupSubscription?.cancel(); // Cancel any existing subscription
    _familyGroupSubscription = _familyService.subscribeToFamilyGroup(familyId!).listen((familyGroup) {
      if (familyGroup != null) {
        familyGroups = [familyGroup];
        _subscribeToHouses(); // Fetch houses for this family group
        notifyListeners();
      }
    });
  }

  /// Subscribe to house updates
  void _subscribeToHouses() {
    if (familyId == null) return;

    _housesSubscription?.cancel(); // Cancel any existing subscription
    _housesSubscription = _familyService.subscribeToHouses(familyId!).listen((houses) {
      if (familyGroups.isNotEmpty) {
        familyGroups[0].houses = houses;
        notifyListeners();
      }
    });
  }

  /// Check if the user is a global admin
  Future<bool> checkAdminAuthorization(String userId) async {
    return await _userService.isGlobalAdmin(userId);
  }

  /// Load family and house information for the current user if not already loaded
  Future<void> loadFamilyForUser(String userId) async {
    if (_isDataLoaded) return; // Prevent redundant loads
    _setLoading(true);

    try {
      final user = await _userService.getUserProfile(userId);
      if (user == null) return; // Handle missing user profile

      familyId = user.familyGroupId;
      houseId = user.houseId;

      if (familyId != null) familyMembers = await _loadFamilyMembers();
      if (houseId != null) houseMembers = await _loadHouseMembers();

      _isDataLoaded = true;
    } catch (e) {
      errorMessage = 'Failed to load family data: $e';
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  /// Select a family group and optionally a house, updating Firestore
  Future<void> selectFamilyAndHouse(
      String familyGroupId, String? houseId, String userId) async {
    _setLoading(true);
    try {
      await _familyService.setFamilyAndHouseForUser(
          familyGroupId, houseId, userId);

      // Update in-memory family and house IDs
      familyId = familyGroupId;
      this.houseId = houseId;

      familyMembers = await _loadFamilyMembers();
      if (houseId != null) houseMembers = await _loadHouseMembers();
      notifyListeners();
    } catch (e) {
      errorMessage = 'Failed to select family and house: $e';
    } finally {
      _setLoading(false);
    }
  }

  /// Load all members of the family group
  Future<List<User>> _loadFamilyMembers() async {
    if (familyId == null) return [];
    try {
      final memberIds = await _familyService.getFamilyMembers(familyId!);
      return await _fetchUsersByIds(memberIds);
    } catch (e) {
      errorMessage = 'Failed to load family members: $e';
      return [];
    }
  }

  /// Load all members of the specified house
  Future<List<User>> _loadHouseMembers() async {
    if (familyId == null || houseId == null) return [];
    try {
      final memberIds =
          await _familyService.getHouseMembers(familyId!, houseId!);
      return await _fetchUsersByIds(memberIds);
    } catch (e) {
      errorMessage = 'Failed to load house members: $e';
      return [];
    }
  }

  /// Helper to fetch user profiles by a list of user IDs
  Future<List<User>> _fetchUsersByIds(List<String> userIds) async {
    return await Future.wait(userIds.map((id) async {
      return await _userService.getUserProfile(id) ??
          User(uid: id, displayName: "Unknown", email: "", familyGroupId: '');
    }));
  }

  /// Add a member to the family group and reload the list of family members
  Future<void> addMemberToFamily(String familyGroupId, String userId) async {
    await _familyService.addMemberToFamilyGroup(familyGroupId, userId);
    familyMembers = await _loadFamilyMembers();
    notifyListeners();
  }

  /// Add a member to the house and reload the list of house members
  Future<void> addMemberToHouse(
      String familyGroupId, String houseId, String userId) async {
    await _familyService.addMemberToHouse(familyGroupId, houseId, userId);
    houseMembers = await _loadHouseMembers();
    notifyListeners();
  }

  /// Retrieve all family groups, including houses, if not already loaded
  Future<void> getUserFamilyGroup(String userId) async {
    _setLoading(true);

    try {
      // Subscribe to real-time user profile updates
      subscribeToUser(userId);

      // Fetch the user's profile to get familyGroupId and houseId
      final user = await _userService.getUserProfile(userId);
      familyId = user?.familyGroupId;
      houseId = user?.houseId;

      if (familyId != null) {
        // Fetch the family group
        final familyGroup = await _familyService.getFamilyGroupById(familyId!);

        // Fetch the houses for this family group
        final houses = await _familyService.getHousesForFamilyGroup(familyId!);

        // For each house, fetch its members and map user profiles to the house
        for (var house in houses) {
          house.members = await Future.wait(house.memberIds.map((memberId) async {
            final member = await _userService.getUserProfile(memberId);
            return member?.displayName ?? 'Unknown User';
          }).toList());
        }

        // Assign houses with user details back to the family group
        familyGroup.houses = houses;
        familyGroups = [familyGroup]; // Replace with the single family group for the user
      } else {
        familyGroups = []; // If the user is not part of any family group
      }
      notifyListeners(); // Trigger UI update
    } catch (e) {
      errorMessage = 'Failed to load family group: $e';
      print(errorMessage);
    } finally {
      _setLoading(false);
    }
  }


  Future<void> getFamilyGroups() async {
    if (isLoading) return; // Prevent concurrent calls

    _setLoading(true);
    try {
      familyGroups = await _familyService.getAllFamilyGroups();
      for (FamilyGroup family in familyGroups) {
        family.houses = await _familyService.getHousesForFamilyGroup(family.id);
      }
    } catch (e) {
      errorMessage = 'Failed to load family groups: $e';
    } finally {
      _setLoading(false);
    }
  }

  /// Delete a family group by its ID and refresh family groups list
  Future<void> deleteFamilyGroup(String familyGroupId) async {
    await _familyService.deleteFamilyGroup(familyGroupId);
    await getFamilyGroups();
    notifyListeners();
  }

  /// Add a new family group and refresh family groups list
  Future<void> addFamilyGroup(String name) async {
    await _familyService.addFamilyGroup(name);
    await getFamilyGroups();
    notifyListeners();
  }

  /// Add a new house to a family group and refresh the houses for that group
  Future<void> addHouse(String familyGroupId, String name) async {
    await _familyService.addHouse(familyGroupId, name);
    final family = familyGroups.firstWhere((group) => group.id == familyGroupId,
        orElse: () => FamilyGroup(
            id: familyGroupId,
            name: name,
            members: [],
            houseIds: [],
            houses: []));
    family.houses = await _familyService.getHousesForFamilyGroup(familyGroupId);
    notifyListeners();
  }

  /// Delete a house from a family group and refresh the houses for that group
  Future<void> deleteHouse(String familyGroupId, String houseId) async {
    await _familyService.deleteHouse(familyGroupId, houseId);
    final family =
        familyGroups.firstWhere((group) => group.id == familyGroupId);
    family.houses = await _familyService.getHousesForFamilyGroup(familyGroupId);
    notifyListeners();
  }

  /// Update the name of a house and refresh the houses for the family group
  Future<void> updateHouse(
      String familyGroupId, String houseId, String newName) async {
    await _familyService.updateHouseName(familyGroupId, houseId, newName);
    final family =
        familyGroups.firstWhere((group) => group.id == familyGroupId);
    family.houses = await _familyService.getHousesForFamilyGroup(familyGroupId);
    notifyListeners();
  }

  /// Reset data to allow reloading if needed
  void resetData() {
    _isDataLoaded = false;
    familyGroups.clear();
    houseMembers.clear();
    notifyListeners();
  }

  /// Set loading state and notify listeners
  void _setLoading(bool value) {
    isLoading = value;
    Future.microtask(() => notifyListeners());
  }

  String? getUserIdByUsername(String username) {
    try {
      final user = familyMembers.firstWhere(
            (user) => user.displayName == username,
      );
      return user.uid; // Safely return the UID if found
    } catch (e) {
      return null; // Return null if no user is found
    }
  }

  /// Listen to user profile updates and react to family changes
  void subscribeToUser(String userId) {
    _familyService.subscribeToUserProfile(userId).listen((userData) {
      final updatedFamilyGroupId = userData['familyGroupId'];
      final updatedHouseId = userData['houseId'];

      // If the family ID changes, reload the family group
      if (updatedFamilyGroupId != familyId) {
        familyId = updatedFamilyGroupId;
        _subscribeToFamilyGroup();
      }

      // If the house ID changes, reload the house members
      if (updatedHouseId != houseId) {
        houseId = updatedHouseId;
        _loadHouseMembers();
      }
    });
  }
}
