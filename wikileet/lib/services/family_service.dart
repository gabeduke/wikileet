// lib/services/family_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wikileet/models/family_member.dart';

class FamilyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<FamilyMember>> getFamilyMembers(String userId) async {
    final familyMembersRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('familyMembers');

    final querySnapshot = await familyMembersRef.get();
    return querySnapshot.docs.map((doc) {
      return FamilyMember.fromFirestore(doc.data(), doc.id);
    }).toList();
  }
}
