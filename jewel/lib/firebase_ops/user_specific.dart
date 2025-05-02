import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UserSettingsService {
  static final _col = FirebaseFirestore.instance.collection('users');

  Future<void> saveThemeColor(String uidOrEmail, Color c) async {
    await _col.doc(uidOrEmail).set(
      {'themeColor': c.value},
      SetOptions(merge: true), // keep existing fields intact
    );
  }

  /// Returns `null` when the user has never chosen a colour.
  Future<Color?> loadThemeColor(String uidOrEmail) async {
    final snap = await _col.doc(uidOrEmail).get();
    if (!snap.exists) return null;
    final val = snap.data()?['themeColor'];
    if (val is int) return Color(val);
    return null;
  }
}