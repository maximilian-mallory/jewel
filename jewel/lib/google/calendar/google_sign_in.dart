import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:googleapis/calendar/v3.dart' as gcal;
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:jewel/google/calendar/event_snap.dart'; /* *** UNUSED *** */
import 'package:jewel/google/maps/google_maps_calculate_distance.dart';
import 'package:jewel/google/calendar/calendar_logic.dart';

// Define constants and scopes
const List<String> scopes = <String>[
  'https://www.googleapis.com/auth/calendar',
];

// Initialize GoogleSignIn instance
final GoogleSignIn googleSignIn = GoogleSignIn(
  scopes: scopes,
  clientId: kIsWeb
      ? "954035696925-p4j9gbmpjknoc04qjd701r2h5ah190ug.apps.googleusercontent.com"
      : null,
);

// Function to handle signing in
Future<GoogleSignInAccount?> handleSignIn() async {
  try {
    // await handleSignOut();
    return await googleSignIn.signIn();
  } catch (error) {
    print('Sign-In failed: $error');
  }
  return null;
}

// Clear current user and set unauthorized state
Future<void> handleSignOut() async {
  await googleSignIn.disconnect();
}