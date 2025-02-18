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
                    IconButton(
                      icon: const Icon(Icons.add_home),
                      tooltip: 'Create House',
                      onPressed: () => _showCreateHouseDialog(context, family.id),
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

  Future<void> _showCreateHouseDialog(BuildContext context, String familyGroupId) async {
    final nameController = TextEditingController();
    
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create House'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Create a new house in your family group',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'House Name',
                hintText: 'Enter the house name',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a house name')),
                );
                return;
              }

              try {
                final familyViewModel = Provider.of<FamilyViewModel>(context, listen: false);
                await familyViewModel.addHouse(familyGroupId, nameController.text.trim());
                
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('House created successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to create house: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Widget _buildHouseTile(
      BuildContext context, String familyGroupId, House house, String userId) {
    return Consumer<FamilyViewModel>(
      builder: (context, familyViewModel, child) {
        final isCurrentHouse = house.id == familyViewModel.houseId;
        return ExpansionTile(
          title: Row(
            children: [
              Text(
                house.name,
                style: TextStyle(
                  color: Colors.blueAccent,
                  fontWeight: isCurrentHouse ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              if (isCurrentHouse) ...[
                const SizedBox(width: 8),
                const Icon(Icons.check_circle, color: Colors.green, size: 16),
              ],
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_showJoinButtons && !isCurrentHouse)
                ElevatedButton(
                  onPressed: () async {
                    // Show loading indicator
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Changing house..."),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    }

                    try {
                      await familyViewModel.selectFamilyAndHouse(
                          familyGroupId, house.id, userId);
                      
                      if (context.mounted) {
                        // Hide the join buttons after successful change
                        setState(() {
                          _showJoinButtons = false;
                        });
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Changed to house: ${house.name}"),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Failed to change house: $e"),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('Join House'),
                ),
              if (house.memberIds.isNotEmpty) const Icon(Icons.expand_more),
            ],
          ),
          children: house.memberIds.isEmpty
              ? [
                  const ListTile(
                    title: Text('No members found in this house.'),
                  ),
                ]
              : house.memberIds.map((memberId) => FutureBuilder(
                    future: familyViewModel.getUserProfile(memberId),
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data != null) {
                        final member = snapshot.data!;
                        return ListTile(
                          title: Text(member.displayName),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => GiftListScreen(
                                  userId: member.uid,
                                  isCurrentUser: member.uid == userId,
                                ),
                              ),
                            );
                          },
                        );
                      }
                      return const ListTile(
                        title: Text('Loading member...'),
                      );
                    },
                  )).toList(),
        );
      },
    );
  }
}
