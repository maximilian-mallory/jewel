import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:googleapis/calendar/v3.dart' as gcal;
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';

import 'dart:html' as html;

const List<String> scopes = <String>[
  'https://www.googleapis.com/auth/calendar',
];

String? getClientId() {
  if (kIsWeb) {
    // Fetch the meta tag dynamically
    final metaTag = html.document.querySelector('meta[name="google-signin-client_id"]');
    final clientId = metaTag?.attributes['content'];
    print("Client ID fetched from meta tag: $clientId"); // Ensure it prints the client ID
    return clientId;
  }
  return null; // Non-web platforms
}

// Dynamically assign the client ID for GoogleSignIn on web
final GoogleSignIn _googleSignIn = GoogleSignIn(
  scopes: scopes,
  clientId: kIsWeb ? "954035696925-p4j9gbmpjknoc04qjd701r2h5ah190ug.apps.googleusercontent.com" : null, // Set client ID only for web
);

class SignInDemo extends StatefulWidget {
  const SignInDemo({Key? key}) : super(key: key);

  @override
  State createState() => _SignInDemoState();
}

class _SignInDemoState extends State<SignInDemo> {
  GoogleSignInAccount? _currentUser;
  bool _isAuthorized = false;

  @override
  void initState() {
    super.initState();

    // Ensure the client ID is printed on init for debugging
    if (kIsWeb) {
      print("Initializing Google Sign-In for Web...");
      final clientId = getClientId();
      print("Client ID used: $clientId");
    }

    _googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount? account) async {
      if (account != null) {
        setState(() {
          _currentUser = account;
          _isAuthorized = true;
        });
        createCalendarApiInstance();
      }
    });
  }

  Future<void> _handleSignIn() async {
    try {
      if (kIsWeb) {
        print("Attempting Google Sign-In on Web...");
      } else {
        print("Attempting Google Sign-In on non-web platform...");
      }
      await _googleSignIn.signIn();
    } catch (error) {
      print('Sign-In failed: $error');
    }
  }

  Future<void> _handleSignOut() async {
    await _googleSignIn.disconnect();
    setState(() {
      _currentUser = null;
      _isAuthorized = false;
    });
  }

  Future<void> createCalendarApiInstance() async {
    try {
      if (_currentUser == null) {
        print('User is not signed in');
        return;
      }

      final GoogleSignInAuthentication auth = await _currentUser!.authentication;
      final String? accessToken = auth.accessToken;

      if (accessToken == null) {
        print('Access token not available');
        return;
      }

      final httpClient = http.Client();
      final AuthClient authClient = authenticatedClient(
        httpClient,
        AccessCredentials(
          AccessToken('Bearer', accessToken, DateTime.now().toUtc().add(const Duration(hours: 1))),
          null,
          scopes,
        ),
      );

      gcal.CalendarApi calendarApi = gcal.CalendarApi(authClient);
      print("Calendar API instance created successfully");
    } catch (e) {
      print('Error creating Calendar API instance: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Google Calendar Integration')),
      body: Center(
        child: _currentUser != null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Signed in as: ${_currentUser!.email}'),
                  ElevatedButton(
                    onPressed: _handleSignOut,
                    child: const Text('Sign Out'),
                  ),
                ],
              )
            : ElevatedButton(
                onPressed: _handleSignIn,
                child: const Text('Sign In with Google'),
              ),
      ),
    );
  }
}
