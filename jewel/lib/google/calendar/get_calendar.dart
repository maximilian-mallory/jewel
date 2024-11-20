import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:googleapis_auth/auth_io.dart';

class CalendarService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<List<calendar.Event>> getCalendarEvents() async {
    // Step 1: Get the current user and their ID token
    User? user = _auth.currentUser;
    if (user == null) {
      throw Exception("User is not authenticated.");
    }

    String? idToken = await user.getIdToken();
    if (idToken!.isEmpty) {
      throw Exception("Failed to retrieve ID token.");
    }

    // Step 2: Authenticate with the Google Calendar API using the ID token
    final client = await clientViaUserConsent(
      ClientId('YOUR_CLIENT_ID', 'YOUR_CLIENT_SECRET'),
      [calendar.CalendarApi.calendarScope],
      (url) {
        // This URL is for users to grant access to their Google Calendar
        print('Please go to this URL and grant access: $url');
      },
    );

    // Step 3: Create an instance of the Calendar API
    var calendarApi = calendar.CalendarApi(client);

    try {
      // Step 4: Fetch the events from the user's primary calendar
      final events = await calendarApi.events.list(
        'primary',
        maxResults: 10,
        singleEvents: true,
        orderBy: 'startTime',
      );

      // Step 5: Return the list of events
      return events.items ?? [];
    } catch (e) {
      print('Error fetching calendar events: $e');
      rethrow;
    } finally {
      client.close(); // Close the client when done
    }
  }
}
