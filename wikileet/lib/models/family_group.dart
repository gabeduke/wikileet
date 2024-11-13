// lib/models/family_group.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class FamilyGroup {
  final String id;
  final String name;
  final List<String> members;
  final List<String> houseIds; // New field

  FamilyGroup({
    required this.id,
    required this.name,
    required this.members,
    required this.houseIds, // Include in constructor
  });

  // Factory constructor for creating a FamilyGroup instance from Firestore
  factory FamilyGroup.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FamilyGroup(
      id: doc.id,
      name: data['name'] ?? '',
      members: List<String>.from(data['members'] ?? []),
      houseIds: List<String>.from(data['houseIds'] ?? []), // Retrieve houseIds
    );
  }

  // Convert FamilyGroup instance to Firestore-compatible JSON
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'members': members,
      'houseIds': houseIds, // Include when saving
    };
  }
}
