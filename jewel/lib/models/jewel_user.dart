import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:jewel/google/calendar/googleapi.dart';

class JewelUser {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoUrl;
  List<CalendarLogic>? calendarLogicList;
  final Map<String, List<PersonalGoals>>? personalGoalsList;


  JewelUser({
    required this.uid,
    required this.email,
    required this.personalGoalsList,
    this.displayName,
    this.photoUrl,
    this.calendarLogicList
  });

  // Factory constructor to create JewelUser from Firebase User
  factory JewelUser.fromFirebaseUser(User user, {String? role, String? bio, List<CalendarLogic>? calendarLogicList, Map<String, List<PersonalGoals>>? personalGoalsList}) {
    return JewelUser(
      uid: user.uid,
      email: user.email!,
      displayName: user.displayName,
      photoUrl: user.photoURL,
      calendarLogicList: calendarLogicList ?? [],
      personalGoalsList: personalGoalsList ?? []
    );
  }

  void addCalendarLogic(CalendarLogic logic) async {
    calendarLogicList ??= [];
    calendarLogicList!.add(logic);
  }

  // Convert to JSON (useful for Firestore storage)
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'calendarLogic': jsonEncode(calendarLogicList)
    };
  }

  // Create from JSON (useful for Firestore retrieval)
  factory JewelUser.fromJson(Map<String, dynamic> json) {
    return JewelUser(
      uid: json['uid'],
      email: json['email'],
      displayName: json['displayName'],
      photoUrl: json['photoUrl'],
      calendarLogicList: jsonDecode(json['calendarLogic'])
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