// lib/services/user_service.dart

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

  Future<void> updateUserProfile(String userId, Map<String, dynamic> updates) async {
    await _firestore.collection('users').doc(userId).update(updates);
  }

  Future<void> addUserIfNotExist(auth.User firebaseUser) async {
    final userDocRef = _firestore.collection('users').doc(firebaseUser.uid);

    // Force a fresh read from Firestore
    final userDoc = await userDocRef.get(GetOptions(source: Source.server));

    if (!userDoc.exists) {
      // Prepare data for new user
      final userData = {
        'uid': firebaseUser.uid,
        'displayName': firebaseUser.displayName ?? firebaseUser.email?.split('@').first ?? 'Unknown',
        'email': firebaseUser.email ?? 'unknown@example.com',
        'familyGroupId': null,
        'profilePicUrl': firebaseUser.photoURL,
      };

      print("Creating new user in Firestore with data: $userData");

      // Write user data to Firestore
      await userDocRef.set(userData);
      print("New user added to Firestore: ${firebaseUser.email}");
    } else {
      print("User already exists in Firestore: ${firebaseUser.email}");
    }
  }


  Future<User?> getUserProfile(String userId) async {
    // Return cached user if available
    if (_cachedUser != null && _cachedUser!.uid == userId) {
      print('Returning cached user profile for UID: $userId');
      return _cachedUser;
    }

    // Prevent concurrent fetches
    if (_isFetchingProfile) {
      print('Already fetching profile for UID: $userId. Returning null.');
      return null;
    }

    _isFetchingProfile = true;
    try {
      print('Attempting to fetch user profile for UID: $userId');
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (userDoc.exists) {
        print('User profile found in Firestore for UID: $userId');
        _cachedUser = User.fromJson(userDoc); // Cache the result
        return _cachedUser;
      } else {
        print('User not found in Firestore: $userId');
        return null;
      }
    } catch (e) {
      print('Failed to get user profile: $e');
      throw Exception('Failed to get user profile: $e');
    } finally {
      _isFetchingProfile = false; // Reset fetching state
    }
  }


  Future<void> addUser(User user) async {
    await _firestore.collection('users').doc(user.uid).set(user.toJson());
  }

  Future<User?> getUser(String uid) async {
    final docSnapshot = await _firestore.collection('users').doc(uid).get();
    if (docSnapshot.exists) {
      return User.fromJson(docSnapshot);
    }
    return null;
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(uid).update(data);
  }

  Future<void> deleteUser(String uid) async {
    await _firestore.collection('users').doc(uid).delete();
  }

  // Optional method for authenticated user retrieval, not needed for Firestore tests
  auth.User? getCurrentUser() {
    return _auth?.currentUser;
  }
}
