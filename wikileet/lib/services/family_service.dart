// lib/services/family_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wikileet/models/family_group.dart';
import 'package:wikileet/models/house.dart';

class FamilyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Fetches the family ID for a user by their email address.
  Future<String?> getFamilyIdForUser(String email) async {
    try {
      print("Querying families for email: $email");
      final querySnapshot = await _firestore
          .collection('family_groups')
          .where('assignedEmails', arrayContains: email)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        print("Family found with ID: ${querySnapshot.docs.first.id}");
        return querySnapshot.docs.first.id;
      } else {
        print("No family found for the given email.");
        return null;
      }
    } catch (e) {
      print("Error fetching family ID: $e");
      return null;
    }
  }

  /// Retrieves all family groups.
  Future<List<FamilyGroup>> getAllFamilyGroups() async {
    try {
      final snapshot = await _firestore.collection('family_groups').get();
      return snapshot.docs.map((doc) => FamilyGroup.fromFirestore(doc)).toList();
    } catch (e) {
      print("Error fetching all family groups: $e");
      return [];
    }
  }

  /// Retrieves all houses for a specified family group.
  Future<List<House>> getHousesForFamilyGroup(String familyGroupId) async {
    try {
      final snapshot = await _firestore
          .collection('family_groups')
          .doc(familyGroupId)
          .collection('houses')
          .get();
      return snapshot.docs.map((doc) => House.fromFirestore(doc)).toList();
    } catch (e) {
      print("Error fetching houses for family group $familyGroupId: $e");
      return [];
    }
  }

  /// Adds a user ID to a specified family group as a member.
  Future<void> addMemberToFamilyGroup(String familyGroupId, String userId) async {
    try {
      final familyGroupRef = _firestore.collection('family_groups').doc(familyGroupId);
      await familyGroupRef.update({
        'members': FieldValue.arrayUnion([userId]),
      });
    } catch (e) {
      print("Error adding member to family group $familyGroupId: $e");
    }
  }

  /// Adds a user ID to a specified house within a family group.
  Future<void> addMemberToHouse(String familyGroupId, String houseId, String userId) async {
    try {
      final houseRef = _firestore
          .collection('family_groups')
          .doc(familyGroupId)
          .collection('houses')
          .doc(houseId);
      await houseRef.update({
        'members': FieldValue.arrayUnion([userId]),
      });
    } catch (e) {
      print("Error adding member to house $houseId in family group $familyGroupId: $e");
    }
  }

  /// Retrieves a list of family member user IDs for a specified family.
  Future<List<String>> getFamilyMembers(String familyId) async {
    try {
      final familyDoc = await _firestore.collection('family_groups').doc(familyId).get();
      if (familyDoc.exists) {
        return List<String>.from(familyDoc['members']);
      } else {
        print("No family document found for ID: $familyId");
        return [];
      }
    } catch (e) {
      print("Error fetching family members for family ID $familyId: $e");
      return [];
    }
  }

  /// Retrieves a list of house member user IDs for a specified house in a family group.
  Future<List<String>> getHouseMembers(String familyGroupId, String houseId) async {
    try {
      final doc = await _firestore
          .collection('family_groups')
          .doc(familyGroupId)
          .collection('houses')
          .doc(houseId)
          .get();
      final data = doc.data();
      return List<String>.from(data?['members'] ?? []);
    } catch (e) {
      print("Error fetching house members for house $houseId in family group $familyGroupId: $e");
      return [];
    }
  }

  /// Adds a new family group with the specified name.
  Future<void> addFamilyGroup(String name) async {
    try {
      await _firestore.collection('family_groups').add({
        'name': name,
        'members': [],
      });
      print("Family group '$name' added successfully.");
    } catch (e) {
      print("Error adding family group '$name': $e");
    }
  }

  /// Adds a new house to a specified family group with the given name.
  Future<void> addHouse(String familyGroupId, String name) async {
    try {
      final familyGroupRef = _firestore.collection('family_groups').doc(familyGroupId);
      final houseRef = familyGroupRef.collection('houses').doc();
      await houseRef.set({
        'name': name,
        'members': [],
      });
      print("House '$name' added to family group $familyGroupId successfully.");
    } catch (e) {
      print("Error adding house '$name' to family group $familyGroupId: $e");
    }
  }

  deleteHouse(String familyGroupId, String houseId) {
    print("Deleting house $houseId from family group $familyGroupId");
    try {
      final houseRef = _firestore
          .collection('family_groups')
          .doc(familyGroupId)
          .collection('houses')
          .doc(houseId);
      houseRef.delete();
      print("House $houseId deleted successfully.");
    } catch (e) {
      print("Error deleting house $houseId: $e");
    }

  }

  updateHouseName(String familyGroupId, String houseId, String newName) {
    print("Updating house $houseId name to '$newName'");
    try {
      final houseRef = _firestore
          .collection('family_groups')
          .doc(familyGroupId)
          .collection('houses')
          .doc(houseId);
      houseRef.update
      ({
        'name': newName,
      });
      print("House $houseId name updated to '$newName' successfully.");
    } catch (e) {
      print("Error updating house $houseId name to '$newName': $e");
    }
  }

  deleteFamilyGroup(String familyGroupId) {
    print("Deleting family group $familyGroupId");
    try {
      final familyGroupRef = _firestore.collection('family_groups').doc(familyGroupId);
      familyGroupRef.delete();
      print("Family group $familyGroupId deleted successfully.");
    } catch (e) {
      print("Error deleting family group $familyGroupId: $e");
    }
  }
}
