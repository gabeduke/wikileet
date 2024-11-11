// lib/services/family_group_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wikileet/models/family_group.dart';

class FamilyGroupService {
  final FirebaseFirestore _firestore;

  FamilyGroupService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // Add a new family group
  Future<void> addFamilyGroup(FamilyGroup familyGroup) async {
    await _firestore.collection('familyGroups').doc(familyGroup.id).set(familyGroup.toFirestore());
  }

  // Retrieve a family group by ID
  Future<FamilyGroup?> getFamilyGroup(String id) async {
    final docSnapshot = await _firestore.collection('familyGroups').doc(id).get();
    if (docSnapshot.exists) {
      return FamilyGroup.fromFirestore(docSnapshot);
    }
    return null;
  }

  // Update family group members or name
  Future<void> updateFamilyGroup(String id, Map<String, dynamic> data) async {
    await _firestore.collection('familyGroups').doc(id).update(data);
  }

  // Delete a family group
  Future<void> deleteFamilyGroup(String id) async {
    await _firestore.collection('familyGroups').doc(id).delete();
  }
}
