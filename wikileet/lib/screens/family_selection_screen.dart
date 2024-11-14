// lib/screens/family_selection_screen.dart

import 'package:flutter/material.dart';
import 'package:wikileet/services/family_service.dart';
import 'package:wikileet/models/family_group.dart';
import 'package:wikileet/models/house.dart';
import 'main_navigation_screen.dart';

class FamilySelectionScreen extends StatefulWidget {
  final String userId;

  FamilySelectionScreen({required this.userId});

  @override
  _FamilySelectionScreenState createState() => _FamilySelectionScreenState();
}

class _FamilySelectionScreenState extends State<FamilySelectionScreen> {
  final FamilyService _familyService = FamilyService();

  List<FamilyGroup> _familyGroups = [];
  String? _selectedFamilyGroupId;

  List<House> _houses = [];
  String? _selectedHouseId;

  @override
  void initState() {
    super.initState();
    _loadFamilyGroups();
  }

  Future<void> _loadFamilyGroups() async {
    _familyGroups = await _familyService.getAllFamilyGroups();
    setState(() {});
  }

  Future<void> _loadHouses(String familyGroupId) async {
    _houses = await _familyService.getHousesForFamilyGroup(familyGroupId);
    setState(() {});
  }

  /// Join the selected family group and house, ensuring bidirectional updates.
  Future<void> _joinFamilyGroup() async {
    if (_selectedFamilyGroupId == null) return;

    // Add the user to the selected family group and house (if chosen)
    await _familyService.addMemberToFamilyGroup(_selectedFamilyGroupId!, widget.userId);
    if (_selectedHouseId != null) {
      await _familyService.addMemberToHouse(_selectedFamilyGroupId!, _selectedHouseId!, widget.userId);
    }

    // Navigate to main screen
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => MainNavigationScreen()),
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
        title: Text('Select Your Family'),
      ),
      body: Column(
        children: [
          Text('Select Family Group'),
          Expanded(
            child: ListView.builder(
              itemCount: _familyGroups.length,
              itemBuilder: (context, index) {
                final family = _familyGroups[index];
                return RadioListTile<String>(
                  title: Text(family.name),
                  value: family.id,
                  groupValue: _selectedFamilyGroupId,
                  onChanged: _onFamilyGroupSelected,
                );
              },
            ),
          ),
          if (_houses.isNotEmpty) ...[
            Text('Select Your House'),
            Expanded(
              child: ListView.builder(
                itemCount: _houses.length,
                itemBuilder: (context, index) {
                  final house = _houses[index];
                  return RadioListTile<String>(
                    title: Text(house.name),
                    value: house.id,
                    groupValue: _selectedHouseId,
                    onChanged: (value) {
                      setState(() {
                        _selectedHouseId = value;
                      });
                    },
                  );
                },
              ),
            ),
          ],
          ElevatedButton(
            onPressed: _joinFamilyGroup,
            child: Text('Join'),
          ),
        ],
      ),
    );
  }
}
