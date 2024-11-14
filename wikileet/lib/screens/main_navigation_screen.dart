import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart'; // Import Provider
import 'package:wikileet/screens/admin.dart';
import 'package:wikileet/screens/family_list_screen.dart';
import 'package:wikileet/screens/gift_list_screen.dart';
import 'package:wikileet/viewmodels/family_viewmodel.dart';

class MainNavigationScreen extends StatefulWidget {
  @override
  _MainNavigationScreenState createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Screens for each tab
  final List<Widget> _screens = [
    FamilyListScreen(),
    GiftListScreen(userId: FirebaseAuth.instance.currentUser?.uid ?? ''),
    AdminInterfaceScreen(viewModel: FamilyViewModel())
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
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return ChangeNotifierProvider(
      create: (_) => FamilyViewModel()..loadFamilyForUser(userId), // Pass userId instead of email
      child: Scaffold(
        appBar: AppBar(
          title: Text(_selectedIndex == 0 ? 'Family' : 'My Gift List'),
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
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.group),
              label: 'Family',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.list),
              label: 'My Gift List',
            ),
            BottomNavigationBarItem(
                icon: Icon(Icons.admin_panel_settings),
                label: 'Admin' // Add an Admin tab
            )
          ],
        ),
      ),
    );
  }
}
