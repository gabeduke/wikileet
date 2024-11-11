// lib/screens/test_user_selection_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class TestUserSelectionScreen extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _signInWithTestUser(String email, String password) async {
    try {
      await _auth.signOut();
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      print('Failed to sign in: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Select Test User')),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: () => _signInWithTestUser("owner@example.com", "password"),
            child: Text("Log in as Owner"),
          ),
          ElevatedButton(
            onPressed: () => _signInWithTestUser("family@example.com", "password"),
            child: Text("Log in as Family Member"),
          ),
        ],
      ),
    );
  }
}
