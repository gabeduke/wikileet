import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wikileet/viewmodels/family_viewmodel.dart';
import '../providers/user_provider.dart';
import '../models/house.dart';

class FamilyListScreen extends StatefulWidget {
  @override
  _FamilyListScreenState createState() => _FamilyListScreenState();
}

class _FamilyListScreenState extends State<FamilyListScreen> {
  @override
  void initState() {
    super.initState();
    Provider.of<FamilyViewModel>(context, listen: false).getFamilyGroups();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        child: Consumer<FamilyViewModel>(
          builder: (context, familyViewModel, child) {
            if (familyViewModel.isLoading) {
              return Center(child: CircularProgressIndicator());
            }

            if (familyViewModel.errorMessage != null) {
              return Center(child: Text(familyViewModel.errorMessage!));
            }

            if (familyViewModel.familyGroups.isEmpty) {
              return Center(child: Text('No family groups found.'));
            }

            final userId =
                Provider.of<UserProvider>(context, listen: false).userId;

            return ListView(
              children: familyViewModel.familyGroups.map((family) {
                final hasHouses = family.houses.isNotEmpty;

                return ExpansionTile(
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        family.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: hasHouses
                              ? Colors.black
                              : Colors.grey, // Grey out if no houses
                        ),
                      ),
                      ElevatedButton(
                        onPressed: hasHouses
                            ? () async {
                                await familyViewModel.addMemberToFamily(
                                    family.id, userId!);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          "Added to family: ${family.name}")),
                                );
                              }
                            : null, // Disable button if no houses
                        child: Text('Join Family'),
                      ),
                    ],
                  ),
                  initiallyExpanded: true,
                  children: hasHouses
                      ? family.houses
                          .map((house) => _buildHouseTile(
                              context, family.id, house, userId!))
                          .toList()
                      : [
                          ListTile(
                            title: Text(
                              'No houses found in this family group.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        ],
                );
              }).toList(),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHouseTile(
      BuildContext context, String familyGroupId, House house, String userId) {
    return ExpansionTile(
      title: Text(house.name, style: TextStyle(color: Colors.blueAccent)),
      children: house.members.isNotEmpty
          ? house.members
          .map((member) => ListTile(
        title: Text(member),
      ))
          .toList()
          : [
        ListTile(
          title: Text('No members found in this house.'),
        ),
      ],
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton(
            onPressed: () async {
              await Provider.of<FamilyViewModel>(context, listen: false)
                  .addMemberToHouse(familyGroupId, house.id, userId);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Added to house: ${house.name}")),
              );
            },
            child: Text('Join House'),
          ),
          // Add arrow indicator only if there are members in the house
          if (house.members.isNotEmpty)
            Icon(Icons.expand_more), // Arrow icon for expansion
        ],
      ),
    );
  }
}
