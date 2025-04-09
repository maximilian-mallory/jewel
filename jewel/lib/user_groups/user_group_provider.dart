import 'package:firebase_auth/firebase_auth.dart';
import 'package:jewel/user_groups/user_group.dart';
import 'package:flutter/material.dart';
import 'package:jewel/firebase_ops/user_groups.dart';

class UserGroupProvider extends ChangeNotifier {
  List<UserGroup> _userGroups = [];
  List<UserGroup> _yourGroups = [];

  List<UserGroup> get userGroups => _userGroups;
  List<UserGroup> get yourGroups => _yourGroups;

  UserGroupProvider() {
    _loadUserGroups();
    _loadYourGroups();
  }

  Future<void> _loadUserGroups() async {
    _userGroups = await getAllGroupsFromFireBase();
    notifyListeners();
  }

  void addUserGroup(UserGroup group) {
    _userGroups.add(group);
    notifyListeners();
  }

  List<UserGroup> searchUserGroups(String query) {
    return _userGroups
        .where((group) =>
            group.getName.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  Future<void> _loadYourGroups() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _yourGroups = await getUsersGroups(
          user.email!); // Fetch groups for the current user
      notifyListeners();
    }
  }

  Future<void> refreshYourGroups() async {
    await _loadYourGroups(); // Reload the user's groups
  }
}
