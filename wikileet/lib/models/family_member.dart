// lib/models/family_member.dart

class FamilyMember {
  final String id; // Unique ID of the family member, usually from Firestore
  final String displayName; // Name displayed for the family member

  FamilyMember({required this.id, required this.displayName});

  // Factory constructor to create a FamilyMember instance from Firestore data
  factory FamilyMember.fromFirestore(Map<String, dynamic> data, String id) {
    return FamilyMember(
      id: id,
      displayName: data['displayName'] ?? 'Unknown', // Default to 'Unknown' if no name provided
    );
  }

  get name => displayName;

  // Convert FamilyMember instance to Firestore-compatible JSON
  Map<String, dynamic> toFirestore() {
    return {
      'displayName': displayName,
    };
  }
}
