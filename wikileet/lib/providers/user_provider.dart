import 'package:flutter/material.dart';

class UserProvider with ChangeNotifier {
  String? _userId;
  String? _familyGroupId;
  String? _houseId;

  String? get userId => _userId;
  String? get familyGroupId => _familyGroupId;
  String? get houseId => _houseId;

  void setHouseId(String houseId) {
    _houseId = houseId;
    print("House ID set to: $_houseId"); // Debug statement
    notifyListeners();
  }

  void clearHouseId() {
    _houseId = null;
    print("House ID cleared"); // Debug statement
    notifyListeners();
  }

  void setFamilyGroupId(String familyGroupId) {
    _familyGroupId = familyGroupId;
    print("Family Group ID set to: $_familyGroupId"); // Debug statement
    notifyListeners();
  }

  void clearFamilyGroupId() {
    _familyGroupId = null;
    print("Family Group ID cleared"); // Debug statement
    notifyListeners();
  }

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
