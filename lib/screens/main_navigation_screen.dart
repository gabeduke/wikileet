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
  const MainNavigationScreen({super.key});

  @override
  _MainNavigationScreenState createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;
  final AuthService _authService = AuthService();

  bool _isAdmin = false;
  List<Widget> _screens = [];

  @override
  void initState() {
    super.initState();
    print('MainNavigationScreen initState called');
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    print('Checking admin status...');
    try {
      final userId = Provider.of<UserProvider>(context, listen: false).userId;
      print('Got userId: $userId');
      
      if (userId == null) {
        print('No userId found, setting screens with non-admin status');
        setState(() {
          _isAdmin = false;
          _screens = _buildScreens();
        });
        return;
      }

      print('Checking admin authorization for userId: $userId');
      final isAdmin = await Provider.of<FamilyViewModel>(context, listen: false)
          .checkAdminAuthorization(userId);
      print('Admin check result: $isAdmin');

      setState(() {
        _isAdmin = isAdmin;
        _screens = _buildScreens();
      });
      print('Screens built, count: ${_screens.length}');
    } catch (e, stackTrace) {
      print('Error checking admin status: $e');
      print('Stack trace: $stackTrace');
      setState(() {
        _isAdmin = false;
        _screens = _buildScreens();
      });
    }
  }

  List<Widget> _buildScreens() {
    return [
      FamilyListScreen(),
      GiftListScreen(
        userId: FirebaseAuth.instance.currentUser?.uid ?? '',
        isCurrentUser: true,
      ),
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
    if (_screens.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        bool isWideScreen = constraints.maxWidth > 800;

        Widget bodyContent;

        if (isWideScreen) {
          // Wide screen logic: Admin replaces everything, else Family + Gift List side by side
          if (_selectedIndex == 2 && _isAdmin) {
            bodyContent = AdminInterfaceScreen();
          } else {
            bodyContent = Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: FamilyListScreen()),
                Expanded(
                  child: GiftListScreen(
                    userId: FirebaseAuth.instance.currentUser?.uid ?? '',
                    isCurrentUser: true,
                  ),
                ),
              ],
            );
          }
        } else {
          // Narrow screen logic: Show the selected screen
          bodyContent = _screens[_selectedIndex];
        }

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
          body: bodyContent,
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) {
              if (index < _screens.length) {
                setState(() {
                  _selectedIndex = index;
                });
              }
            },
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.group),
                label: 'Family',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.list),
                label: 'My Gift List',
              ),
              if (_isAdmin)
                const BottomNavigationBarItem(
                  icon: Icon(Icons.admin_panel_settings),
                  label: 'Admin',
                ),
            ],
          ),
        );
      },
    );
  }
}
