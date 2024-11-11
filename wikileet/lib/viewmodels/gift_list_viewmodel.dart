// lib/viewmodels/gift_list_viewmodel.dart

import 'package:flutter/material.dart';
import 'package:wikileet/models/gift.dart';
import 'package:wikileet/services/gift_service.dart';

class GiftListViewModel extends ChangeNotifier {
  final GiftService giftService;
  final String userId;
  List<Gift> _gifts = [];
  bool isOwner = false;

  GiftListViewModel({required this.giftService, required this.userId}) {
    initialize();
  }

  List<Gift> get gifts => _gifts;

  Future<void> initialize() async {
    isOwner = giftService.isOwner(userId);
    _gifts = await giftService.getGiftList(userId);
    notifyListeners();
  }

  bool canMarkAsPurchased(Gift gift) {
    return giftService.canMarkAsPurchased(userId, gift.purchasedBy);
  }

  Future<void> markAsPurchased(Gift gift) async {
    if (canMarkAsPurchased(gift)) {
      await giftService.updateGift(userId, gift.id, {
        'purchasedBy': giftService.currentUser?.uid, // Updated to use giftService.currentUser
      });
      initialize(); // Reload after marking as purchased
    }
  }

  Future<void> deleteGift(Gift gift) async {
    await giftService.deleteGift(userId, gift.id);
    initialize(); // Reload after deletion
  }
}
