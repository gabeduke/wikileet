import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/gift.dart';

class GiftProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Stream<List<Gift>>? _giftsForUser;
  
  Stream<List<Gift>>? get giftsForUser => _giftsForUser;

  void initializeGiftStreamForUser(String userId) {
    _giftsForUser = _firestore
        .collection('gifts')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) {
              if (!doc.exists || doc.data() == null) return null;
              return Gift.fromFirestore(doc);
            })
            .where((gift) => gift != null)
            .cast<Gift>()
            .toList());
    notifyListeners();
  }

  Future<void> addGift(Map<String, dynamic> giftData) async {
    try {
      await _firestore.collection('gifts').add({
        ...giftData,
        'createdAt': FieldValue.serverTimestamp(),
        'purchased': false,
        'purchasedBy': null,
        'purchasedAt': null,
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error adding gift: $e');
      }
      rethrow;
    }
  }

  Future<void> updateGift(String giftId, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection('gifts').doc(giftId).update({
        ...updates,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error updating gift: $e');
      }
      rethrow;
    }
  }

  Future<void> updateGiftStatus(String giftId, bool isPurchased, String? purchasedBy) async {
    try {
      await _firestore.collection('gifts').doc(giftId).update({
        'purchased': isPurchased,
        'purchasedBy': purchasedBy,
        'purchasedAt': isPurchased ? FieldValue.serverTimestamp() : null,
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error updating gift status: $e');
      }
      rethrow;
    }
  }

  Future<void> deleteGift(String giftId) async {
    try {
      await _firestore.collection('gifts').doc(giftId).delete();
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting gift: $e');
      }
      rethrow;
    }
  }

  Stream<List<Gift>> getVisibleGiftsForFamily(String familyGroupId, String currentUserId) {
    return _firestore
        .collection('gifts')
        .where('familyGroupId', isEqualTo: familyGroupId)
        .where('visibility', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) {
              if (!doc.exists || doc.data() == null) return null;
              final gift = Gift.fromFirestore(doc);
              // Don't show purchased gifts unless the current user purchased them
              if (gift.purchased && gift.purchasedBy != currentUserId) {
                return null;
              }
              return gift;
            })
            .where((gift) => gift != null)
            .cast<Gift>()
            .toList());
  }
}