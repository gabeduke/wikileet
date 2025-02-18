// lib/screens/family_selection_screen.dart

import 'package:flutter/material.dart';
import 'package:wikileet/services/family_service.dart';
import 'package:wikileet/models/family_group.dart';
import 'package:wikileet/models/house.dart';
import 'main_navigation_screen.dart';
import 'package:provider/provider.dart';
import 'package:wikileet/providers/user_provider.dart';

class FamilySelectionScreen extends StatefulWidget {
  final String userId;

  const FamilySelectionScreen({super.key, required this.userId});

  @override
  _FamilySelectionScreenState createState() => _FamilySelectionScreenState();
}

class _FamilySelectionScreenState extends State<FamilySelectionScreen> {
  final FamilyService _familyService = FamilyService();

  List<FamilyGroup> _familyGroups = [];
  String? _selectedFamilyGroupId;

  List<House> _houses = [];
  String? _selectedHouseId;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFamilyGroups();
  }

  Future<void> _loadFamilyGroups() async {
    try {
      setState(() {
        _error = null;
        _familyGroups = []; // Clear existing data while loading
      });
      
      print('Starting to load family groups...'); // Debug print
      final groups = await _familyService.getAllFamilyGroups();
      print('Loaded ${groups.length} family groups'); // Debug print
      
      if (mounted) {
        setState(() {
          _familyGroups = groups;
          if (groups.isEmpty) {
            _error = 'No family groups found. Create one using the + button.';
          }
        });
      }
    } catch (e) {
      print('Error loading family groups: $e'); // Debug print
      if (mounted) {
        setState(() => _error = 'Failed to load family groups: $e');
      }
    }
  }

  Future<void> _loadHouses(String familyGroupId) async {
    try {
      setState(() => _error = null);
      _houses = await _familyService.getHousesForFamilyGroup(familyGroupId);
      print('Loaded ${_houses.length} houses'); // Debug print
      if (_houses.isEmpty) {
        setState(() => _error = 'No houses found for this family group.');
      } else {
        setState(() {});
      }
    } catch (e) {
      print('Error loading houses: $e'); // Debug print
      setState(() => _error = 'Failed to load houses: $e');
    }
  }

  /// Join the selected family group and house, ensuring bidirectional updates.
  Future<void> _joinFamilyGroup() async {
    if (_selectedFamilyGroupId == null) return;

    try {
      // Add the user to the selected family group and house (if chosen)
      await _familyService.addMemberToFamilyGroup(
          _selectedFamilyGroupId!, widget.userId);

      if (_selectedHouseId != null) {
        await _familyService.addMemberToHouse(
            _selectedFamilyGroupId!, _selectedHouseId!, widget.userId);
        
        // Update the UserProvider state
        if (mounted) {
          final userProvider = Provider.of<UserProvider>(context, listen: false);
          userProvider.setFamilyGroupId(_selectedFamilyGroupId!);
          userProvider.setHouseId(_selectedHouseId!);
        }
      }

      // Navigate to main screen
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => MainNavigationScreen()),
        );
      }
    } catch (e) {
      print('Error joining family group: $e'); // Debug print
      setState(() => _error = 'Failed to join family group: $e');
    }
  }

  Future<void> _showAddFamilyGroupDialog() async {
    final nameController = TextEditingController();
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Create Family Group'),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(hintText: "Enter family group name"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                try {
                  await _familyService.addFamilyGroup(nameController.text);
                  if (mounted) {
                    Navigator.pop(context);
                    _loadFamilyGroups(); // Reload the list
                  }
                } catch (e) {
                  setState(() => _error = 'Failed to create family group: $e');
                }
              }
            },
            child: Text('Create'),
          ),
        ],
      ),
    );
  }

  void _onFamilyGroupSelected(String? familyGroupId) {
    setState(() {
      _selectedFamilyGroupId = familyGroupId;
      _selectedHouseId = null;
      _houses = [];
    });
    if (familyGroupId != null) {
      _loadHouses(familyGroupId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Your Family'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadFamilyGroups,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Family Groups',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _showAddFamilyGroupDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Create Family'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  color: Colors.red.shade100,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text(_error!, style: TextStyle(color: Colors.red)),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: _loadFamilyGroups,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            Expanded(
              child: _familyGroups.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.family_restroom, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          'No Family Groups Found',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Create a new family group to get started',
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _showAddFamilyGroupDialog,
                          icon: const Icon(Icons.add_circle),
                          label: const Text('Create New Family Group'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Card(
                        child: Column(
                          children: _familyGroups.map((family) =>
                            RadioListTile<String>(
                              title: Text(family.name),
                              subtitle: Text('Members: ${family.members.length}'),
                              value: family.id,
                              groupValue: _selectedFamilyGroupId,
                              onChanged: _onFamilyGroupSelected,
                            ),
                          ).toList(),
                        ),
                      ),
                      if (_houses.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        const Text(
                          'Select Your House',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Card(
                          child: Column(
                            children: _houses.map((house) =>
                              RadioListTile<String>(
                                title: Text(house.name),
                                subtitle: Text('Members: ${house.memberIds.length}'),
                                value: house.id,
                                groupValue: _selectedHouseId,
                                onChanged: (value) {
                                  setState(() {
                                    _selectedHouseId = value;
                                  });
                                },
                              ),
                            ).toList(),
                          ),
                        ),
                      ],
                      if (_selectedFamilyGroupId != null) ...[
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _joinFamilyGroup,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.all(16),
                          ),
                          child: const Text('Join Family'),
                        ),
                      ],
                    ],
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
