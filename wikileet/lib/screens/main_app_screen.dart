// lib/screens/main_app_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:wikileet/screens/gift_list_screen.dart';
import 'package:wikileet/screens/test_user_selection_screen.dart'; // Import TestUserSelectionScreen

class MainAppScreen extends StatefulWidget {
  @override
  _MainAppScreenState createState() => _MainAppScreenState();
}

class _MainAppScreenState extends State<MainAppScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<void> _signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gift List App'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _signOut,
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                // Navigate to the Gift List screen for the current user
                final user = _auth.currentUser;
                if (user != null) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => GiftListScreen(userId: user.uid),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please sign in to view your gift list')),
                  );
                }
              },
              child: Text('Go to My Gift List'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Navigate to TestUserSelectionScreen
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => TestUserSelectionScreen(),
                  ),
                );
              },
              child: Text('Select Test User'),
            ),
          ],
        ),
      ),
    );
  }
}
