import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';

class UserProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _userId;
  String? _familyGroupId;
  String? _houseId;
  Map<String, User> _userCache = {};
  
  String? get userId => _userId;
  String? get familyGroupId => _familyGroupId;
  String? get houseId => _houseId;

  // Add user cache getter
  Map<String, User> get userCache => _userCache;

  // Fetch and cache user data
  Future<User?> getUserData(String userId) async {
    // Check cache first
    if (_userCache.containsKey(userId)) {
      return _userCache[userId];
    }

    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists && doc.data() != null) {
        final user = User.fromJson(doc);
        _userCache[userId] = user; // Cache the user data
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
  Stream<User?> getUserStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) {
          if (!doc.exists || doc.data() == null) return null;
          final user = User.fromJson(doc);
          _userCache[userId] = user; // Update cache
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
    getUserData(userId);
    notifyListeners();
  }

  void clearUserId() {
    _userId = null;
    notifyListeners();
  }
}
