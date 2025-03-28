import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:jewel/models/jewel_user.dart';

// Define constants and scopes
const List<String> scopes = <String>[
  'https://www.googleapis.com/auth/calendar',
];

List<GoogleSignIn> googleSignInList = [];

// Initialize GoogleSignIn instance
GoogleSignIn createGoogleSignInInstance() {
    return GoogleSignIn(
      scopes: scopes,
      clientId: kIsWeb
          ? "954035696925-p4j9gbmpjknoc04qjd701r2h5ah190ug.apps.googleusercontent.com"
          : null,
    );
  }

// Function to handle signing in
Future<GoogleSignInAccount?> handleSignIn(JewelUser jewelUser) async {
  print("[GOOGLE SIGN-IN] Handling Sign-In...");
  
  // print(jewelUser.toJson());
  try {
    bool? hasExistingAccounts = jewelUser.calendarLogicList?.isNotEmpty;
    if (hasExistingAccounts != null) {
      // Force a new login session by signing in a different user
      return await googleSignInList[0].signInSilently(suppressErrors: true).then((existingUser) async {
        print("[GOOGLE SIGN-IN] Trying to add second account...");
        if (existingUser != null) {
          print('[Google Sign-In] Existing user detected: ${existingUser.email}');
          googleSignInList.add(createGoogleSignInInstance());
          return await googleSignInList[1].signIn(); // Prompts new login without logging out the first user
        } else {
          print("[GOOGLE SIGN-IN] No Existing Session on second run...");
          return await googleSignInList[0].signIn(); // No existing session, proceed with normal sign-in
        }
      });
    } else {
      print("[GOOGLE SIGN-IN] No Existing Session on first run...");
      googleSignInList.add(createGoogleSignInInstance());
      return await googleSignInList[0].signIn();
    }
  } catch (error) {
    print('Sign-In failed: $error');
  }
  return null;
}
// Clear current user and set unauthorized state
// Future<void> handleSignOut() async {
//   await googleSignIn.disconnect();
// }