import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:jewel/google/calendar/googleapi.dart';
import 'package:jewel/personal_goals/personal_goals.dart';
import 'package:jewel/google/calendar/calendar_logic.dart';
import 'package:jewel/user_groups/user_group.dart';

class JewelUser extends ChangeNotifier{
  String? uid;
  String? email;
  String? displayName;
  String? photoUrl;
  List<CalendarLogic>? calendarLogicList;
  List<PersonalGoals>? personalGoalsList;
  List<UserGroup>? userGroupList;
  int? themeColor;


  JewelUser({
    this.uid,
    this.email,
    this.personalGoalsList,
    this.displayName,
    this.photoUrl,
    this.calendarLogicList,
    this.userGroupList,
    this.themeColor,
  });

  // Factory constructor to create JewelUser from Firebase User
  factory JewelUser.fromFirebaseUser(User user, {String? role, String? bio, List<CalendarLogic>? calendarLogicList, List<PersonalGoals>? personalGoalsList, List<UserGroup>? userGroupList, int? themeColor}) {
    return JewelUser(
      uid: user.uid,
      email: user.email!,
      displayName: user.displayName,
      photoUrl: user.photoURL,
      calendarLogicList: calendarLogicList,
      personalGoalsList: personalGoalsList,
      userGroupList: userGroupList,
      themeColor: themeColor,
    );
  }

  void updateFrom(JewelUser other) {
    // Update all properties from the other instance
    if (other.uid != null) {
      uid = other.uid;
    }

    if (other.email != null) {
      email = other.email;
    }
    if (other.displayName != null) {
      displayName = other.displayName;
    }
    if (other.photoUrl != null) {
      photoUrl = other.photoUrl;
    }
    
    // Handle the calendar logic list
    if (other.calendarLogicList != null) {
      calendarLogicList = other.calendarLogicList;
    }
    
    // Handle the personal goals list
    if (other.personalGoalsList != null) {
      personalGoalsList = other.personalGoalsList;
    }

    if (other.userGroupList != null) {
      userGroupList = other.userGroupList;
    }

    if (other.themeColor != null) {
      themeColor = other.themeColor;
    }
    // Notify listeners about the changes
    notifyListeners();
  }

  void addCalendarLogic(CalendarLogic logic) async {
    calendarLogicList ??= [];
    calendarLogicList!.add(logic);
    notifyListeners();
  }

  void updateCalendarLogic(CalendarLogic updated, int index)
  {
    calendarLogicList![index] = updated;
    notifyListeners();
  }

  void updateUserGroups(List<UserGroup> groups)
  {
    userGroupList = groups;
    notifyListeners();
  }


  // Convert to JSON (useful for Firestore storage)
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'calendarLogic': jsonEncode(calendarLogicList),
      if (themeColor != null) 'themeColor': themeColor,
    };
  }

  // Create from JSON (useful for Firestore retrieval)
  factory JewelUser.fromJson(Map<String, dynamic> json) {
    return JewelUser(
      uid: json['uid'],
      email: json['email'],
      displayName: json['displayName'],
      photoUrl: json['photoUrl'],
      calendarLogicList: jsonDecode(json['calendarLogic']),
    );
  }
  
  
  Future<JewelUser?> getUserFromFirestore(String email) async {
    DocumentSnapshot doc = await FirebaseFirestore.instance.collection('users').doc('email').get();

    if (doc.exists) {
      return JewelUser.fromJson(doc.data() as Map<String, dynamic>);
    }
    return null;
  }

}

Future<void> saveUserToFirestore(JewelUser user) async {
    final docId = user.email; // Use email as document ID
    await FirebaseFirestore.instance.collection('users').doc(docId).set(user.toJson());
}