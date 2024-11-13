// lib/screens/family_list_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wikileet/viewmodels/family_viewmodel.dart';
import 'package:wikileet/screens/gift_list_screen.dart';

import 'package:wikileet/models/user.dart';

class FamilyListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<FamilyViewModel>(
      builder: (context, familyViewModel, child) {
        if (familyViewModel.isLoading) {
          return Center(child: CircularProgressIndicator());
        } else if (familyViewModel.errorMessage != null) {
          return Center(child: Text(familyViewModel.errorMessage!));
        }

        return ListView(
          children: [
            if (familyViewModel.houseMembers.isNotEmpty) ...[
              ListTile(
                title: Text('My House'),
                tileColor: Colors.grey[300],
              ),
              ...familyViewModel.houseMembers.map((member) => _buildMemberTile(context, member)),
            ],
            if (familyViewModel.familyMembers.isNotEmpty) ...[
              ListTile(
                title: Text('My Family'),
                tileColor: Colors.grey[300],
              ),
              ...familyViewModel.familyMembers.map((member) => _buildMemberTile(context, member)),
            ],
          ],
        );
      },
    );
  }

  Widget _buildMemberTile(BuildContext context, User member) {
    return ListTile(
      title: Text(member.displayName),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => GiftListScreen(userId: member.uid),
          ),
        );
      },
    );
  }
}
