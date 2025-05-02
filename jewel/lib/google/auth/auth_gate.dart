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

// USED FOR FIRST AUTH
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});
  
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return SignInScreen(
            providers: [
              EmailAuthProvider(),
              GoogleProvider(clientId: "954035696925-p4j9gbmpjknoc04qjd701r2h5ah190ug.apps.googleusercontent.com"),
              // We can't directly add Microsoft here as it's not part of Firebase UI Auth package
            ],
            headerBuilder: (context, constraints, shrinkOffset) {
              return Padding(
                padding: const EdgeInsets.all(20),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Image.asset('jewel.png'),
                ),
              );
            },
            subtitleBuilder: (context, action) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: action == AuthAction.signIn
                    ? const Text('Welcome to FlutterFire, please sign in!')
                    : const Text('Welcome to Flutterfire, please sign up!'),
              );
            },
            footerBuilder: (context, action) {
              return Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: Text(
                      'By signing in, you agree to our terms and conditions.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Add Microsoft Sign-in Button
                  ElevatedButton.icon(
                    onPressed: () {
                      // Create instance of Microsoft Auth Service and sign in
                      final microsoftAuthService = MicrosoftAuthService();
                      microsoftAuthService.signInWithMicrosoft();
                    },
                    icon: const Icon(Icons.account_circle),
                    label: const Text('Sign in with Microsoft'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                  ),
                ],
              );
            },
            sideBuilder: (context, shrinkOffset) {
              return Padding(
                padding: const EdgeInsets.all(20),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Image.asset('assets/images/jewel205.png'),
                ),
              );
            },
          );
        }
        User? firebaseUser = FirebaseAuth.instance.currentUser;
        JewelUser jewelUser = Provider.of<JewelUser>(context, listen: false);
        jewelUser.updateFrom(
          JewelUser.fromFirebaseUser(
            firebaseUser!,
          )
        );

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
       
        return Intermediary();
      },
    );
  });
  }
}