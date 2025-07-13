import 'package:flutter/foundation.dart';
import 'dart:async';
import '../models/family_group.dart';
import '../services/family_service.dart';

class FamilyGroupProvider with ChangeNotifier {
  final FamilyService _familyService;
  StreamSubscription? _userSubscription;
  StreamSubscription? _familySubscription;
  List<FamilyGroup> _groups = [];
  String? _userId;
  bool _isInitialized = false;
  bool _isLoading = false;

  FamilyGroupProvider({FamilyService? familyService}) 
    : _familyService = familyService ?? FamilyService();

  List<FamilyGroup> get groups => _groups;
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  bool get hasData => _groups.isNotEmpty;

  void initializeStream(String userId) {
    print('FamilyGroupProvider: Initializing stream for user: $userId');
    if (_userId == userId && _isInitialized) {
      print('FamilyGroupProvider: Stream already initialized for this user');
      return;
    }

    _cleanup();
    _userId = userId;
    _setLoading(true);

    try {
      print('FamilyGroupProvider: Setting up streams for user: $userId');

      // Listen to user profile updates
      _userSubscription = _familyService.subscribeToUserProfile(userId).listen((userData) {
        final familyGroupId = userData['familyGroupId'] as String?;
        
        print('FamilyGroupProvider: User familyGroupId: $familyGroupId');
        
        if (familyGroupId == null) {
          print('FamilyGroupProvider: User has no family group assignment');
          _groups = [];
          _setLoading(false);
          if (!_isInitialized) {
            _isInitialized = true;
          }
          notifyListeners();
          return;
        }

        // Cancel existing family subscription if any
        _familySubscription?.cancel();

        // Subscribe to family group updates
        _familySubscription = _familyService.subscribeToFamilyGroup(familyGroupId).listen((familyGroup) {
          if (familyGroup == null) {
            print('FamilyGroupProvider: Family group $familyGroupId not found');
            _groups = [];
          } else {
            print('FamilyGroupProvider: Processing family group ${familyGroup.id}');
            // Subscribe to houses for this family group
            _familyService.subscribeToHouses(familyGroupId).listen((houses) {
              familyGroup.houses = houses;
              _groups = [familyGroup];
              _setLoading(false);
              if (!_isInitialized) {
                _isInitialized = true;
              }
              notifyListeners();
            });
          }
        });
      });
    } catch (e) {
      print('FamilyGroupProvider: Error initializing streams: $e');
      _setLoading(false);
      _isInitialized = false;
    }
  }

  void _cleanup() {
    _userSubscription?.cancel();
    _familySubscription?.cancel();
    _userSubscription = null;
    _familySubscription = null;
    _groups = [];
  }

  void _setLoading(bool value) {
    if (_isLoading != value) {
      _isLoading = value;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _cleanup();
    super.dispose();
  }

  Future<void> createFamilyGroup(String name, String creatorId) async {
    try {
      await _familyService.addFamilyGroup(name);
    } catch (e) {
      print('FamilyGroupProvider: Error creating family group: $e');
      rethrow;
    }
  }

  Future<void> joinFamilyGroup(String groupId, String userId) async {
    try {
      await _familyService.addMemberToFamilyGroup(groupId, userId);
    } catch (e) {
      print('FamilyGroupProvider: Error joining family group: $e');
      rethrow;
    }
  }

  Future<void> removeMember(String groupId, String userId) async {
    try {
      await _familyService.removeMemberFromFamilyGroup(groupId, userId);
    } catch (e) {
      print('FamilyGroupProvider: Error removing member: $e');
      rethrow;
    }
  }

  Future<void> updateFamilyGroup(String groupId, Map<String, dynamic> updates) async {
    try {
      final familyGroup = await _familyService.getFamilyGroupById(groupId);
      // Apply updates to family group using service methods as needed
      if (updates.containsKey('name')) {
        // Add appropriate service methods for other update types
        throw UnimplementedError('Update operations not yet implemented in FamilyService');
      }
    } catch (e) {
      print('FamilyGroupProvider: Error updating family group: $e');
      rethrow;
    }
  }
}
