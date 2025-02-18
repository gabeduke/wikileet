import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:wikileet/models/user.dart' as app_user;

class UserService {
  final FirebaseFirestore _firestore;
  final auth.FirebaseAuth? _auth;
  app_user.User? _cachedUser;
  bool _isAddingUser = false;

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
    if (_isAddingUser) {
      print("Skipping duplicate addUserIfNotExist call for UID: ${firebaseUser.uid}");
      return;
    }
    _isAddingUser = true;
    
    try {
      final userDocRef = _firestore.collection('users').doc(firebaseUser.uid);
      final userDoc = await userDocRef.get(const GetOptions(source: Source.server));
      
      if (!userDoc.exists) {
        final userData = {
          'uid': firebaseUser.uid,
          'displayName': firebaseUser.displayName ?? 
              firebaseUser.email?.split('@').first ?? 
              'Unknown',
          'email': firebaseUser.email ?? 'unknown@example.com',
          'familyGroupId': null,  // Initialize as null, user will join/create group later
          'houseId': null,
          'profilePicUrl': firebaseUser.photoURL,
          'createdAt': FieldValue.serverTimestamp(),
        };
        await userDocRef.set(userData);
        print("New user added to Firestore: ${firebaseUser.email}");
      } else {
        // Update existing user's display name and photo if they've changed
        final currentData = userDoc.data() as Map<String, dynamic>;
        if (currentData['displayName'] != firebaseUser.displayName || 
            currentData['profilePicUrl'] != firebaseUser.photoURL) {
          await userDocRef.update({
            'displayName': firebaseUser.displayName,
            'profilePicUrl': firebaseUser.photoURL,
            'lastUpdated': FieldValue.serverTimestamp(),
          });
        }
      }
    } catch (e) {
      print("Error adding user to Firestore: $e");
      rethrow;
    } finally {
      _isAddingUser = false;
    }
  }

  /// Fetch a user profile by their user ID
  Future<app_user.User?> getUserProfile(String userId) async {
    print('Fetching user profile for: $userId');
    if (_cachedUser != null && _cachedUser!.uid == userId) {
      print('Returning cached user profile');
      return _cachedUser; // Return cached user if available
    }

    try {
      print('Getting user doc from Firestore');
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        print('User doc exists, creating User object');
        _cachedUser = app_user.User.fromJson(userDoc); // Cache the result
        return _cachedUser;
      }
      print('No user document found for ID: $userId');
      return null;
    } catch (e, stackTrace) {
      print('Failed to get user profile: $e');
      print('Stack trace: $stackTrace');
      throw Exception('Failed to get user profile: $e');
    }
  }

  /// Add a user to Firestore
  Future<void> addUser(app_user.User user) async {
    await _firestore.collection('users').doc(user.uid).set(user.toJson());
  }

  /// Get a user document by their UID
  Future<app_user.User?> getUser(String uid) async {
    final docSnapshot = await _firestore.collection('users').doc(uid).get();
    if (docSnapshot.exists) {
      return app_user.User.fromJson(docSnapshot);
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
