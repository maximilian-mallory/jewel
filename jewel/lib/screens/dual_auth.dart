import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_sign_in_web/google_sign_in_web.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart';


class DualAuthScreen extends StatefulWidget {
  @override
  _DualAuthScreenState createState() => _DualAuthScreenState();
}

class _DualAuthScreenState extends State<DualAuthScreen> {
  User? firebaseUser;
  GoogleSignInAccount? googleCalendarUser;
  calendar.CalendarApi? calendarApi;

  final GoogleSignIn _googleSignInCalendar = GoogleSignIn(
    scopes: [calendar.CalendarApi.calendarScope],
  );

  @override
  void initState() {
    super.initState();
    firebaseUser = FirebaseAuth.instance.currentUser;
    _googleSignInCalendar.onCurrentUserChanged.listen((account) {
      setState(() {
        googleCalendarUser = account;
      });
      if (account != null) _initializeCalendarApi(account);
    });
    _googleSignInCalendar.signInSilently();
  }

  Future<void> _signInWithFirebase() 
  async {
    try {
      print('[Firebase Auth] Attempting to sign in to Firebase...');
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        print('[Firebase Auth] Firebase sign-in was canceled by the user.');
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      setState(() => firebaseUser = userCredential.user);

      if (firebaseUser != null) {
        print('[Firebase Auth] Firebase user successfully signed in: ${firebaseUser!.email}');
      } else {
        print('[Firebase Auth] Firebase sign-in failed: User object is null.');
      }

      // Proof of Google Calendar authentication persistence after Firebase sign-in
      if (googleCalendarUser != null) {
        print('[Persistence Check] Google Calendar authentication is still active for: ${googleCalendarUser!.email}');
      } else {
        print('[Persistence Check] Google Calendar authentication is NOT active after Firebase sign-in.');
      }
    } catch (e) {
      print('[Firebase Auth] Firebase sign-in error: $e');
    }
  }

  Future<void> _signInWithGoogleCalendar() async {
  try {
    print('[Google Calendar Auth] Attempting silent sign-in for Calendar...');
    final account = await _googleSignInCalendar.signInSilently();
    if (account == null) {
      print('[Google Calendar Auth] Silent sign-in failed, attempting popup...');
      final user = await _googleSignInCalendar.signIn();
      if (user != null) {
        print('[Google Calendar Auth] Signed in as ${user.email}');
        await _initializeCalendarApi(user);
      } else {
        print('[Google Calendar Auth] User canceled the Calendar sign-in.');
      }
    } else {
      print('[Google Calendar Auth] Google Calendar signed in: ${account.email}');
      await _initializeCalendarApi(account);
    }

    // Proof of Firebase authentication persistence after Calendar sign-in
    if (firebaseUser != null) {
      print('[Persistence Check] Firebase authentication is still active for: ${firebaseUser!.email}');
    } else {
      print('[Persistence Check] Firebase authentication is NOT active after Google Calendar sign-in.');
    }
  } catch (e) {
    print('[Google Calendar Auth] Error during Calendar sign-in: $e');
  }
}

  final clientId = ClientId(
    '954035696925-p4j9gbmpjknoc04qjd701r2h5ah190ug.apps.googleusercontent.com', 
    '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',
  );

  Future<void> _initializeCalendarApi(GoogleSignInAccount account) 
  async {
    final authHeaders = await account.authHeaders;
    final client = authenticatedClient(clientId, authHeaders);
    setState(() {
      calendarApi = calendar.CalendarApi(client);
    });
  }

  AutoRefreshingAuthClient authenticatedClient(ClientId clientId, Map<String, String> headers) 
  {
    final client = GoogleHttpClient(headers);
    return autoRefreshingClient(
      clientId,
      AccessCredentials(
        AccessToken('Bearer', headers['Authorization']!.split(' ').last,
            DateTime.now().add(Duration(hours: 1))),
        null,
        [calendar.CalendarApi.calendarScope],
      ),
      client,
    );
  }


  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    await _googleSignInCalendar.signOut();
    setState(() {
      firebaseUser = null;
      googleCalendarUser = null;
      calendarApi = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auth Example'),
        actions: [
          if (firebaseUser != null || googleCalendarUser != null)
            IconButton(icon: Icon(Icons.logout), onPressed: _signOut),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            firebaseUser == null
                ? ElevatedButton(
                    onPressed: _signInWithFirebase,
                    child: Text('Sign in with Firebase'),
                  )
                : Text('Firebase user: ${firebaseUser!.email}'),
            const SizedBox(height: 20),
            googleCalendarUser == null
                ? ElevatedButton(
                    onPressed: _signInWithGoogleCalendar,
                    child: Text('Sign in to Google Calendar'),
                  )
                : Text('Google Calendar user: ${googleCalendarUser!.email}'),
          ],
        ),
      ),
    );
  }
}

class GoogleHttpClient extends BaseClient {
  final Map<String, String> _headers;
  final Client _client = Client();

  GoogleHttpClient(this._headers);

  @override
  Future<StreamedResponse> send(BaseRequest request) {
    return _client.send(request..headers.addAll(_headers));
  }
}
