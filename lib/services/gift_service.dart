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

    return querySnapshot.docs.map((doc) => Gift.fromFirestore(doc)).toList();
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
    final userGiftsRef =
        _firestore.collection('users').doc(userId).collection('gifts');

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
  Future<void> updateGift(
      String userId, String giftId, Map<String, dynamic> data) async {
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

  /// Migrate a single category string to a list of categories.
  /// This ensures backward compatibility with existing data.
  List<String> _migrateCategoryToList(dynamic categoryData) {
    if (categoryData == null) {
      return [];
    }
    if (categoryData is String) {
      return [categoryData]; // Convert single category to list
    }
    if (categoryData is List) {
      return categoryData.map((e) => e.toString()).toList();
    }
    return [];
  }

  /// Updates the gift data model for all gifts in a user's list.
  /// This should be called when initializing the app to ensure data consistency.
  Future<void> migrateGiftCategories(String userId) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('gifts')
        .get();

    final batch = _firestore.batch();
    var needsMigration = false;

    for (var doc in snapshot.docs) {
      final data = doc.data();
      if (data['category'] != null && data['categories'] == null) {
        // Convert old single category to new categories list
        batch.update(doc.reference, {
          'categories': [data['category']],
          'category': FieldValue.delete(), // Remove old field
        });
        needsMigration = true;
      }
    }

    if (needsMigration) {
      await batch.commit();
    }
  }

  Future<List<String>> getAllCategories(String userId) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('gifts')
        .get();

    final categories = snapshot.docs
        .expand((doc) {
          final data = doc.data();
          final cats = (data['categories'] as List<dynamic>?)?.cast<String>() ?? [];
          return cats;
        })
        .toSet()
        .toList()
      ..sort();

    return categories;  // Now just return the List<String> directly
  }

  Future<List<String>> getPinnedCategories(String userId) async {
    final doc = await _firestore
        .collection('users')
        .doc(userId)
        .get();
    
    final data = doc.data();
    return (data?['pinnedCategories'] as List<dynamic>?)?.cast<String>() ?? [];
  }

  Future<void> updatePinnedCategories(String userId, List<String> categories) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .set({
          'pinnedCategories': categories,
        }, SetOptions(merge: true));
  }
}
