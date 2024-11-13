// lib/services/user_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:wikileet/models/user.dart';

class UserService {
  final FirebaseFirestore _firestore;
  final auth.FirebaseAuth? _auth;

  UserService({FirebaseFirestore? firestore, auth.FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth;

  // Add UserProfile fetching functionality here
  Future<User?> getUserProfile(String id) async {
    try {
      final DocumentSnapshot doc = await _firestore.collection('users').doc(id).get();
      if (doc.exists) {
        return User.fromJson(doc);  // Updated to use fromJson
      } else {
        throw Exception("User not found");
      }
    } catch (e) {
      throw Exception("Failed to get user profile: $e");
    }
  }

  Future<void> addUserIfNotExists(auth.User user) async {
    final userDocRef = _firestore.collection('users').doc(user.uid);
    final docSnapshot = await userDocRef.get();

    if (!docSnapshot.exists) {
      await userDocRef.set({
        'uid': user.uid,
        'displayName': user.displayName ?? user.email,
        'email': user.email,
        'familyGroupId': null, // Set this as needed
        'profilePicUrl': user.photoURL,
      });
      print("User added to Firestore: ${user.email}");
    } else {
      print("User already exists in Firestore: ${user.email}");
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
