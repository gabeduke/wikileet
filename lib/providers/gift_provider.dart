import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Added import for Timestamp
import '../models/gift.dart';
import '../services/gift_service.dart';

class GiftProvider with ChangeNotifier {
  final GiftService _giftService;
  
  Stream<List<Gift>>? _giftsForUser;
  String? _currentUserId;
  String? _currentFamilyGroupId;
  List<String> _pinnedCategories = [];
  
  GiftProvider({GiftService? giftService}) : _giftService = giftService ?? GiftService();
  
  Stream<List<Gift>>? get giftsForUser => _giftsForUser;
  List<String> get pinnedCategories => _pinnedCategories;

  Future<void> initializeGiftStreamForUser(String userId) async {
    if (kDebugMode) {
      print('Initializing gift stream for user: $userId');
    }
    
    // Clear any existing stream
    _giftsForUser = null;
    _currentUserId = userId;
    
    // Get the user's family group ID through the service
    try {
      final familyGroupId = await _giftService.getUserFamilyGroupId(userId);
      if (kDebugMode) {
        print('Retrieved familyGroupId: $familyGroupId for user: $userId');
      }
      _currentFamilyGroupId = familyGroupId;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting familyGroupId: $e');
      }
      _currentFamilyGroupId = null;
    }
    
    if (_currentFamilyGroupId == null) {
      if (kDebugMode) {
        print('Warning: No family group ID found for user $userId');
      }
      _giftsForUser = Stream.value([]);  // Return empty stream
      notifyListeners();
      return;
    }

    if (kDebugMode) {
      print('Found family group ID: $_currentFamilyGroupId');
    }
    
    // Migrate any old category data and load pinned categories in parallel
    try {
      await Future.wait([
        _giftService.migrateGiftCategories(userId),
        _loadPinnedCategories(),
      ]);
      if (kDebugMode) {
        print('Successfully migrated categories and loaded pinned categories');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error in migration or loading pinned categories: $e');
      }
    }

    // Initialize the filtered stream
    _giftsForUser = _giftService.getGiftListStreamForFamily(userId, _currentFamilyGroupId!);
    
    // Add debug listener with more detailed logging
    _giftsForUser?.listen(
      (gifts) {
        if (kDebugMode) {
          print('Stream update - received ${gifts.length} gifts');
          print('Gift categories: ${gifts.expand((g) => g.categories).toSet()}');
          print('Gift IDs: ${gifts.map((g) => g.id)}');
        }
      },
      onError: (e, stack) {
        if (kDebugMode) {
          print('Error in gift stream: $e');
          print('Stack trace: $stack');
        }
      }
    );
    
    notifyListeners();
  }

  Future<void> _loadPinnedCategories() async {
    if (_currentUserId == null) return;
    _pinnedCategories = await _giftService.getPinnedCategories(_currentUserId!);
    notifyListeners();
  }

  Future<void> updatePinnedCategories(List<String> categories) async {
    if (_currentUserId == null) throw Exception('No user initialized');
    
    try {
      await _giftService.updatePinnedCategories(_currentUserId!, categories);
      _pinnedCategories = categories;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error updating pinned categories: $e');
      }
      rethrow;
    }
  }

  Future<void> addGift(Map<String, dynamic> giftData) async {
    if (_currentUserId == null) throw Exception('No user initialized');
    if (_currentFamilyGroupId == null) throw Exception('No family group initialized');
    
    if (kDebugMode) {
      print('\n=== GiftProvider.addGift ===');
      print('Current user ID: $_currentUserId');
      print('Family group ID: $_currentFamilyGroupId');
      print('Initial gift data: $giftData');
    }

    try {
      // Validate required fields
      if (giftData['name'] == null || giftData['name'].toString().trim().isEmpty) {
        throw Exception('Gift name is required');
      }

      // Ensure we have all required fields
      final giftDataWithDefaults = {
        ...giftData,
        'id': giftData['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
        'familyGroupId': _currentFamilyGroupId,
        'ownerId': _currentUserId, // Add the owner ID to track who created the gift
        'visibility': giftData['visibility'] ?? true,
        'purchased': giftData['purchased'] ?? false,
        'categories': giftData['categories'] ?? <String>[],
        'createdAt': giftData['createdAt'] ?? Timestamp.now(),
      };
      
      if (kDebugMode) {
        print('Creating Gift object with data: $giftDataWithDefaults');
      }
      
      final newGift = Gift.fromMap(giftDataWithDefaults);
      
      if (kDebugMode) {
        print('Gift object created:');
        print('- ID: ${newGift.id}');
        print('- Name: ${newGift.name}');
        print('- Owner ID: ${newGift.ownerId}');  // Log the owner ID
        print('- Categories: ${newGift.categories}');
        print('- Family Group: ${newGift.familyGroupId}');
        print('Calling GiftService.addGift...');
      }
      
      await _giftService.addGift(_currentUserId!, newGift);
      
      if (kDebugMode) {
        print('Gift successfully added through service');
        print('=== End GiftProvider.addGift ===\n');
      }
    } catch (e, stack) {
      if (kDebugMode) {
        print('=== Error in GiftProvider.addGift ===');
        print('Error: $e');
        print('Stack trace: $stack');
        print('=================================\n');
      }
      rethrow;
    }
  }

  Future<void> updateGift(String giftId, Map<String, dynamic> updates) async {
    if (_currentUserId == null) throw Exception('No user initialized');
    if (_currentFamilyGroupId == null) throw Exception('No family group initialized');
    
    try {
      // Ensure updates maintain the family group ID
      updates['familyGroupId'] = _currentFamilyGroupId;
      await _giftService.updateGift(_currentUserId!, giftId, updates);
    } catch (e) {
      if (kDebugMode) {
        print('Error updating gift: $e');
      }
      rethrow;
    }
  }

  Future<void> updateGiftStatus(String giftId, bool isPurchased, String? purchasedBy) async {
    if (_currentUserId == null) throw Exception('No user initialized');

    try {
      await _giftService.updateGiftStatus(_currentUserId!, giftId, isPurchased, purchasedBy);
    } catch (e) {
      if (kDebugMode) {
        print('Error updating gift status: $e');
      }
      rethrow;
    }
  }

  Future<void> deleteGift(String giftId) async {
    if (_currentUserId == null) throw Exception('No user initialized');
    
    try {
      await _giftService.deleteGift(_currentUserId!, giftId);
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting gift: $e');
      }
      rethrow;
    }
  }

  Future<List<String>> getAllCategories() async {
    if (_currentUserId == null) throw Exception('No user initialized');
    return _giftService.getAllCategories(_currentUserId!);
  }
}