// lib/models/user.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String uid;
  final String displayName;
  final String email;
  final String? familyGroupId;
  final String? houseId;
  final String? profilePicUrl;
  final bool isFamilyAdmin = false;
  final bool isGlobalAdmin = false;

  User({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.familyGroupId,
    this.houseId,
    this.profilePicUrl,
  });

  // Factory constructor for creating a new User instance from Firestore document
  factory User.fromJson(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return User(
      uid: doc.id,
      displayName: data['displayName'] ?? '',
      email: data['email'] ?? '',
      familyGroupId: data['familyGroupId'],
      houseId: data['houseId'], // Retrieve houseId from Firestore
      profilePicUrl: data['profilePicUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'displayName': displayName,
      'email': email,
      'familyGroupId': familyGroupId,
      'houseId': houseId, // Include when saving to Firestore
      'profilePicUrl': profilePicUrl,
    };
  }
}
