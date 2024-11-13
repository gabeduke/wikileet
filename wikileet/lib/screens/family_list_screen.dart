// lib/screens/family_list_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wikileet/viewmodels/family_viewmodel.dart';
import 'package:wikileet/screens/gift_list_screen.dart';
import 'package:wikileet/services/navigation_service.dart'; // Import NavigationService
import 'package:wikileet/models/user.dart';

class FamilyListScreen extends StatefulWidget {
  @override
  _FamilyListScreenState createState() => _FamilyListScreenState();
}

class _FamilyListScreenState extends State<FamilyListScreen> {
  final NavigationService _navigationService = NavigationService(); // Initialize NavigationService

  @override
  void initState() {
    super.initState();
    print("FamilyListScreen initState called");
    _checkFamilyGroup();
  }

  Future<void> _checkFamilyGroup() async {
    print("Inside _checkFamilyGroup method"); // Add this log

    // Get the current user ID from the provider, Firebase, or other source
    final userId = Provider.of<FamilyViewModel>(context, listen: false).currentUserId;

    if (userId != null) {
      print("Running family group check for user ID: $userId");
      await _navigationService.checkFamilyGroupAndNavigate(userId);
    }
  }

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
