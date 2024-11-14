import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:wikileet/screens/admin.dart';
import 'package:wikileet/screens/family_list_screen.dart';
import 'package:wikileet/screens/gift_list_screen.dart';
import 'package:wikileet/viewmodels/family_viewmodel.dart';

import '../providers/user_provider.dart';
import '../services/auth_service.dart';

class MainNavigationScreen extends StatefulWidget {
  @override
  _MainNavigationScreenState createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;
  final AuthService _authService = AuthService();

  bool _isAdmin = false;
  List<Widget> _screens = []; // Initialize with an empty list

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    final userId = Provider.of<UserProvider>(context, listen: false).userId;
    final isAdmin = await Provider.of<FamilyViewModel>(context, listen: false).checkAdminAuthorization(userId);
    setState(() {
      _isAdmin = isAdmin;
      _screens = _buildScreens(); // Update screens with admin check
    });
  }

  List<Widget> _buildScreens() {
    return [
      FamilyListScreen(),
      GiftListScreen(userId: FirebaseAuth.instance.currentUser?.uid ?? ''),
      if (_isAdmin) AdminInterfaceScreen(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _signOut() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    await _authService.signOut(userProvider);
  }

  @override
  Widget build(BuildContext context) {
    // Render loading indicator until `_screens` is fully initialized
    if (_screens.isEmpty) {
      return Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedIndex == 0 ? 'Family' : _selectedIndex == 1 ? 'My Gift List' : 'Admin'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _signOut,
          ),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.group),
            label: 'Family',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'My Gift List',
          ),
          if (_isAdmin)
            BottomNavigationBarItem(
              icon: Icon(Icons.admin_panel_settings),
              label: 'Admin',
            ),
        ],
      ),
    );
  }
}
