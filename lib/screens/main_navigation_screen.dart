import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:wikileet/screens/no_family_group_screen.dart';
import 'package:wikileet/screens/gift_list_screen.dart';
import 'package:wikileet/screens/family_list_screen.dart';  // Updated import
import 'package:wikileet/viewmodels/family_viewmodel.dart';

import '../providers/user_provider.dart';
import '../services/auth_service.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;
  bool _isAdmin = false;
  List<Widget> _screens = [];  // Initialize with empty list instead of late

  @override
  void initState() {
    super.initState();
    print('MainNavigationScreen: initState called');
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    print('MainNavigationScreen: Checking admin status...');
    final userId = Provider.of<UserProvider>(context, listen: false).userId;
    print('MainNavigationScreen: Got userId: $userId');
    if (userId != null) {
      print('MainNavigationScreen: Checking admin authorization');
      final isAdmin = await Provider.of<FamilyViewModel>(context, listen: false)
          .checkAdminAuthorization(userId);
      print('MainNavigationScreen: Admin check result: $isAdmin');
      if (mounted) {
        setState(() {
          _isAdmin = isAdmin;
          _initializeScreens(userId);
        });
      }
    }
  }

  void _initializeScreens(String userId) {
    print('MainNavigationScreen: Initializing screens');
    setState(() {
      _screens = [
        GiftListScreen(userId: userId, isCurrentUser: true),
        const FamilyListScreen(),
      ];
    });
    print('MainNavigationScreen: Screens built, count: ${_screens.length}');
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final userId = userProvider.userId;
    final isLargeScreen = MediaQuery.of(context).size.width > 900;

    // Check if user has no family group
    if (userProvider.familyGroupId == null) {
      print('MainNavigationScreen: No family group, redirecting to NoFamilyGroupScreen');
      return const NoFamilyGroupScreen();
    }

    // Show loading if userId is not available
    if (userId == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Initialize screens if empty
    if (_screens.isEmpty) {
      print('MainNavigationScreen: Screens empty, initializing');
      _initializeScreens(userId);
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // For larger screens, show side-by-side layout
    if (isLargeScreen) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('WikiLeet'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _signOut,
            ),
          ],
        ),
        body: Container(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Card(
                  margin: const EdgeInsets.only(right: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16.0),
                        child: const Text(
                          'My Wish List',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: GiftListScreen(
                          userId: userId!, 
                          isCurrentUser: true,
                          useInternalScaffold: false,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Card(
                  margin: const EdgeInsets.only(left: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16.0),
                        child: const Text(
                          'Family Members',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Divider(height: 1),
                      const Expanded(
                        child: FamilyListScreen(
                          useInternalScaffold: false,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // For mobile screens, use bottom navigation
    return Scaffold(
      appBar: AppBar(
        title: const Text('WikiLeet'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
          ),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          if (index < _screens.length) {
            setState(() {
              _selectedIndex = index;
            });
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'My Gift List',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group),
            label: 'Family',
          ),
        ],
      ),
    );
  }

  Future<void> _signOut() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    await userProvider.signOut();
  }
}
