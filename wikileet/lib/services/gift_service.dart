// lib/services/gift_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wikileet/models/gift.dart';

class GiftService {
  final FirebaseFirestore _firestore;

  GiftService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // Add a new gift
  Future<void> addGift(String userId, Gift gift) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('gifts')
        .doc(gift.id)
        .set(gift.toFirestore());
  }

  // Retrieve a gift by ID for a specific user
  Future<Gift?> getGift(String userId, String giftId) async {
    final docSnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('gifts')
        .doc(giftId)
        .get();
    if (docSnapshot.exists) {
      return Gift.fromFirestore(docSnapshot);
    }
    return null;
  }

  // Update specific fields of a gift document
  Future<void> updateGift(String userId, String giftId, Map<String, dynamic> data) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('gifts')
        .doc(giftId)
        .update(data);
  }

  // Delete a gift document
  Future<void> deleteGift(String userId, String giftId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('gifts')
        .doc(giftId)
        .delete();
  }
}
