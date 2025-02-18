import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import '../models/family_group.dart';

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
    print('Initializing FamilyGroupProvider stream for user: $userId');
    if (_userId == userId && _isInitialized) {
      print('Stream already initialized for this user');
      return;
    }

    _cleanup();
    _userId = userId;
    _setLoading(true);
    
    try {
      final query = _firestore
          .collection('familyGroups')
          .where('members', arrayContains: userId);

      _subscription = query.snapshots().listen(
        (snapshot) {
          print('Received family groups snapshot with ${snapshot.docs.length} docs');
          _groups = snapshot.docs
              .map((doc) {
                if (!doc.exists || doc.data() == null) return null;
                return FamilyGroup.fromFirestore(doc);
              })
              .where((group) => group != null)
              .cast<FamilyGroup>()
              .toList();
          
          _setLoading(false);
          if (!_isInitialized) {
            _isInitialized = true;
          }
          notifyListeners();
        },
        onError: (error) {
          print('Error in family groups stream: $error');
          _setLoading(false);
          _isInitialized = false;
          notifyListeners();
        },
      );
    } catch (e) {
      print('Error initializing family groups stream: $e');
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
    try {
      final groupData = {
        'name': name,
        'members': [creatorId],
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': creatorId,
        'houseIds': [],
      };
      
      final docRef = await _firestore.collection('familyGroups').add(groupData);
      
      // Update the creator's user document with the new family group ID
      await _firestore.collection('users').doc(creatorId).update({
        'familyGroupId': docRef.id,
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error creating family group: $e');
      }
      rethrow;
    }
  }

  Future<void> joinFamilyGroup(String groupId, String userId) async {
    try {
      // Verify the group exists first
      final groupDoc = await _firestore.collection('familyGroups').doc(groupId).get();
      if (!groupDoc.exists) {
        throw 'Family group not found';
      }

      // Add user to group
      await _firestore.collection('familyGroups').doc(groupId).update({
        'members': FieldValue.arrayUnion([userId]),
      });
      
      // Update user's familyGroupId
      await _firestore.collection('users').doc(userId).update({
        'familyGroupId': groupId,
      });
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