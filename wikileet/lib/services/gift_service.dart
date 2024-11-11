// lib/services/gift_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wikileet/models/gift.dart';

class GiftService {
  final FirebaseFirestore _firestore;

  GiftService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;
  
  // Method for batch adding multiple gifts
  Future<void> batchAddGifts(String userId, List<Gift> gifts) async {
    final batch = _firestore.batch();
    final userGiftsRef = _firestore.collection('users').doc(userId).collection('gifts');

    for (var gift in gifts) {
      final giftRef = userGiftsRef.doc(gift.id);
      batch.set(giftRef, gift.toFirestore());
    }

    try {
      await batch.commit();
    } catch (e) {
      throw Exception("Failed to add gifts: $e");
    }
  }

  // Stream to get real-time updates for a user's gift list
  Stream<List<Gift>> getGiftListStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('gifts')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => Gift.fromFirestore(doc)).toList());
  }

  Future<void> addGift(String userId, Gift gift) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('gifts')
          .doc(gift.id)
          .set(gift.toFirestore());
    } catch (e) {
      throw Exception("Failed to add gift: $e");
    }
  }

  Future<void> updateGift(String userId, String giftId, Map<String, dynamic> data) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('gifts')
          .doc(giftId)
          .update(data);
    } catch (e) {
      throw Exception("Failed to update gift: $e");
    }
  }

  Future<void> deleteGift(String userId, String giftId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('gifts')
          .doc(giftId)
          .delete();
    } catch (e) {
      throw Exception("Failed to delete gift: $e");
    }
  }
}
