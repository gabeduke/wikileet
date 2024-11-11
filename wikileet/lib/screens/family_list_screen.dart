import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wikileet/viewmodels/family_viewmodel.dart';

class FamilyListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<FamilyViewModel>(
      builder: (context, familyViewModel, child) {
        if (familyViewModel.familyId == null) {
          return Center(child: Text("No family found."));
        }
        return ListView.builder(
          itemCount: familyViewModel.familyMembers.length,
          itemBuilder: (context, index) {
            return ListTile(
              title: Text(familyViewModel.familyMembers[index]),
            );
          },
        );
      },
    );
  }
}
