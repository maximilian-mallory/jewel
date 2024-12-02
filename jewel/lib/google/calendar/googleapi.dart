import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:googleapis/calendar/v3.dart' as gcal;
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:html' as html;

// Define constants and scopes
const List<String> scopes = <String>[
  'https://www.googleapis.com/auth/calendar',
];

String? getClientId() {
  if (kIsWeb) {
    final metaTag = html.document.querySelector('meta[name="google-signin-client_id"]');
    return metaTag?.attributes['content'];
  }
  return null;
}

// Initialize GoogleSignIn instance
final GoogleSignIn googleSignIn = GoogleSignIn(
  scopes: scopes,
  clientId: kIsWeb ? "954035696925-p4j9gbmpjknoc04qjd701r2h5ah190ug.apps.googleusercontent.com" : null,
);

class CalendarLogic {
  static final CalendarLogic _instance = CalendarLogic._internal();

  factory CalendarLogic() {
    return _instance;
  }

  CalendarLogic._internal();
  GoogleSignInAccount? currentUser;
  bool isAuthorized = false;
  List<gcal.Event> events = [];
  DateTime currentDate = DateTime.now();
  bool isDayMode = true;

  Future<void> handleSignIn() async {
    try {
      await googleSignIn.signIn();
    } catch (error) {
      print('Sign-In failed: $error');
    }
  }

  Future<void> handleSignOut() async {
    await googleSignIn.disconnect();
    currentUser = null;
    isAuthorized = false;
    events.clear();
  }

  Future<gcal.CalendarApi> createCalendarApiInstance() async {
    if (currentUser == null) {
      throw Exception('No current user found.');
    }

    final auth = await currentUser!.authentication;
    final accessToken = auth.accessToken;

    if (accessToken == null) {
      throw Exception('Access token is null.');
    }

    final httpClient = http.Client();
    final authClient = authenticatedClient(
      httpClient,
      AccessCredentials(
        AccessToken('Bearer', accessToken, DateTime.now().toUtc().add(const Duration(hours: 1))),
        null,
        scopes,
      ),
    );

    return gcal.CalendarApi(authClient);
  }

  Future<void> getAllEvents(gcal.CalendarApi calendarApi) async {
    try {
      String? pageToken;
      List<gcal.Event> eventsList = [];
      DateTime startOfPeriod = isDayMode ? currentDate : DateTime(currentDate.year, currentDate.month, 1);
      DateTime endOfPeriod = isDayMode
          ? currentDate.add(const Duration(days: 1))
          : DateTime(currentDate.year, currentDate.month + 1, 0);

      do {
        gcal.Events events = await calendarApi.events.list(
          'primary',
          timeMin: startOfPeriod.toUtc(),
          timeMax: endOfPeriod.toUtc(),
          singleEvents: true,
          orderBy: 'startTime',
          pageToken: pageToken,
        );

        if (events.items != null) {
          for (var event in events.items!) {
            if (event.start?.dateTime != null) {
              // Adjust to local time zone
              event.start!.dateTime = event.start!.dateTime!.toLocal();
            }
            if (event.end?.dateTime != null) {
              // Adjust to local time zone
              event.end!.dateTime = event.end!.dateTime!.toLocal();
            }
            eventsList.add(event);
          }
        }

        pageToken = events.nextPageToken;
      } while (pageToken != null);

      events = eventsList;
    } catch (e) {
      print('Error fetching events: $e');
    }
  }

  Future<void> changeDateBy(int daysOrMonths) async {
    if (isDayMode) {
      currentDate = currentDate.add(Duration(days: daysOrMonths));
    } else {
      currentDate = DateTime(currentDate.year, currentDate.month + daysOrMonths, 1);
    }
    await createCalendarApiInstance(); // Update events when date changes.
  }

  Future<void> toggleDayMode(bool value) async {
    isDayMode = value;
    await createCalendarApiInstance(); // Update events when mode changes.
  }
}
