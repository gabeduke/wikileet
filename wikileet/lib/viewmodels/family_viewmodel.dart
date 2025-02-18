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
  StreamSubscription? _userSubscription;

  bool get isInitialized => _isDataLoaded && !isLoading;

  @override
  void dispose() {
    _familyGroupSubscription?.cancel();
    _housesSubscription?.cancel();
    _userSubscription?.cancel();
    super.dispose();
  }

  /// Initialize the view model with user data and start subscriptions
  Future<void> getUserFamilyGroup(String userId) async {
    print('Initializing FamilyViewModel for user: $userId');
    _setLoading(true);

    try {
      // First get initial data
      final user = await _userService.getUserProfile(userId);
      print('Initial user profile fetched: ${user?.familyGroupId}');
      
      if (user != null) {
        familyId = user.familyGroupId;
        houseId = user.houseId;

        // If user has a family group, load initial data
        if (familyId != null) {
          await _loadInitialFamilyData();
        } else {
          familyGroups = [];
        }

        // Start subscriptions after initial data is loaded
        _startSubscriptions(userId);
      }
      
      _isDataLoaded = true;
      notifyListeners();
    } catch (e, stackTrace) {
      print('Error in getUserFamilyGroup: $e');
      print('Stack trace: $stackTrace');
      errorMessage = 'Failed to initialize family data: $e';
      _isDataLoaded = false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _loadInitialFamilyData() async {
    print('Loading initial family data for familyId: $familyId');
    if (familyId == null) return;

    try {
      final familyGroup = await _familyService.getFamilyGroupById(familyId!);
      final houses = await _familyService.getHousesForFamilyGroup(familyId!);
      
      // Load house members in parallel
      await Future.wait(houses.map((house) async {
        house.members = await Future.wait(house.memberIds.map((memberId) async {
          final member = await _userService.getUserProfile(memberId);
          return member?.displayName ?? 'Unknown User';
        }));
      }));

      familyGroup.houses = houses;
      familyGroups = [familyGroup];
      print('Initial family data loaded successfully');
    } catch (e) {
      print('Error loading initial family data: $e');
      throw e;
    }
  }

  void _startSubscriptions(String userId) {
    print('Starting real-time subscriptions');
    
    // Subscribe to user profile changes
    _userSubscription?.cancel();
    _userSubscription = _familyService.subscribeToUserProfile(userId).listen(
      (userData) {
        print('User profile update received: $userData');
        final updatedFamilyGroupId = userData['familyGroupId'];
        final updatedHouseId = userData['houseId'];

        if (updatedFamilyGroupId != familyId) {
          familyId = updatedFamilyGroupId;
          _subscribeToFamilyGroup();
        }
        if (updatedHouseId != houseId) {
          houseId = updatedHouseId;
          _loadHouseMembers();
        }
      },
      onError: (e) => print('Error in user subscription: $e'),
    );

    // Start family group subscription if we have a familyId
    if (familyId != null) {
      _subscribeToFamilyGroup();
    }
  }

  /// Subscribe to family group updates
  void _subscribeToFamilyGroup() {
    print('_subscribeToFamilyGroup called, familyId: $familyId');
    if (familyId == null) return;

    _familyGroupSubscription?.cancel(); // Cancel any existing subscription
    print('Subscribing to family group: $familyId');
    _familyGroupSubscription = _familyService.subscribeToFamilyGroup(familyId!).listen((familyGroup) {
      print('Family group update received: ${familyGroup?.name}');
      if (familyGroup != null) {
        familyGroups = [familyGroup];
        _subscribeToHouses(); // Fetch houses for this family group
        notifyListeners();
      }
    });
  }

  /// Subscribe to house updates
  void _subscribeToHouses() {
    print('_subscribeToHouses called, familyId: $familyId');
    if (familyId == null) return;

    _housesSubscription?.cancel(); // Cancel any existing subscription
    print('Subscribing to houses for family: $familyId');
    _housesSubscription = _familyService.subscribeToHouses(familyId!).listen((houses) {
      print('Houses update received, count: ${houses.length}');
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
    print('Setting loading state to: $value');
    isLoading = value;
    notifyListeners();
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
}
