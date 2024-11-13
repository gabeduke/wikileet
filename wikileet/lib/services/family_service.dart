// lib/services/family_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wikileet/models/family_group.dart';
import 'package:wikileet/models/house.dart';

class FamilyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String?> getFamilyIdForUser(String email) async {
    print("Querying families for email: $email");

    final querySnapshot = await _firestore
        .collection('families')
        .where('assignedEmails', arrayContains: email)
        .get();

    print(
        "Query snapshot size: ${querySnapshot.size}"); // Check if any documents are returned

    if (querySnapshot.docs.isNotEmpty) {
      print("Family found: ${querySnapshot.docs.first.id}");
      return querySnapshot.docs.first.id;
    } else {
      print("No family found for the given email.");
      return null; // User does not belong to any family
    }
  }

  Future<List<FamilyGroup>> getAllFamilyGroups() async {
    final snapshot = await _firestore.collection('family_groups').get();
    return snapshot.docs.map((doc) => FamilyGroup.fromFirestore(doc)).toList();
  }

  Future<List<House>> getHousesForFamilyGroup(String familyGroupId) async {
    final snapshot = await _firestore
        .collection('family_groups')
        .doc(familyGroupId)
        .collection('houses')
        .get();
    return snapshot.docs.map((doc) => House.fromFirestore(doc)).toList();
  }

  Future<void> addMemberToFamilyGroup(
      String familyGroupId, String userId) async {
    final familyGroupRef =
        _firestore.collection('family_groups').doc(familyGroupId);
    await familyGroupRef.update({
      'members': FieldValue.arrayUnion([userId]),
    });
  }

  Future<void> addMemberToHouse(
      String familyGroupId, String houseId, String userId) async {
    final houseRef = _firestore
        .collection('family_groups')
        .doc(familyGroupId)
        .collection('houses')
        .doc(houseId);
    await houseRef.update({
      'members': FieldValue.arrayUnion([userId]),
    });
  }

  // Get the list of family members' user IDs for a given family
  Future<List<String>> getFamilyMembers(String familyId) async {
    final familyDoc =
        await _firestore.collection('families').doc(familyId).get();

    if (familyDoc.exists) {
      return List<String>.from(familyDoc['members']);
    } else {
      return []; // No members found
    }
  }

  Future<List<String>> getHouseMembers(
      String familyGroupId, String houseId) async {
    final doc = await _firestore
        .collection('family_groups')
        .doc(familyGroupId)
        .collection('houses')
        .doc(houseId)
        .get();
    final data = doc.data();
    return List<String>.from(data?['members'] ?? []);
  }
}
