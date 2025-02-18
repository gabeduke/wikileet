import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import '../models/family_group.dart';
import '../models/house.dart';  // Add House model import

class FamilyGroupProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription? _subscription;
  List<FamilyGroup> _groups = [];
  String? _userId;
  bool _isInitialized = false;
  bool _isLoading = false;

  List<FamilyGroup> get groups => _groups;
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  bool get hasData => _groups.isNotEmpty;

  void initializeStream(String userId) {
    print('FamilyGroupProvider: Initializing stream for user: $userId');
    if (_userId == userId && _isInitialized) {
      print('FamilyGroupProvider: Stream already initialized for this user');
      return;
    }

    _cleanup();
    _userId = userId;
    _setLoading(true);
    
    try {
      print('FamilyGroupProvider: Setting up streams for user: $userId');
      
      // Listen to user document for both familyGroupId and houseId
      final userDoc = _firestore.collection('users').doc(userId).snapshots();
      
      _subscription = userDoc.listen((userSnapshot) {
        final userData = userSnapshot.data();
        final familyGroupId = userData?['familyGroupId'] as String?;
        final houseId = userData?['houseId'] as String?;
        
        print('FamilyGroupProvider: User familyGroupId: $familyGroupId, houseId: $houseId');
        
        if (familyGroupId == null || houseId == null) {
          print('FamilyGroupProvider: User missing family group or house assignment');
          _groups = [];
          _setLoading(false);
          if (!_isInitialized) {
            _isInitialized = true;
          }
          notifyListeners();
          return;
        }

        // Get both the family group and house data
        _firestore
            .collection('familyGroups')
            .doc(familyGroupId)
            .snapshots()
            .listen((groupSnapshot) {
          if (!groupSnapshot.exists) {
            print('FamilyGroupProvider: Family group $familyGroupId not found');
            _groups = [];
          } else {
            print('FamilyGroupProvider: Processing family group ${groupSnapshot.id}');
            final group = FamilyGroup.fromFirestore(groupSnapshot);
            
            // Get the house data
            _firestore
                .collection('houses')
                .doc(houseId)
                .get()
                .then((houseDoc) {
              if (houseDoc.exists) {
                final house = House.fromFirestore(houseDoc);
                group.houses = [house];  // Assign the user's current house
                _groups = [group];
              }
              
              _setLoading(false);
              if (!_isInitialized) {
                _isInitialized = true;
              }
              notifyListeners();
            });
          }
        });
      });
    } catch (e) {
      print('FamilyGroupProvider: Error initializing streams: $e');
      _setLoading(false);
      _isInitialized = false;
    }
  }

  void _cleanup() {
    _subscription?.cancel();
    _subscription = null;
    _groups = [];
  }

  void _setLoading(bool value) {
    if (_isLoading != value) {
      _isLoading = value;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _cleanup();
    super.dispose();
  }

  Future<void> createFamilyGroup(String name, String creatorId) async {
    print('FamilyGroupProvider: Creating new family group with name: $name for user: $creatorId');
    try {
      final batch = _firestore.batch();
      
      // Create new family group document
      final groupRef = _firestore.collection('familyGroups').doc();
      
      // Create initial house document
      final houseRef = _firestore.collection('houses').doc();
      final houseData = {
        'name': 'Main House',  // Default house name
        'members': [creatorId],
        'familyGroupId': groupRef.id,
      };
      
      // Family group data now includes the initial house
      final groupData = {
        'name': name,
        'members': [creatorId],
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': creatorId,
        'houseIds': [houseRef.id],  // Include the initial house ID
      };
      
      // Set up the batch operations
      batch.set(groupRef, groupData);
      batch.set(houseRef, houseData);
      
      // Update user document with both family group and house IDs
      final userRef = _firestore.collection('users').doc(creatorId);
      batch.update(userRef, {
        'familyGroupId': groupRef.id,
        'houseId': houseRef.id,
      });

      // Commit all operations atomically
      await batch.commit();
      
      print('FamilyGroupProvider: Created family group with ID: ${groupRef.id} and house with ID: ${houseRef.id}');
    } catch (e) {
      print('FamilyGroupProvider: Error creating family group: $e');
      rethrow;
    }
  }

  Future<void> joinFamilyGroup(String groupId, String userId) async {
    try {
      // First verify the group exists
      final groupDoc = await _firestore.collection('familyGroups').doc(groupId).get();
      if (!groupDoc.exists) {
        throw 'Family group not found';
      }

      // Get the first house in the family group (we can add house selection later)
      final housesQuery = await _firestore
          .collection('houses')
          .where('familyGroupId', isEqualTo: groupId)
          .limit(1)
          .get();

      if (housesQuery.docs.isEmpty) {
        throw 'No houses found in this family group';
      }

      final houseId = housesQuery.docs.first.id;

      // Use a batch to update all related documents
      final batch = _firestore.batch();

      // Add user to family group
      batch.update(
        _firestore.collection('familyGroups').doc(groupId),
        {
          'members': FieldValue.arrayUnion([userId]),
        },
      );

      // Add user to house
      batch.update(
        _firestore.collection('houses').doc(houseId),
        {
          'members': FieldValue.arrayUnion([userId]),
        },
      );

      // Update user's familyGroupId and houseId
      batch.update(
        _firestore.collection('users').doc(userId),
        {
          'familyGroupId': groupId,
          'houseId': houseId,
        },
      );

      // Commit all changes
      await batch.commit();
      
      print('User $userId joined family group $groupId and house $houseId');
    } catch (e) {
      if (kDebugMode) {
        print('Error joining family group: $e');
      }
      rethrow;
    }
  }

  Future<void> removeMember(String groupId, String userId) async {
    try {
      // Start a batch write
      final batch = _firestore.batch();
      
      // Remove user from group
      batch.update(
        _firestore.collection('familyGroups').doc(groupId),
        {
          'members': FieldValue.arrayRemove([userId])
        },
      );
      
      // Remove familyGroupId from user
      batch.update(
        _firestore.collection('users').doc(userId),
        {
          'familyGroupId': null,
          'houseId': null,  // Also clear house assignment
        },
      );

      // Commit the batch
      await batch.commit();
    } catch (e) {
      if (kDebugMode) {
        print('Error removing member: $e');
      }
      rethrow;
    }
  }

  Future<void> updateFamilyGroup(String groupId, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection('familyGroups').doc(groupId).update(updates);
    } catch (e) {
      if (kDebugMode) {
        print('Error updating family group: $e');
      }
      rethrow;
    }
  }
}