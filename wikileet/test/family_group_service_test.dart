// test/services/family_group_service_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:wikileet/services/family_group_service.dart';
import 'package:wikileet/models/family_group.dart';

void main() {
  late FamilyGroupService familyGroupService;
  late FakeFirebaseFirestore fakeFirestore;

  setUpAll(() async {
    fakeFirestore = FakeFirebaseFirestore();
    familyGroupService = FamilyGroupService(firestore: fakeFirestore);
  });

  group('FamilyGroupService Tests', () {
    test('Add and retrieve family group', () async {
      final familyGroup = FamilyGroup(
        id: 'group1',
        name: 'Test Family',
        members: ['user1', 'user2'],
      );

      await familyGroupService.addFamilyGroup(familyGroup);
      final fetchedGroup = await familyGroupService.getFamilyGroup('group1');

      expect(fetchedGroup, isNotNull);
      expect(fetchedGroup!.id, 'group1');
      expect(fetchedGroup.name, 'Test Family');
      expect(fetchedGroup.members, containsAll(['user1', 'user2']));
    });

    test('Update family group name', () async {
      await fakeFirestore.collection('familyGroups').doc('group1').set({
        'name': 'Test Family',
        'members': ['user1', 'user2'],
      });

      await familyGroupService.updateFamilyGroup('group1', {'name': 'Updated Family'});
      final updatedGroup = await familyGroupService.getFamilyGroup('group1');

      expect(updatedGroup, isNotNull);
      expect(updatedGroup!.name, 'Updated Family');
    });

    test('Delete family group', () async {
      await fakeFirestore.collection('familyGroups').doc('group1').set({
        'name': 'Test Family',
        'members': ['user1', 'user2'],
      });

      await familyGroupService.deleteFamilyGroup('group1');
      final deletedGroup = await familyGroupService.getFamilyGroup('group1');

      expect(deletedGroup, isNull);
    });
  });
}
