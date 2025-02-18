// lib/models/house.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class House {
  final String id;
  final String name;
  final List<String> memberIds; // Raw IDs fetched from Firestore
  final String familyGroupId; // Add this to track which family the house belongs to
  List<String> members; // Display names for the UI

  House({
    required this.id,
    required this.name,
    required this.memberIds,
    required this.familyGroupId,
    this.members = const [],
  });

  factory House.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return House(
      id: doc.id,
      name: data['name'] ?? '',
      memberIds: List<String>.from(data['members'] ?? []),
      familyGroupId: data['familyGroupId'] ?? '',
      members: const [], // This will be populated later with display names
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'members': memberIds,
      'familyGroupId': familyGroupId,
    };
  }
}
