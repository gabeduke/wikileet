// lib/screens/family_list_screen.dart

import 'package:flutter/material.dart';
import 'package:wikileet/models/family_member.dart';
import 'package:wikileet/services/family_service.dart';
import 'package:wikileet/screens/gift_list_screen.dart';

class FamilyListScreen extends StatelessWidget {
  final String userId;
  final FamilyService familyService;

  FamilyListScreen({required this.userId, FamilyService? familyService})
      : familyService = familyService ?? FamilyService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Family Members'),
      ),
      body: FutureBuilder<List<FamilyMember>>(
        future: familyService.getFamilyMembers(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No family members found.'));
          }

          final familyMembers = snapshot.data!;
          return ListView.builder(
            itemCount: familyMembers.length,
            itemBuilder: (context, index) {
              final member = familyMembers[index];
              return ListTile(
                title: Text(member.displayName),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => GiftListScreen(userId: member.id),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
