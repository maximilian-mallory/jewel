import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:googleapis/calendar/v3.dart' as gcal;
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:google_sign_in/google_sign_in.dart';

// Define constants and scopes
const List<String> scopes = <String>[
  'https://www.googleapis.com/auth/calendar',
];

Future<List<gcal.Event>> getGoogleEventsData(gcal.CalendarApi calendarApi) async {

  final gcal.Events calEvents = await calendarApi.events.list(
    "primary",
  );
  List<gcal.Event> appointments = <gcal.Event>[];
  if (calEvents != null && calEvents.items != null) {
    for (int i = 0; i < calEvents.items!.length; i++) {
      final gcal.Event event = calEvents.items![i];
      if (event.start == null) {
        continue;
      }
      appointments.add(event);
    }
  }
  return appointments;
}

// Initialize GoogleSignIn instance
final GoogleSignIn googleSignIn = GoogleSignIn(
  scopes: scopes,
  clientId: kIsWeb ? "954035696925-p4j9gbmpjknoc04qjd701r2h5ah190ug.apps.googleusercontent.com" : null,
);

class CalendarLogic extends ChangeNotifier{
  static final CalendarLogic _instance = CalendarLogic._internal();
  List<gcal.Event> _events = [];

  List<gcal.Event> get events => _events;

  set events(List<gcal.Event> newEvents) {
    _events = newEvents;
    notifyListeners(); // Notify listeners whenever events are updated
  }
  factory CalendarLogic() {
    return _instance;
  }

  CalendarLogic._internal();
  GoogleSignInAccount? currentUser;
  String? selectedCalendar;
  bool isAuthorized = false;
  DateTime currentDate = DateTime.now();
  bool isDayMode = true;
  Map<String, dynamic> calendars = {};
  
  // This list is a JSON List of events as Maps
  List<Map<String, dynamic>> mapEvents(List<gcal.Event> events) {
    return events.map((event) {
      return {
        'kind': event.kind,
        'etag': event.etag,
        'id': event.id,
        'status': event.status,
        'htmlLink': event.htmlLink,
        'created': event.created?.toIso8601String(),
        'updated': event.updated?.toIso8601String(),
        'summary': event.summary,
        'description': event.description,
        'location': event.location,
        'colorId': event.colorId,
        'creator': {
          'id': event.creator?.id,
          'email': event.creator?.email,
          'displayName': event.creator?.displayName,
          'self': event.creator?.self,
        },
        'organizer': {
          'id': event.organizer?.id,
          'email': event.organizer?.email,
          'displayName': event.organizer?.displayName,
          'self': event.organizer?.self,
        },
        'start': event.start != null
            ? {
                'date': event.start?.date?.toIso8601String(),
                'dateTime': event.start?.dateTime?.toIso8601String(),
                'timeZone': event.start?.timeZone,
              }
            : null,
        'end': event.end != null
            ? {
                'date': event.end?.date?.toIso8601String(),
                'dateTime': event.end?.dateTime?.toIso8601String(),
                'timeZone': event.end?.timeZone,
              }
            : null,
        'endTimeUnspecified': event.endTimeUnspecified,
        'recurrence': event.recurrence,
        'recurringEventId': event.recurringEventId,
        'originalStartTime': event.originalStartTime != null
            ? {
                'date': event.originalStartTime?.date?.toIso8601String(),
                'dateTime': event.originalStartTime?.dateTime?.toIso8601String(),
                'timeZone': event.originalStartTime?.timeZone,
              }
            : null,
        'transparency': event.transparency,
        'visibility': event.visibility,
        'iCalUID': event.iCalUID,
        'sequence': event.sequence,
        'attendees': event.attendees?.map((attendee) {
          return {
            'id': attendee.id,
            'email': attendee.email,
            'displayName': attendee.displayName,
            'organizer': attendee.organizer,
            'self': attendee.self,
            'resource': attendee.resource,
            'optional': attendee.optional,
            'responseStatus': attendee.responseStatus,
            'comment': attendee.comment,
            'additionalGuests': attendee.additionalGuests,
          };
        }).toList(),
        'attendeesOmitted': event.attendeesOmitted,
        'extendedProperties': {
          'private': event.extendedProperties?.private,
          'shared': event.extendedProperties?.shared,
        },
        'hangoutLink': event.hangoutLink,
        'conferenceData': event.conferenceData != null
            ? {
                'createRequest': event.conferenceData?.createRequest,
                'entryPoints': event.conferenceData?.entryPoints,
                'conferenceSolution': event.conferenceData?.conferenceSolution,
                'conferenceId': event.conferenceData?.conferenceId,
                'signature': event.conferenceData?.signature,
                'notes': event.conferenceData?.notes,
              }
            : null,
      };
    }).toList();
  }

