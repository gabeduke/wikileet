import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import '../models/user.dart' as app_user;

class UserProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _userId;
  String? _familyGroupId;
  String? _houseId;
  Map<String, app_user.User> _userCache = {};
  bool _isInitialized = false;
  
  String? get userId => _userId;
  String? get familyGroupId => _familyGroupId;
  String? get houseId => _houseId;
  bool get isInitialized => _isInitialized;

  // Add user cache getter
  Map<String, app_user.User> get userCache => _userCache;

  // Fetch and cache user data
  Future<app_user.User?> getUserData(String userId) async {
    // Check cache first
    if (_userCache.containsKey(userId)) {
      return _userCache[userId];
    }

    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists && doc.data() != null) {
        final user = app_user.User.fromJson(doc);
        _userCache[userId] = user; // Cache the user data
        
        // Update local state
        _familyGroupId = user.familyGroupId;
        _houseId = user.houseId;
        _isInitialized = true;
        
        notifyListeners();
        return user;
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching user data: $e');
      return null;
    }
  }

  // Get user stream for real-time updates
  Stream<app_user.User?> getUserStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) {
          if (!doc.exists || doc.data() == null) return null;
          final user = app_user.User.fromJson(doc);
          _userCache[userId] = user; // Update cache
          
          // Update local state
          _familyGroupId = user.familyGroupId;
          _houseId = user.houseId;
          _isInitialized = true;
          
          notifyListeners();
          return user;
        });
  }

  // Fetch multiple users at once
  Future<void> fetchUsers(List<String> userIds) async {
    try {
      final futures = userIds.map((id) => getUserData(id));
      await Future.wait(futures);
    } catch (e) {
      debugPrint('Error fetching multiple users: $e');
    }
  }

  // Clear cache when logging out
  void clearCache() {
    _userCache.clear();
    notifyListeners();
  }

  // Existing methods
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
    // This will trigger the auth state change in the Wrapper
    await auth.FirebaseAuth.instance.signOut();
  }
}
