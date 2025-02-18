import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/gift.dart';
import '../services/gift_service.dart';

class GiftListViewModel extends ChangeNotifier {
  final GiftService giftService;
  final String giftListOwnerId;
  final String currentUserId;
  
  Stream<List<Gift>>? _giftsStream;
  List<Gift> _gifts = [];
  Map<String, List<Gift>> _giftsByCategory = {};
  bool _isLoading = false;
  String? _error;

  GiftListViewModel({
    required this.giftService,
    required this.giftListOwnerId,
    required this.currentUserId,
  }) {
    _initGiftsStream();
  }

  List<Gift> get gifts => _gifts;
  Map<String, List<Gift>> get giftsByCategory => _giftsByCategory;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isOwner => currentUserId == giftListOwnerId;

  void _initGiftsStream() {
    _giftsStream = FirebaseFirestore.instance
        .collection('users')
        .doc(giftListOwnerId)
        .collection('gifts')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Gift.fromFirestore(doc))
            .toList());

    _giftsStream?.listen(
      (gifts) {
        _gifts = gifts;
        _updateGiftsByCategory();
        notifyListeners();
      },
      onError: (error) {
        _error = error.toString();
        notifyListeners();
      },
    );
  }

  void _updateGiftsByCategory() {
    _giftsByCategory = {};
    for (var gift in _gifts) {
      final category = gift.category ?? 'Uncategorized';
      if (!_giftsByCategory.containsKey(category)) {
        _giftsByCategory[category] = [];
      }
      _giftsByCategory[category]!.add(gift);
    }
  }

  bool canTogglePurchasedStatus(Gift gift) {
    if (isOwner) return false; // Owner can't mark their own gifts as purchased
    return gift.purchasedBy == null || gift.purchasedBy == currentUserId;
  }

  Future<void> toggleGiftPurchased(Gift gift) async {
    if (!canTogglePurchasedStatus(gift)) return;

    try {
      final updatedGift = gift.copyWith(
        purchasedBy: gift.purchasedBy == null ? currentUserId : null,
        purchased: !gift.purchased,
      );

      await giftService.updateGift(
        giftListOwnerId,
        gift.id,
        updatedGift.toFirestore(),
      );
    } catch (e) {
      _error = 'Failed to update gift: $e';
      notifyListeners();
    }
  }

  Future<void> deleteGift(Gift gift) async {
    if (!isOwner) return;

    try {
      await giftService.deleteGift(giftListOwnerId, gift.id);
    } catch (e) {
      _error = 'Failed to delete gift: $e';
      notifyListeners();
    }
  }
}
