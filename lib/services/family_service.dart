import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wikileet/models/family_group.dart';
import 'package:wikileet/models/house.dart';

class FamilyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String FAMILY_GROUPS_COLLECTION = 'familyGroups';
  static const String HOUSES_COLLECTION = 'houses';

  /// Subscribe to real-time updates for a user profile
  Stream<Map<String, dynamic>> subscribeToUserProfile(String userId) {
    return _firestore.collection('users').doc(userId).snapshots().map((snapshot) {
      return snapshot.data() ?? {};
    });
  }

  /// Fetch and subscribe to a family group by ID
  Stream<FamilyGroup?> subscribeToFamilyGroup(String familyGroupId) {
    return _firestore.collection(FAMILY_GROUPS_COLLECTION).doc(familyGroupId).snapshots().map((snapshot) {
      if (snapshot.exists) {
        return FamilyGroup.fromFirestore(snapshot);
      }
      return null;
    });
  }

  /// Fetch and subscribe to houses in a family group
  Stream<List<House>> subscribeToHouses(String familyGroupId) {
    return _firestore
        .collection(HOUSES_COLLECTION)
        .where('familyGroupId', isEqualTo: familyGroupId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => House.fromFirestore(doc)).toList());
  }

  /// Set the family and house for a user, ensuring they are removed from any other houses in the same family group.
  Future<void> setFamilyAndHouseForUser(
      String familyGroupId, String? houseId, String userId) async {
    final userRef = _firestore.collection('users').doc(userId);
    final familyGroupRef =
        _firestore.collection(FAMILY_GROUPS_COLLECTION).doc(familyGroupId);

    await _firestore.runTransaction((transaction) async {
      // Update user's familyGroupId and houseId
      transaction.update(userRef, {
        'familyGroupId': familyGroupId,
        'houseId': houseId,
      });

      // Add user to family group members
      transaction.update(familyGroupRef, {
        'members': FieldValue.arrayUnion([userId]),
      });

      // Remove user from all houses in the family group
      final housesSnapshot = await _firestore
          .collection(HOUSES_COLLECTION)
          .where('familyGroupId', isEqualTo: familyGroupId)
          .get();
      for (final houseDoc in housesSnapshot.docs) {
        final houseRef = houseDoc.reference;

        if (houseDoc.id != houseId) {
          // Remove the user from all other houses
          transaction.update(houseRef, {
            'members': FieldValue.arrayRemove([userId]),
          });
        }
      }

      // Add user to the new house, if provided
      if (houseId != null) {
        final houseRef = _firestore.collection(HOUSES_COLLECTION).doc(houseId);
        transaction.update(houseRef, {
          'members': FieldValue.arrayUnion([userId]),
        });
      }
    });
  }

  /// Add a user to the family group and update their `familyGroupId` field.
  Future<void> addMemberToFamilyGroup(
      String familyGroupId, String userId) async {
    final familyGroupRef =
        _firestore.collection(FAMILY_GROUPS_COLLECTION).doc(familyGroupId);
    final userRef = _firestore.collection('users').doc(userId);

    await _firestore.runTransaction((transaction) async {
      transaction.update(familyGroupRef, {
        'members': FieldValue.arrayUnion([userId]),
      });
      transaction.update(userRef, {'familyGroupId': familyGroupId});
    });
  }

  /// Remove a user from the family group and clear their `familyGroupId`.
  Future<void> removeMemberFromFamilyGroup(
      String familyGroupId, String userId) async {
    final familyGroupRef =
        _firestore.collection(FAMILY_GROUPS_COLLECTION).doc(familyGroupId);
    final userRef = _firestore.collection('users').doc(userId);

    await _firestore.runTransaction((transaction) async {
      transaction.update(familyGroupRef, {
        'members': FieldValue.arrayRemove([userId]),
      });
      transaction.update(userRef, {'familyGroupId': null});
    });
  }

  /// Add a user to a specific house within a family group.
  Future<void> addMemberToHouse(
      String familyGroupId, String houseId, String userId) async {
    final houseRef = _firestore.collection(HOUSES_COLLECTION).doc(houseId);
    final userRef = _firestore.collection('users').doc(userId);
    
    await _firestore.runTransaction((transaction) async {
      transaction.update(houseRef, {
        'members': FieldValue.arrayUnion([userId]),
      });
      transaction.update(userRef, {
        'houseId': houseId,
        'familyGroupId': familyGroupId
      });
    });
  }

  /// Remove a user from a specific house and clear their `houseId`.
  Future<void> removeMemberFromHouse(
      String familyGroupId, String houseId, String userId) async {
    final houseRef = _firestore.collection(HOUSES_COLLECTION).doc(houseId);
    final userRef = _firestore.collection('users').doc(userId);

    await _firestore.runTransaction((transaction) async {
      transaction.update(houseRef, {
        'members': FieldValue.arrayRemove([userId]),
      });
      transaction.update(userRef, {'houseId': null});
    });
  }

  /// Fetch all family groups.
  Future<List<FamilyGroup>> getAllFamilyGroups() async {
    try {
      final snapshot = await _firestore.collection(FAMILY_GROUPS_COLLECTION).get();
      return snapshot.docs
          .map((doc) => FamilyGroup.fromFirestore(doc))
          .toList();
    } catch (e) {
      print("Error fetching all family groups: $e");
      return [];
    }
  }

  /// Fetch all houses in a specified family group.
  Future<List<House>> getHousesForFamilyGroup(String familyGroupId) async {
    try {
      // First get the family group to get the house IDs
      final familyDoc = await _firestore.collection(FAMILY_GROUPS_COLLECTION).doc(familyGroupId).get();
      if (!familyDoc.exists) return [];
      
      final familyData = familyDoc.data() as Map<String, dynamic>;
      final houseIds = List<String>.from(familyData['houseIds'] ?? []);
      
      if (houseIds.isEmpty) return [];

      // Fetch all referenced houses
      final houseDocs = await Future.wait(
        houseIds.map((id) => _firestore.collection(HOUSES_COLLECTION).doc(id).get())
      );

      return houseDocs
          .where((doc) => doc.exists)
          .map((doc) => House.fromFirestore(doc))
          .toList();
    } catch (e) {
      print("Error fetching houses for family group $familyGroupId: $e");
      return [];
    }
  }

  /// Retrieve all members of a family by user IDs.
  Future<List<String>> getFamilyMembers(String familyId) async {
    try {
      final familyDoc =
          await _firestore.collection(FAMILY_GROUPS_COLLECTION).doc(familyId).get();
      return familyDoc.exists ? List<String>.from(familyDoc['members']) : [];
    } catch (e) {
      print("Error fetching family members for family ID $familyId: $e");
      return [];
    }
  }

  /// Retrieve all members of a house by user IDs.
  Future<List<String>> getHouseMembers(
      String familyGroupId, String houseId) async {
    try {
      final doc = await _firestore
          .collection(HOUSES_COLLECTION)
          .doc(houseId)
          .get();
      final data = doc.data();
      return List<String>.from(data?['members'] ?? []);
    } catch (e) {
      print(
          "Error fetching house members for house $houseId in family group $familyGroupId: $e");
      return [];
    }
  }

  /// Add a new family group.
  Future<String> addFamilyGroup(String name) async {
    try {
      final docRef = await _firestore.collection(FAMILY_GROUPS_COLLECTION).add({
        'name': name,
        'members': [],
        'houseIds': [],
        'createdAt': FieldValue.serverTimestamp(),
      });
      print('Created family group with ID: ${docRef.id}'); // Debug log
      return docRef.id;
    } catch (e) {
      print("Error adding family group '$name': $e");
      rethrow; // Rethrow to handle in UI
    }
  }

  /// Add a new house to a specific family group.
  Future<void> addHouse(String familyGroupId, String name) async {
    try {
      final familyGroupRef =
          _firestore.collection(FAMILY_GROUPS_COLLECTION).doc(familyGroupId);
      final houseRef = _firestore.collection(HOUSES_COLLECTION).doc();
      await houseRef.set({
        'name': name,
        'members': [],
        'familyGroupId': familyGroupId,
      });

      // Update the family group to include the new house ID
      await familyGroupRef.update({
        'houseIds': FieldValue.arrayUnion([houseRef.id]),
      });
    } catch (e) {
      print("Error adding house '$name' to family group $familyGroupId: $e");
    }
  }

  /// Delete a house from a specific family group.
  Future<void> deleteHouse(String familyGroupId, String houseId) async {
    try {
      final houseRef = _firestore.collection(HOUSES_COLLECTION).doc(houseId);
      await houseRef.delete();

      // Update the family group to remove the house ID
      final familyGroupRef =
          _firestore.collection(FAMILY_GROUPS_COLLECTION).doc(familyGroupId);
      await familyGroupRef.update({
        'houseIds': FieldValue.arrayRemove([houseId]),
      });
    } catch (e) {
      print("Error deleting house $houseId: $e");
    }
  }

  /// Update the name of a house within a family group.
  Future<void> updateHouseName(
      String familyGroupId, String houseId, String newName) async {
    try {
      final houseRef = _firestore.collection(HOUSES_COLLECTION).doc(houseId);
      await houseRef.update({'name': newName});
    } catch (e) {
      print("Error updating house $houseId name to '$newName': $e");
    }
  }

  /// Delete a family group by its ID.
  Future<void> deleteFamilyGroup(String familyGroupId) async {
    try {
      final familyGroupRef =
          _firestore.collection(FAMILY_GROUPS_COLLECTION).doc(familyGroupId);
      await familyGroupRef.delete();
    } catch (e) {
      print("Error deleting family group $familyGroupId: $e");
    }
  }

  Future<FamilyGroup> getFamilyGroupById(String familyGroupId) async {
    try {
      final doc =
          await _firestore.collection(FAMILY_GROUPS_COLLECTION).doc(familyGroupId).get();
      if (doc.exists) {
        return FamilyGroup.fromFirestore(doc);
      } else {
        throw Exception("Family group not found");
      }
    } catch (e) {
      print("Error fetching family group by ID: $e");
      rethrow;
    }
  }
}
