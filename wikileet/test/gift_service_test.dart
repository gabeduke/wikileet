// test/services/gift_service_test.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:wikileet/services/gift_service.dart';
import 'package:wikileet/models/gift.dart';

void main() {
  late GiftService giftService;
  late FakeFirebaseFirestore fakeFirestore;

  setUpAll(() async {
    fakeFirestore = FakeFirebaseFirestore();
    giftService = GiftService(firestore: fakeFirestore);
  });

  group('GiftService Tests', () {
    final gift = Gift(
      id: 'gift1',
      name: 'Sample Gift',
      description: 'A wonderful gift',
      price: 29.99,
      link: 'http://example.com',
      reservedBy: null,
      visibility: true,
      purchased: false,
      createdAt: Timestamp.now(),
    );

    test('Add and retrieve gift', () async {
      await giftService.addGift('user1', gift);
      final fetchedGift = await giftService.getGift('user1', 'gift1');

      expect(fetchedGift, isNotNull);
      expect(fetchedGift!.name, 'Sample Gift');
      expect(fetchedGift.description, 'A wonderful gift');
    });

    test('Update gift visibility', () async {
      await fakeFirestore
          .collection('users')
          .doc('user1')
          .collection('gifts')
          .doc('gift1')
          .set(gift.toFirestore());

      await giftService.updateGift('user1', 'gift1', {'visibility': false});
      final updatedGift = await giftService.getGift('user1', 'gift1');

      expect(updatedGift, isNotNull);
      expect(updatedGift!.visibility, false);
    });

    test('Delete gift', () async {
      await fakeFirestore
          .collection('users')
          .doc('user1')
          .collection('gifts')
          .doc('gift1')
          .set(gift.toFirestore());

      await giftService.deleteGift('user1', 'gift1');
      final deletedGift = await giftService.getGift('user1', 'gift1');

      expect(deletedGift, isNull);
    });
  });
}
