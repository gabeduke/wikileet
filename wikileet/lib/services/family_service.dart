// lib/services/family_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wikileet/models/family_member.dart';

class FamilyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String?> getFamilyIdForUser(String email) async {
    print("Querying families for email: $email");

    final querySnapshot = await _firestore
        .collection('families')
        .where('assignedEmails', arrayContains: email)
        .get();

    print("Query snapshot size: ${querySnapshot.size}"); // Check if any documents are returned

    if (querySnapshot.docs.isNotEmpty) {
      print("Family found: ${querySnapshot.docs.first.id}");
      return querySnapshot.docs.first.id;
    } else {
      print("No family found for the given email.");
      return null; // User does not belong to any family
    }
  }


  // Get the list of family members' user IDs for a given family
  Future<List<String>> getFamilyMembers(String familyId) async {
    final familyDoc = await _firestore
        .collection('families')
        .doc(familyId)
        .get();

    if (familyDoc.exists) {
      return List<String>.from(familyDoc['members']);
    } else {
      return []; // No members found
    }
  }
}
