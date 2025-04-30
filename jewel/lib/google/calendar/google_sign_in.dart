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
      forceCodeForRefreshToken: true,
      clientId: kIsWeb
          ? "954035696925-p4j9gbmpjknoc04qjd701r2h5ah190ug.apps.googleusercontent.com"
          : null,
    );
  }

// Function to handle signing in
Future<GoogleSignInAccount?> handleSignIn(JewelUser jewelUser) async {
  print("[GOOGLE SIGN-IN] Handling Sign-In...");
  
  try {
    GoogleSignIn googleSignIn;
    bool hasExistingAccounts = jewelUser.calendarLogicList?.isNotEmpty ?? false;
    
    if (hasExistingAccounts) {
      print("[GOOGLE SIGN-IN] User has existing accounts");
      // Create a new instance for additional accounts
      googleSignIn = createGoogleSignInInstance();
      googleSignInList.add(googleSignIn);
    } else {
      print("[GOOGLE SIGN-IN] First time sign-in");
      googleSignIn = createGoogleSignInInstance();
      googleSignInList.add(googleSignIn);
    }
    
    // First, try to sign in - this handles the authentication
    final GoogleSignInAccount? account = await googleSignIn.signIn();
    
    if (account != null) {
      print("[GOOGLE SIGN-IN] Successfully signed in: ${account.email}");
      
      // After authentication succeeds, explicitly request scopes
      // This helps with web specifically to ensure the consent dialog appears
      bool granted = await googleSignIn.requestScopes(scopes);
      
      if (granted) {
        print("[GOOGLE SIGN-IN] All scopes granted");
        return account;
      } else {
        print("[GOOGLE SIGN-IN] Required scopes were denied");
        // Optional: Sign out if scopes weren't granted to prevent incomplete access
        await googleSignIn.signOut();
        return null;
      }
    } else {
      print("[GOOGLE SIGN-IN] Sign-in cancelled by user");
      return null;
    }
  } catch (error) {
    print('Sign-In failed: $error');
    return null;
  }
}
// Clear current user and set unauthorized state
// Future<void> handleSignOut() async {
//   await googleSignIn.disconnect();
// }