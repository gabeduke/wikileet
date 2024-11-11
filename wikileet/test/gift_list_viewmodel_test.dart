// test/viewmodels/gift_list_viewmodel_test.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:wikileet/viewmodels/gift_list_viewmodel.dart';
import 'package:wikileet/models/gift.dart';
import 'package:wikileet/services/gift_service.dart';

// Mock GiftService class
class MockGiftService extends Mock implements GiftService {}

void main() {
  group('GiftListViewModel Tests', () {
    late MockGiftService mockGiftService;
    late GiftListViewModel viewModel;
    const String ownerId = 'owner123';
    const String familyMemberId = 'family456';

    setUp(() {
      mockGiftService = MockGiftService();
      viewModel = GiftListViewModel(giftService: mockGiftService, userId: ownerId);
    });

    test('should initialize with owner status and load gifts', () async {
      // Set up mock data
      final gifts = [
        Gift(
          id: 'gift1',
          name: 'Test Gift',
          description: 'Description',
          visibility: true,
          purchased: false,
          createdAt: Timestamp.now(),
        ),
      ];
      when(mockGiftService.isOwner(ownerId)).thenReturn(true);
      when(mockGiftService.getGiftList(ownerId)).thenAnswer((_) async => gifts);

      // Initialize ViewModel
      await viewModel.initialize();

      // Verify that ViewModel loads data correctly
      expect(viewModel.isOwner, isTrue);
      expect(viewModel.gifts, equals(gifts));
    });

    test('should allow marking a gift as purchased for family member', () async {
      // Set up mock data
      final gift = Gift(
        id: 'gift1',
        name: 'Test Gift',
        description: 'Description',
        visibility: true,
        purchased: false,
        createdAt: Timestamp.now(),
      );
      when(mockGiftService.isOwner(familyMemberId)).thenReturn(false);
      when(mockGiftService.canMarkAsPurchased(ownerId, gift.purchasedBy)).thenReturn(true);
      when(mockGiftService.getGiftList(ownerId)).thenAnswer((_) async => [gift]);

      // Update ViewModel to simulate family member viewing
      viewModel = GiftListViewModel(giftService: mockGiftService, userId: familyMemberId);

      await viewModel.markAsPurchased(gift);

      // Verify that the gift is marked as purchased
      verify(mockGiftService.updateGift(ownerId, gift.id, {'purchasedBy': familyMemberId})).called(1);
    });

    test('should prevent family member from deleting a gift', () async {
      // Set up mock data
      final gift = Gift(
        id: 'gift1',
        name: 'Test Gift',
        description: 'Description',
        visibility: true,
        purchased: false,
        createdAt: Timestamp.now(),
      );
      when(mockGiftService.isOwner(familyMemberId)).thenReturn(false);
      when(mockGiftService.getGiftList(ownerId)).thenAnswer((_) async => [gift]);

      // Update ViewModel to simulate family member viewing
      viewModel = GiftListViewModel(giftService: mockGiftService, userId: familyMemberId);

      // Attempt to delete as family member, which should not happen
      await viewModel.deleteGift(gift);

      // Verify that deleteGift was not called on the mock service
      verifyNever(mockGiftService.deleteGift(ownerId, gift.id));
    });

    test('should allow owner to edit and delete gifts', () async {
      // Set up mock data
      final gift = Gift(
        id: 'gift1',
        name: 'Test Gift',
        description: 'Description',
        visibility: true,
        purchased: false,
        createdAt: Timestamp.now(),
      );
      when(mockGiftService.isOwner(ownerId)).thenReturn(true);
      when(mockGiftService.getGiftList(ownerId)).thenAnswer((_) async => [gift]);

      // Initialize ViewModel for the owner
      await viewModel.initialize();

      // Owner attempts to delete the gift
      await viewModel.deleteGift(gift);

      // Verify that deleteGift was called on the mock service
      verify(mockGiftService.deleteGift(ownerId, gift.id)).called(1);
    });
  });
}
