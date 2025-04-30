import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';
import 'package:flutter/material.dart';
import 'package:jewel/google/calendar/googleapi.dart';
import 'package:jewel/models/jewel_user.dart';
import 'package:jewel/screens/intermediary.dart';
import 'package:jewel/google/calendar/calendar_logic.dart';
import 'package:jewel/screens/mslogin.dart';
import 'package:jewel/utils/text_style_notifier.dart';
import 'package:jewel/firebase_ops/user_specific.dart';
import 'package:provider/provider.dart';

/// First screen shown by the app – handles authentication.
///
/// After a successful login it *immediately* fetches the saved `themeColor`
/// from Firestore and injects it into `ThemeStyleNotifier` so the whole UI
/// rebuilds with the correct colour before the user sees the main screen.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // ------------------ NOT signed in -----------------------------------
        if (!snapshot.hasData) {
          return SignInScreen(
            providers: [
              EmailAuthProvider(),
              GoogleProvider(
                clientId:
                    '954035696925-p4j9gbmpjknoc04qjd701r2h5ah190ug.apps.googleusercontent.com',
              ),
            ],
            headerBuilder: (context, constraints, shrinkOffset) => Padding(
              padding: const EdgeInsets.all(20),
              child: AspectRatio(
                aspectRatio: 1,
                child: Image.asset('jewel.png'),
              ),
            ),
            subtitleBuilder: (context, action) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: action == AuthAction.signIn
                  ? const Text('Welcome to Jewel, please sign in!')
                  : const Text('Welcome to Jewel, please sign up!'),
            ),
            footerBuilder: (context, action) => Column(
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: Text(
                    'By signing in, you agree to our terms and conditions.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 20),
                // Microsoft sign-in button
                ElevatedButton.icon(
                  onPressed: () =>
                      MicrosoftAuthService().signInWithMicrosoft(),
                  icon: const Icon(Icons.account_circle),
                  label: const Text('Sign in with Microsoft'),
                ),
              ],
            ),
            sideBuilder: (context, shrinkOffset) => Padding(
              padding: const EdgeInsets.all(20),
              child: AspectRatio(
                aspectRatio: 1,
                child: Image.asset('assets/images/jewel205.png'),
              ),
            ),
          );
        }

        // ------------------ Signed in ---------------------------------------
        final User firebaseUser = FirebaseAuth.instance.currentUser!;
        // Update global JewelUser provider
        final jewelUser = Provider.of<JewelUser>(context, listen: false);
        jewelUser.updateFrom(JewelUser.fromFirebaseUser(firebaseUser));

        // Fetch theme colour, then push to notifier, then enter the app.
        final uidOrEmail = firebaseUser.email ?? firebaseUser.uid;
        return FutureBuilder<Color?>(
          future: UserSettingsService().loadThemeColor(uidOrEmail),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                  body: Center(child: CircularProgressIndicator()));
            }

            final color = snap.data;
            if (color != null) {
              // Do *one* post-frame update to the notifier
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Provider.of<ThemeStyleNotifier>(context, listen: false)
                    .updateThemeColor(color);
              });
              jewelUser.themeColor = color.value; // keep model in sync
            }

            return const Intermediary();
          },
        );
      },
    );
  }
}