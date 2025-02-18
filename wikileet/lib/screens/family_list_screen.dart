import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wikileet/viewmodels/family_viewmodel.dart';
import '../providers/user_provider.dart';
import '../models/house.dart';
import 'gift_list_screen.dart';

class FamilyListScreen extends StatefulWidget {
  const FamilyListScreen({super.key});

  @override
  _FamilyListScreenState createState() => _FamilyListScreenState();
}

class _FamilyListScreenState extends State<FamilyListScreen> {
  bool _showJoinButtons = false; // Controls visibility of "Join House" buttons

  @override
  void initState() {
    super.initState();
    final userId = Provider.of<UserProvider>(context, listen: false).userId;
    Future.microtask(() => Provider.of<FamilyViewModel>(context, listen: false)
        .getUserFamilyGroup(userId!));
  }

  @override
  Widget build(BuildContext context) {
    final userId = Provider.of<UserProvider>(context, listen: false).userId;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Family List"),
      ),
      body: Consumer<FamilyViewModel>(
        builder: (context, familyViewModel, child) {
          if (familyViewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (familyViewModel.errorMessage != null) {
            return Center(child: Text(familyViewModel.errorMessage!));
          }

          if (familyViewModel.familyGroups.isEmpty) {
            return const Center(child: Text('No family groups found.'));
          }

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
                        color: hasHouses ? Colors.black : Colors.grey,
                      ),
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
                  const ListTile(
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
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: () {
            setState(() {
              _showJoinButtons = !_showJoinButtons;
            });
          },
          child: Text(_showJoinButtons ? 'Cancel' : 'Change House'),
        ),
      ),
    );
  }

  Widget _buildHouseTile(
      BuildContext context, String familyGroupId, House house, String userId) {
    return Consumer<FamilyViewModel>(
      builder: (context, familyViewModel, child) {
        return ExpansionTile(
          title: Text(house.name, style: const TextStyle(color: Colors.blueAccent)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_showJoinButtons)
                ElevatedButton(
                  onPressed: () async {
                    await familyViewModel.selectFamilyAndHouse(
                        familyGroupId, house.id, userId);

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text("Added to house: ${house.name}")),
                      );
                    }
                  },
                  child: const Text('Join House'),
                ),
              if (house.members.isNotEmpty) const Icon(Icons.expand_more),
            ],
          ),
          children: house.members.isNotEmpty
              ? house.members
              .map((username) => ListTile(
            title: Text(username),
            onTap: () {
              final selectedUserId = familyViewModel.getUserIdByUsername(username);
              if (selectedUserId != null) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => GiftListScreen(
                      userId: selectedUserId,
                      isCurrentUser: selectedUserId == userId,
                    ),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("User ID not found for $username")),
                );
              }
            },
          ))
              .toList()
              : [
            const ListTile(
              title: Text('No members found in this house.'),
            ),
          ],
        );
      },
    );
  }
}
