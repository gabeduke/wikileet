import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wikileet/viewmodels/family_viewmodel.dart';
import 'package:wikileet/screens/gift_list_screen.dart';

import '../models/house.dart';
import 'family_selection_screen.dart';

class FamilyListScreen extends StatefulWidget {
  @override
  _FamilyListScreenState createState() => _FamilyListScreenState();
}

class _FamilyListScreenState extends State<FamilyListScreen> {
  @override
  void initState() {
    super.initState();
    // Trigger data loading in initState
    Provider.of<FamilyViewModel>(context, listen: false).getFamilyGroups();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FamilyViewModel>(
      builder: (context, familyViewModel, child) {
        // Display loading indicator
        if (familyViewModel.isLoading) {
          return Center(child: CircularProgressIndicator());
        }

        // Display error message
        if (familyViewModel.errorMessage != null) {
          return Center(child: Text(familyViewModel.errorMessage!));
        }

        // Display message if no family groups are found
        if (familyViewModel.familyGroups.isEmpty) {
          return Center(child: Text('No family groups found.'));
        }

        // Render family groups and houses
        return ListView(
          children: familyViewModel.familyGroups.map((family) => ExpansionTile(
            title: Text(family.name, style: TextStyle(fontWeight: FontWeight.bold)),
            children: family.houses.isNotEmpty
                ? family.houses.map((house) => _buildHouseTile(context, family.id, house)).toList()
                : [ListTile(title: Text('No houses found in this family group.'))],
          )).toList(),
        );
      },
    );
  }

  Widget _buildHouseTile(BuildContext context, String familyGroupId, House house) {
    return ExpansionTile(
      title: Text(house.name, style: TextStyle(color: Colors.blueAccent)),
      children: [
        if (house.members.isNotEmpty)
          ...house.members.map((member) => _buildMemberTile(context, familyGroupId, house.id, member))
        else
          ListTile(
            title: Text('No members found in this house.'),
          ),
      ],
    );
  }

  Widget _buildMemberTile(BuildContext context, String familyGroupId, String houseId, String member) {
    return ListTile(
      title: Text(member),
      trailing: IconButton(
        icon: Icon(Icons.edit, color: Colors.grey),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => FamilySelectionScreen(userId: member),
            ),
          );
        },
      ),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => GiftListScreen(userId: member),
          ),
        );
      },
    );
  }
}
