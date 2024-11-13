// lib/screens/family_list_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wikileet/viewmodels/family_viewmodel.dart';
import 'package:wikileet/screens/gift_list_screen.dart';

class FamilyListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<FamilyViewModel>(
      builder: (context, familyViewModel, child) {
        if (familyViewModel.isLoading) {
          // Show loading indicator while data is being fetched
          return Center(child: CircularProgressIndicator());
        } else if (familyViewModel.errorMessage != null) {
          // Display error message if any
          return Center(child: Text(familyViewModel.errorMessage!));
        } else if (familyViewModel.familyId == null) {
          // No family found
          return Center(child: Text("No family found."));
        } else if (familyViewModel.familyMembers.isEmpty) {
          // No family members in the family
          return Center(child: Text("No family members found."));
        } else {
          // Display the list of family members
          return ListView.builder(
            itemCount: familyViewModel.familyMembers.length,
            itemBuilder: (context, index) {
              final familyMember = familyViewModel.familyMembers[index];
              return ListTile(
                title: Text(familyMember.displayName),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => GiftListScreen(userId: familyMember.uid),
                    ),
                  );
                },
              );
            },
          );
        }
      },
    );
  }
}
