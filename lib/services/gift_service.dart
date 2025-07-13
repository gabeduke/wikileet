// lib/services/gift_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rxdart/rxdart.dart';
import 'package:wikileet/models/gift.dart';
import 'package:flutter/foundation.dart';

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
    if (gifts.isEmpty) return;
    
    // Validate all gifts have the same familyGroupId
    final familyGroupId = gifts.first.familyGroupId;
    if (gifts.any((gift) => gift.familyGroupId != familyGroupId)) {
      throw Exception('All gifts must belong to the same family group');
    }

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
    if (kDebugMode) {
      print('\n=== GiftService.addGift ===');
      print('Adding gift for user: $userId');
      print('Gift ID: ${gift.id}');
      print('Family Group ID: ${gift.familyGroupId}');
    }

    // First validate the gift belongs to a family group
    if (gift.familyGroupId.isEmpty) {
      throw Exception('Gift must have a valid family group ID');
    }

    // Validate the user belongs to the family group
    final userDoc = await _firestore.collection('users').doc(userId).get();
    final userData = userDoc.data();
    if (userData == null) {
      throw Exception('User not found');
    }
    
    final userFamilyGroupId = userData['familyGroupId'] as String?;
    if (userFamilyGroupId != gift.familyGroupId) {
      throw Exception('Gift must belong to the user\'s current family group');
    }

    try {
      if (kDebugMode) {
        print('Creating Firestore document with ID: ${gift.id}');
        print('Gift data: ${gift.toFirestore()}');
      }

      // Use .set() with merge:true to ensure we create or update
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('gifts')
          .doc(gift.id)
          .set(gift.toFirestore(), SetOptions(merge: true));
      
      if (kDebugMode) {
        print('Gift document created/updated successfully');
        print('=== End GiftService.addGift ===\n');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error creating gift document: $e');
      }
      rethrow;
    }
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
    // Ensure we're not changing the familyGroupId
    if (data.containsKey('familyGroupId')) {
      final gift = await getGift(userId, giftId);
      if (gift != null && gift.familyGroupId != data['familyGroupId']) {
        throw Exception('Cannot change gift\'s family group');
      }
    }

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('gifts')
        .doc(giftId)
        .update(data);
  }

  // Added updateGiftStatus method to delegate updating purchase status
  Future<void> updateGiftStatus(String userId, String giftId, bool isPurchased, String? purchasedBy) async {
    final data = {
      'purchased': isPurchased,
      'purchasedBy': purchasedBy,
    };
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

  /// Get a user's family group ID
  Future<String?> getUserFamilyGroupId(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    return doc.data()?['familyGroupId'] as String?;
  }

  /// Get a filtered stream of gifts for a specific family group
  Stream<List<Gift>> getGiftListStreamForFamily(String userId, String familyGroupId) {
    if (familyGroupId.isEmpty) {
      print('Empty familyGroupId provided');
      return Stream.value([]);
    }

    // First validate user's family group membership
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .switchMap<List<Gift>>((userDoc) {
          if (!userDoc.exists) {
            print('User document does not exist');
            return Stream.value([]);
          }

          final userData = userDoc.data();
          if (userData == null) {
            print('User data is null');
            return Stream.value([]);
          }

          final userFamilyGroupId = userData['familyGroupId'] as String?;
          if (userFamilyGroupId != familyGroupId) {
            print('User familyGroupId ($userFamilyGroupId) does not match requested familyGroupId ($familyGroupId)');
            return Stream.value([]);
          }

          print('Getting gifts for user $userId in family group $familyGroupId');

          // Now get the gifts for this user and family
          return _firestore
              .collection('users')
              .doc(userId)
              .collection('gifts')
              .where('familyGroupId', isEqualTo: familyGroupId)
              .orderBy('createdAt', descending: true)
              .snapshots()
              .map((snapshot) {
                try {
                  final gifts = snapshot.docs
                      .map((doc) => Gift.fromFirestore(doc))
                      .toList();
                  print('Retrieved ${gifts.length} gifts from Firestore');
                  return gifts;
                } catch (e) {
                  print('Error mapping gifts: $e');
                  return [];
                }
              });
        });
  }

  /// Get current server timestamp for creating gifts
  Timestamp getCurrentTimestamp() {
    return Timestamp.now();
  }
}