  // Method starts the signIn process externally with a Google Modal
  Future<void> handleSignIn() async {
    try {
      await googleSignIn.signIn();
    } catch (error) {
      print('Sign-In failed: $error');
    }
  }

  // Clear current user and set unauthorized state
  Future<void> handleSignOut() async {
    await googleSignIn.disconnect();
    currentUser = null;
    isAuthorized = false;
    events.clear();
  }

  // Method returns an instance of a calendar API for a users Gmail
  Future<gcal.CalendarApi> createCalendarApiInstance() async {
    if (currentUser == null) {
      print('No current user found.');
    }

    final auth = await currentUser!.authentication; // Authenticated against the active user
    final accessToken = auth.accessToken;

    if (accessToken == null) {
      throw Exception('Access token is null.');
    }

    final httpClient = http.Client();
    final authClient = authenticatedClient(
      httpClient,
      AccessCredentials(
        AccessToken('Bearer', accessToken, DateTime.now().toUtc().add(const Duration(hours: 1))), // One hour session
        null,
        scopes,
      ),
    );

    return gcal.CalendarApi(authClient); // This is used to make requests to the Google Calendar API
  }

  // This method returns a Firebase-Stored list of Calendars belonging to a user
  Future<void> getAllCalendars(GoogleSignInAccount? account) async {
    if (account == null) return;

    final calendarPrm = FirebaseFirestore.instance.collection("calendar_prm");
    try {
      final userEmail = account.email;
      final docSnapshot = await calendarPrm.doc(userEmail).get();

      if (docSnapshot.exists) {
        Map<String, dynamic> calendarsData = docSnapshot.data() as Map<String, dynamic>;
        calendars = calendarsData; // Update the calendars map.
      } else {
        calendars = {}; // No calendars found.
      }
    } catch (error) {
      print("Error fetching calendars: $error");
    }
  }

  // Fetch all events in a calendar instance
  Future<void> getAllEvents(gcal.CalendarApi calendarApi) async {
    try {
      String? pageToken; // To paginate results
      List<gcal.Event> eventsList = []; //Storing all events
      print(eventsList);
      DateTime startOfPeriod = isDayMode ? currentDate : DateTime(currentDate.year, currentDate.month, 1); // Stored value or midnight today
      DateTime endOfPeriod = isDayMode // if its daymode
          ? currentDate.add(const Duration(days: 1)) // End of period is 12:00am tomorrow
          : DateTime(currentDate.year, currentDate.month + 1, 0); // Else end of period is 12:00am first day of next month
      // Then fetch events
      do {
        gcal.Events events = await calendarApi.events.list(
          'primary', // Calendar instance id
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

  Future<void> createCalendar({
    required String summary,
    String? description,
    required String timeZone,
    required gcal.CalendarApi calendarApi,
  }) async {
    try {
      var calendar = gcal.Calendar();
      calendar.summary = summary;
      calendar.description = description;
      calendar.timeZone = timeZone;

      await calendarApi.calendars.insert(calendar);
      print("Calendar created: $summary");
    } catch (e) {
      print("Error creating calendar: $e");
      throw e;
    }
  }


  // Method to increment or decrement the Day or Month value of the current date
  Future<void> changeDateBy(int daysOrMonths) async {
    if (isDayMode) {
      currentDate = currentDate.add(Duration(days: daysOrMonths));
    } else {
      currentDate = DateTime(currentDate.year, currentDate.month + daysOrMonths, 1);
    }
    await createCalendarApiInstance(); // Update events when date changes.
  }

  // Method to toggle between Day and Month on calendar
  Future<void> toggleDayMode(bool value) async {
    isDayMode = value;
    await createCalendarApiInstance(); // Update events when mode changes.
  }
}
