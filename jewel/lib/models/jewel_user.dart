import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:jewel/google/calendar/googleapi.dart';

class JewelUser {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoUrl;
  // final CalendarLogic? calendarLogic;

  JewelUser({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoUrl,
    // this.calendarLogic
  });

  // Factory constructor to create JewelUser from Firebase User
  factory JewelUser.fromFirebaseUser(User user, {String? role, String? bio, CalendarLogic? calendarLogic}) {
    return JewelUser(
      uid: user.uid,
      email: user.email!,
      displayName: user.displayName,
      photoUrl: user.photoURL,
      // calendarLogic: calendarLogic,
    );
  }

  // Convert to JSON (useful for Firestore storage)
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      // 'calendarLogic': jsonEncode(calendarLogic)
    };
  }

  // Create from JSON (useful for Firestore retrieval)
  factory JewelUser.fromJson(Map<String, dynamic> json) {
    return JewelUser(
      uid: json['uid'],
      email: json['email'],
      displayName: json['displayName'],
      photoUrl: json['photoUrl'],
      // calendarLogic: jsonDecode(json['calendarLogic'])
    );
  }

  
  
  Future<JewelUser?> getUserFromFirestore(String email) async {
    DocumentSnapshot doc = await FirebaseFirestore.instance.collection('users').doc(email).get();

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