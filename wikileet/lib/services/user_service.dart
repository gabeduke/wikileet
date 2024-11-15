import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:wikileet/models/user.dart';

class UserService {
  final FirebaseFirestore _firestore;
  final auth.FirebaseAuth? _auth;
  User? _cachedUser; // Cache the user to prevent duplicate calls
  bool _isFetchingProfile = false; // Prevent concurrent fetches

  UserService({FirebaseFirestore? firestore, auth.FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth;

  /// Check if a user is a global admin by their user ID
  Future<bool> isGlobalAdmin(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data();
      return userData?['isGlobalAdmin'] ?? false;
    } catch (e) {
      print("Error checking isGlobalAdmin for userId $userId: $e");
      return false;
    }
  }

  /// Update user profile fields by providing a user ID and a map of updates
  Future<void> updateUserProfile(
      String userId, Map<String, dynamic> updates) async {
    await _firestore.collection('users').doc(userId).update(updates);
  }

  /// Add a new user to Firestore if they do not already exist
  Future<void> addUserIfNotExist(auth.User firebaseUser) async {
    final userDocRef = _firestore.collection('users').doc(firebaseUser.uid);

    // Force a fresh read from Firestore
    final userDoc = await userDocRef.get(GetOptions(source: Source.server));

    if (!userDoc.exists) {
      final userData = {
        'uid': firebaseUser.uid,
        'displayName': firebaseUser.displayName ??
            firebaseUser.email?.split('@').first ??
            'Unknown',
        'email': firebaseUser.email ?? 'unknown@example.com',
        'familyGroupId': null,
        'houseId': null,
        'profilePicUrl': firebaseUser.photoURL,
      };

      await userDocRef.set(userData);
      print("New user added to Firestore: ${firebaseUser.email}");
    } else {
      print("User already exists in Firestore: ${firebaseUser.email}");
    }
  }

  /// Fetch a user profile by their user ID
  Future<User?> getUserProfile(String userId) async {
    if (_cachedUser != null && _cachedUser!.uid == userId) {
      return _cachedUser; // Return cached user if available
    }

    if (_isFetchingProfile) {
      return null; // Prevent concurrent fetches
    }

    _isFetchingProfile = true;
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (userDoc.exists) {
        _cachedUser = User.fromJson(userDoc); // Cache the result
        return _cachedUser;
      }
      return null;
    } catch (e) {
      print('Failed to get user profile: $e');
      throw Exception('Failed to get user profile: $e');
    } finally {
      _isFetchingProfile = false;
    }
  }

  /// Add a user to Firestore
  Future<void> addUser(User user) async {
    await _firestore.collection('users').doc(user.uid).set(user.toJson());
  }

  /// Get a user document by their UID
  Future<User?> getUser(String uid) async {
    final docSnapshot = await _firestore.collection('users').doc(uid).get();
    if (docSnapshot.exists) {
      return User.fromJson(docSnapshot);
    }
    return null;
  }

  /// Update user fields in Firestore by their UID
  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(uid).update(data);
  }

  /// Delete a user from Firestore by their UID
  Future<void> deleteUser(String uid) async {
    await _firestore.collection('users').doc(uid).delete();
  }

  /// Get the current authenticated user (optional method)
  auth.User? getCurrentUser() {
    return _auth?.currentUser;
  }
}
