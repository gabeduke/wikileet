import 'package:flutter/material.dart';

class UserProvider with ChangeNotifier {
  String? _userId;

  String? get userId => _userId;

  void setUserId(String userId) {
    _userId = userId;
    print("User ID set to: $_userId"); // Debug statement
    notifyListeners();
  }

  void clearUserId() {
    _userId = null;
    print("User ID cleared"); // Debug statement
    notifyListeners();
  }
}
