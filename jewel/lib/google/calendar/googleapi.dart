import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  Map<String, dynamic> calendars = {};
  
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
