// gift_list_viewmodel.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:wikileet/models/gift.dart';
import 'package:wikileet/services/gift_service.dart';

class GiftListViewModel extends ChangeNotifier {
  final GiftService giftService;
  final String giftListOwnerId;
  final String currentUserId;

  List<Gift> _gifts = [];
  bool isOwner = false;

  GiftListViewModel({
    required this.giftService,
    required this.giftListOwnerId,
    required this.currentUserId,
  }) {
    initialize();
  }

  List<Gift> get gifts => _gifts;

  Map<String, List<Gift>> giftsByCategory = {};

  StreamSubscription<List<Gift>>? _giftsSubscription;

  void initialize() {
    isOwner = currentUserId == giftListOwnerId;

    // Listen to the gifts stream
    _giftsSubscription = giftService.getGiftListStream(giftListOwnerId).listen((giftList) {
      _gifts = giftList;

      // Organize gifts by category
      giftsByCategory = {};
      for (var gift in _gifts) {
        final category = gift.category ?? 'Uncategorized';
        if (!giftsByCategory.containsKey(category)) {
          giftsByCategory[category] = [];
        }
        giftsByCategory[category]!.add(gift);
      }

      notifyListeners();
    });
  }

  bool canTogglePurchasedStatus(Gift gift) {
    // Users can toggle if they are the ones who marked it or if it's unpurchased
    return !isOwner && (gift.purchasedBy == null || gift.purchasedBy == currentUserId);
  }

  Future<void> togglePurchasedStatus(Gift gift) async {
    final isPurchasedByCurrentUser = gift.purchasedBy == currentUserId;

    await giftService.updateGift(giftListOwnerId, gift.id, {
      'purchasedBy': isPurchasedByCurrentUser ? null : currentUserId,
    });
  }

  bool canMarkAsPurchased(Gift gift) {
    return !isOwner && gift.purchasedBy == null;
  }

  Future<void> markAsPurchased(Gift gift) async {
    if (canMarkAsPurchased(gift)) {
      await giftService.updateGift(giftListOwnerId, gift.id, {
        'purchasedBy': currentUserId,
      });
    }
  }

  Future<void> deleteGift(Gift gift) async {
    if (isOwner) {
      await giftService.deleteGift(giftListOwnerId, gift.id);
    }
  }

  @override
  void dispose() {
    _giftsSubscription?.cancel(); // Cancel the subscription when disposed
    super.dispose();
  }
}
