// test/models/user_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:wikileet/models/user.dart';

void main() {
  group('User Model Tests', () {
    final fakeFirestore = FakeFirebaseFirestore();

    test('User serialization to Firestore JSON', () {
      final user = User(
        uid: '123',
        displayName: 'Test User',
        email: 'test@example.com',
        familyGroupId: 'group1',
        profilePicUrl: 'http://example.com/profile.jpg',
      );

      final firestoreData = user.toFirestore();
      expect(firestoreData['displayName'], 'Test User');
      expect(firestoreData['email'], 'test@example.com');
      expect(firestoreData['familyGroupId'], 'group1');
      expect(firestoreData['profilePicUrl'], 'http://example.com/profile.jpg');
    });

    test('User deserialization from Firestore document', () async {
      // Add a mock user document to FakeFirestore
      await fakeFirestore.collection('users').doc('123').set({
        'displayName': 'Test User',
        'email': 'test@example.com',
        'familyGroupId': 'group1',
        'profilePicUrl': 'http://example.com/profile.jpg',
      });

      // Retrieve the mock document and deserialize it
      final snapshot = await fakeFirestore.collection('users').doc('123').get();
      final user = User.fromFirestore(snapshot);

      expect(user.uid, '123');
      expect(user.displayName, 'Test User');
      expect(user.email, 'test@example.com');
      expect(user.familyGroupId, 'group1');
      expect(user.profilePicUrl, 'http://example.com/profile.jpg');
    });
  });
}
