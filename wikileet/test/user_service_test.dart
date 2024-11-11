// test/services/user_service_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:wikileet/services/user_service.dart';
import 'package:wikileet/models/user.dart';

void main() {
  late UserService userService;
  late FakeFirebaseFirestore fakeFirestore;

  setUpAll(() async {
    fakeFirestore = FakeFirebaseFirestore();
    userService = UserService(firestore: fakeFirestore); // Only inject Firestore
  });

  group('UserService Tests', () {
    test('Add and retrieve user', () async {
      final user = User(
        uid: '123',
        displayName: 'Test User',
        email: 'test@example.com',
        familyGroupId: 'group1',
        profilePicUrl: 'http://example.com/profile.jpg',
      );

      await userService.addUser(user);

      final fetchedUser = await userService.getUser('123');

      expect(fetchedUser, isNotNull);
      expect(fetchedUser!.uid, '123');
      expect(fetchedUser.displayName, 'Test User');
      expect(fetchedUser.email, 'test@example.com');
      expect(fetchedUser.familyGroupId, 'group1');
      expect(fetchedUser.profilePicUrl, 'http://example.com/profile.jpg');
    });

    test('Update user data', () async {
      await fakeFirestore.collection('users').doc('123').set({
        'displayName': 'Test User',
        'email': 'test@example.com',
        'familyGroupId': 'group1',
        'profilePicUrl': 'http://example.com/profile.jpg',
      });

      await userService.updateUser('123', {'displayName': 'Updated User'});

      final updatedUser = await userService.getUser('123');

      expect(updatedUser, isNotNull);
      expect(updatedUser!.displayName, 'Updated User');
    });

    test('Delete user', () async {
      await fakeFirestore.collection('users').doc('123').set({
        'displayName': 'Test User',
        'email': 'test@example.com',
        'familyGroupId': 'group1',
        'profilePicUrl': 'http://example.com/profile.jpg',
      });

      await userService.deleteUser('123');

      final deletedUser = await userService.getUser('123');
      expect(deletedUser, isNull);
    });
  });
}
