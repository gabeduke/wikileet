// ...existing code...
import 'package:cloud_firestore/cloud_firestore.dart';

class FamilyGroupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createFamilyGroup(String name, String creatorId) async {
    final batch = _firestore.batch();
    
    // Create new family group document
    final groupRef = _firestore.collection('familyGroups').doc();

    // Create initial house document
    final houseRef = _firestore.collection('houses').doc();
    final houseData = {
      'name': 'Main House',
      'members': [creatorId],
      'familyGroupId': groupRef.id,
    };

    // Family group data now includes the initial house
    final groupData = {
      'name': name,
      'members': [creatorId],
      'createdAt': FieldValue.serverTimestamp(),
      'createdBy': creatorId,
      'houseIds': [houseRef.id],
    };

    batch.set(groupRef, groupData);
    batch.set(houseRef, houseData);

    // Update user document with both family group and house IDs
    final userRef = _firestore.collection('users').doc(creatorId);
    batch.update(userRef, {
      'familyGroupId': groupRef.id,
      'houseId': houseRef.id,
    });

    await batch.commit();
  }

  Future<void> joinFamilyGroup(String groupId, String userId) async {
    // Verify the group exists
    final groupDoc = await _firestore.collection('familyGroups').doc(groupId).get();
    if (!groupDoc.exists) {
      throw Exception('Family group not found');
    }

    // Get the first house in the family group
    final housesQuery = await _firestore
        .collection('houses')
        .where('familyGroupId', isEqualTo: groupId)
        .limit(1)
        .get();

    if (housesQuery.docs.isEmpty) {
      throw Exception('No houses found in this family group');
    }

    final houseId = housesQuery.docs.first.id;
    final batch = _firestore.batch();

    batch.update(
      _firestore.collection('familyGroups').doc(groupId),
      {'members': FieldValue.arrayUnion([userId])},
    );

    batch.update(
      _firestore.collection('houses').doc(houseId),
      {'members': FieldValue.arrayUnion([userId])},
    );

    batch.update(
      _firestore.collection('users').doc(userId),
      {
        'familyGroupId': groupId,
        'houseId': houseId,
      },
    );

    await batch.commit();
  }

  Future<void> removeMember(String groupId, String userId) async {
    final batch = _firestore.batch();

    batch.update(
      _firestore.collection('familyGroups').doc(groupId),
      {'members': FieldValue.arrayRemove([userId])},
    );

    batch.update(
      _firestore.collection('users').doc(userId),
      {
        'familyGroupId': null,
        'houseId': null,
      },
    );

    await batch.commit();
  }

  Future<void> updateFamilyGroup(String groupId, Map<String, dynamic> updates) async {
    await _firestore.collection('familyGroups').doc(groupId).update(updates);
  }
}
// ...existing code...
