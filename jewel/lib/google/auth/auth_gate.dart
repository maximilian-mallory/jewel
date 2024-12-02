import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';
import 'package:flutter/material.dart';
import 'package:jewel/screens/test_screen1.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:googleapis_auth/auth_io.dart';
import 'package:url_launcher/url_launcher.dart'; // Import url_launcher

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
              GoogleProvider(clientId: "954035696925-6853rfv8pcd087nsrl438100kuui3vba.apps.googleusercontent.com "), // Use your Android client ID here
            ],
            headerBuilder: (context, constraints, shrinkOffset) {
              return Padding(
                padding: const EdgeInsets.all(20),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: const Text("Welcome"),
                ),
              );
            },
            subtitleBuilder: (context, action) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: action == AuthAction.signIn
                    ? const Text('Welcome to FlutterFire, please sign in!')
                    : const Text('Welcome to FlutterFire, please sign up!'),
              );
            },
            footerBuilder: (context, action) {
              return const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Text(
                  'By signing in, you agree to our terms and conditions.',
                  style: TextStyle(color: Colors.grey),
                ),
              );
            },
          );
        }
        return Screen1();
        // After signing in, check if the user is authenticated
        // final user = snapshot.data!;
        // return FutureBuilder(
        //   future: _handleGoogleOAuth(user, context), // Pass context to handle URL
        //   builder: (context, AsyncSnapshot<void> snapshot) {
        //     if (snapshot.connectionState == ConnectionState.waiting) {
        //       return const Center(child: CircularProgressIndicator());
        //     } else if (snapshot.hasError) {
        //       return Center(child: Text('Error: ${snapshot.error}'));
        //     }

        //     return HomeScreen();
        //   },
        // );
      },
    );
  }

  // Function to handle Google OAuth
  Future<void> _handleGoogleOAuth(User user, BuildContext context) async {
    // Get the ID token from Firebase
    final idToken = await user.getIdToken();

    // You don't need to use the client secret; just use the client ID
    final clientId = ClientId("954035696925-6853rfv8pcd087nsrl438100kuui3vba.apps.googleusercontent.com", null); // Set client secret to null

    // Create an authenticated client to access the Google Calendar API
    try {
      final url = await clientViaUserConsent(
        clientId,
        [calendar.CalendarApi.calendarScope],
        (url) {
          // Display the URL in a clickable button
          _showAuthUrlDialog(context, url);
        },
      );

      // Use the authenticated client to access Google Calendar API
      final calendarApi = calendar.CalendarApi(url);
      final events = await calendarApi.events.list('primary');

      // Print event details
      events.items?.forEach((event) {
        print('Event: ${event.summary}');
      });
    } catch (e) {
      print('Error retrieving Google Calendar events: $e');
      rethrow; // Handle error accordingly
    }
  }

  // Function to show a dialog with the authorization URL
  void _showAuthUrlDialog(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Authorize Access"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Please authorize access to your Google Calendar:"),
              const SizedBox(height: 10),
              Text(url, style: TextStyle(color: Colors.blue)),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () async {
                  if (await canLaunch(url)) {
                    await launch(url); // Launch the URL in the default browser
                  } else {
                    throw 'Could not launch $url';
                  }
                },
                child: const Text("Open Authorization URL"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text("Cancel"),
            ),
          ],
        );
      },
    );
  }
}
