import 'package:firebase_auth/firebase_auth.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

class CalendarService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _scopes = [calendar.CalendarApi.calendarScope];

  Future<List<calendar.Event>> getCalendarEvents() async {
    User? user = _auth.currentUser;

    if (user == null) {
      throw Exception("User is not authenticated.");
    }

    // Step 1: Retrieve the ID token from Firebase
    String? idToken = await user.getIdToken();

    // Step 2: Use the ID token to get an access token for Google APIs
    final client = await clientViaUserConsent(
      ClientId('YOUR_CLIENT_ID', 'YOUR_CLIENT_SECRET'),
      _scopes,
      (url) {
        print('Please go to this URL and grant access: $url');
      },
    );

    // Step 3: Create a Calendar API client
    var calendarApi = calendar.CalendarApi(client);

    try {
      // Step 4: Fetch events from the user's primary calendar
      var events = await calendarApi.events.list(
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
      client.close(); // Ensure the client is closed
    }
  }
}
