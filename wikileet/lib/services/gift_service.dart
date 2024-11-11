// lib/services/gift_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wikileet/models/gift.dart';

class GiftService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  GiftService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  /// Expose the current user
  User? get currentUser => _auth.currentUser;

  /// Checks if the current user is the owner of the gift list.
  bool isOwner(String listOwnerId) {
    return currentUser != null && currentUser!.uid == listOwnerId;
  }

  /// Determines if a non-owner can mark a gift as purchased.
  bool canMarkAsPurchased(String listOwnerId, String? purchasedBy) {
    return currentUser != null &&
        currentUser!.uid != listOwnerId && // Not the owner
        purchasedBy == null; // Gift not yet marked as purchased
  }

  /// Retrieves the list of gifts for a given user.
  Future<List<Gift>> getGiftList(String userId) async {
    final querySnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('gifts')
        .orderBy('createdAt', descending: true)
        .get();

    return querySnapshot.docs
        .map((doc) => Gift.fromFirestore(doc))
        .toList();
  }

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

  /// Updates a gift's data, specifically for marking as purchased.
  Future<void> updateGift(String userId, String giftId, Map<String, dynamic> data) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('gifts')
        .doc(giftId)
        .update(data);
  }

  /// Deletes a gift, only allowed for the list owner.
  Future<void> deleteGift(String userId, String giftId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('gifts')
        .doc(giftId)
        .delete();
  }

}
