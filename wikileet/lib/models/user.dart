// lib/models/user.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String uid;
  final String displayName;
  final String email;
  final String? familyGroupId;
  final String? profilePicUrl;

  User({
    required this.uid,
    required this.displayName,
    required this.email,
    this.familyGroupId,
    this.profilePicUrl,
  });

  // Factory constructor for creating a new User instance from Firestore document
  factory User.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return User(
      uid: doc.id,
      displayName: data['displayName'] ?? '',
      email: data['email'] ?? '',
      familyGroupId: data['familyGroupId'],
      profilePicUrl: data['profilePicUrl'],
    );
  }

  // Convert User instance to Firestore compatible JSON
  Map<String, dynamic> toFirestore() {
    return {
      'displayName': displayName,
      'email': email,
      'familyGroupId': familyGroupId,
      'profilePicUrl': profilePicUrl,
    };
  }
}
