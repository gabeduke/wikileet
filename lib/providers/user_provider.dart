import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import '../models/user.dart' as app_user;
import '../services/user_service.dart';

class UserProvider with ChangeNotifier {
  final UserService _userService;
  String? _userId;
  String? _familyGroupId;
  String? _houseId;
  Map<String, app_user.User> _userCache = {};
  bool _isInitialized = false;

  UserProvider({UserService? userService}) 
    : _userService = userService ?? UserService();
  
  String? get userId => _userId;
  String? get familyGroupId => _familyGroupId;
  String? get houseId => _houseId;
  bool get isInitialized => _isInitialized;
  Map<String, app_user.User> get userCache => _userCache;

  Future<app_user.User?> getUserData(String userId) async {
    // Check cache first
    if (_userCache.containsKey(userId)) {
      return _userCache[userId];
    }

    try {
      final user = await _userService.getUserProfile(userId);
      if (user != null) {
        _userCache[userId] = user;
        
        // Update local state if this is the current user
        if (userId == _userId) {
          _familyGroupId = user.familyGroupId;
          _houseId = user.houseId;
          _isInitialized = true;
        }
        
        notifyListeners();
      }
      return user;
    } catch (e) {
      debugPrint('Error fetching user data: $e');
      return null;
    }
  }

  Stream<app_user.User?> getUserStream(String userId) {
    return _userService.getUserStream(userId)
      ..listen((user) {
        if (user != null) {
          _userCache[userId] = user;
          
          if (userId == _userId) {
            _familyGroupId = user.familyGroupId;
            _houseId = user.houseId;
            _isInitialized = true;
          }
          
          notifyListeners();
        }
      });
  }

  Future<void> fetchUsers(List<String> userIds) async {
    try {
      final users = await _userService.getMultipleUsers(userIds);
      for (final user in users) {
        _userCache[user.uid] = user;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching multiple users: $e');
    }
  }

  void clearCache() {
    _userCache.clear();
    notifyListeners();
  }

  void setHouseId(String houseId) {
    _houseId = houseId;
    notifyListeners();
  }

  void clearHouseId() {
    _houseId = null;
    notifyListeners();
  }

  void setFamilyGroupId(String familyGroupId) {
    _familyGroupId = familyGroupId;
    notifyListeners();
  }

  void clearFamilyGroupId() {
    _familyGroupId = null;
    notifyListeners();
  }

  void setUserId(String userId) {
    _userId = userId;
    // Fetch current user's data when setting ID
    getUserData(userId).then((_) {
      _isInitialized = true;
      notifyListeners();
    });
  }

  void clearUserId() {
    _userId = null;
    _isInitialized = false;
    notifyListeners();
  }

  Future<void> signOut() async {
    clearCache();
    clearUserId();
    clearFamilyGroupId();
    clearHouseId();
    _isInitialized = false;
    await auth.FirebaseAuth.instance.signOut();
  }
}
