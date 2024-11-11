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

  Future<void> addUser(User user) async {
    await _firestore.collection('users').doc(user.uid).set(user.toFirestore());
  }

  Future<User?> getUser(String uid) async {
    final docSnapshot = await _firestore.collection('users').doc(uid).get();
    if (docSnapshot.exists) {
      return User.fromFirestore(docSnapshot);
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
