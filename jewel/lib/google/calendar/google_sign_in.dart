import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

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