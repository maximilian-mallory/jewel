import 'package:jewel/user_groups/user_group.dart';
import 'package:flutter/material.dart';

class UserGroupProvider extends ChangeNotifier {
  List<UserGroup> _userGroups = [];

  List<UserGroup> get userGroups => _userGroups;

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
}
