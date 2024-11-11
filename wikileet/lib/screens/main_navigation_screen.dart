// lib/screens/main_navigation_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:wikileet/screens/family_list_screen.dart';
import 'package:wikileet/screens/gift_list_screen.dart';
import 'package:wikileet/screens/test_user_selection_screen.dart'; // Import TestUserSelectionScreen

class MainNavigationScreen extends StatefulWidget {
  @override
  _MainNavigationScreenState createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final userId = FirebaseAuth.instance.currentUser?.uid;

  // Screens for each tab
  final List<Widget> _screens = [
    FamilyListScreen(userId: FirebaseAuth.instance.currentUser?.uid ?? ''),
    GiftListScreen(userId: FirebaseAuth.instance.currentUser?.uid ?? ''),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedIndex == 0 ? 'Family Members' : 'My Gift List'),
        actions: [
          IconButton(
            icon: Icon(Icons.person),
            onPressed: () {
              // Navigate to TestUserSelectionScreen for testing purposes
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => TestUserSelectionScreen(),
                ),
              );
            },
          ),
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
        ],
      ),
    );
  }
}
