import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:googleapis/calendar/v3.dart' as gcal;
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:jewel/event_history/event_history.dart';
import 'package:jewel/firebase_ops/event_history_ops.dart';
import 'package:jewel/google/calendar/googleapi.dart';

// CalendarLogic Class
class CalendarLogic extends ChangeNotifier {
  Map<String, List<String>> eventHistory = {}; // Stores change history of events

  DateTime _selectedDate = DateTime.now();

  DateTime get selectedDate => _selectedDate;

  // Function to add to history
  Future<void> addToHistory(String eventId, String change) async {
    final event = await getHistoryFromFireBase(eventId);
    if (event.getChangelog.isEmpty) {
      // If the event doesn't exist, create a new one
      createHistoryInFireBase(EventHistory(
        eventId: eventId,
        changelog: [change],
      ));
    } else {
      updateChangeLogInFireBase(event, change);
    }

    notifyListeners(); // Notify UI of changes
  }

  Future<List<String>> getHistory(String eventId) async {
    final event = await getHistoryFromFireBase(eventId);
    return event.getChangelog;
  }

  set selectedDate(DateTime newDate) {
    _selectedDate = newDate;
    notifyListeners(); // Notify listeners when the date changes
  }

  Future<void> changeDateBy(int days) async {
    selectedDate = _selectedDate.add(Duration(days: days));
  }

  static final CalendarLogic _instance = CalendarLogic._internal();

  List<gcal.Event> _events = [];

  List<gcal.Event> get events => _events;

  set events(List<gcal.Event> newEvents) {
    _events = newEvents;
    notifyListeners(); // Notify listeners whenever events are updated
  }

  List<Marker> _markers = [];

  List<Marker> get markers => _markers;

  set markers(List<Marker> newMarkers) {
    _markers = newMarkers;
    notifyListeners(); // Notify listeners whenever events are updated
  }

  int _selectedScreen = 1;
  int get selectedScreen => _selectedScreen;

  set selectedScreen(int selectedScreen) {
    _selectedScreen = selectedScreen;
    notifyListeners(); // Notify listeners whenever events are updated
  }

  double _scrollPos = 0.0;
  double get scrollPos => _scrollPos;

  set scrollPos(double scrollPos) {
    _scrollPos = scrollPos;
    notifyListeners(); // Notify listeners whenever events are updated
  }

  factory CalendarLogic() {
    return _instance;
  }

  CalendarLogic._internal();
  GoogleSignInAccount? currentUser;
  late gcal.CalendarApi calendarApi;
  String selectedCalendar = 'primary';
  bool isAuthorized = false;
  DateTime currentDate = DateTime.now();
  bool isDayMode = true;
  Map<String, dynamic> calendars = {};

  // This method returns a Firebase-Stored list of Calendars belonging to a user
  Future<void> getAllCalendars(GoogleSignInAccount? account) async {
    if (account == null) return;

    final calendarPrm = FirebaseFirestore.instance.collection("calendar_prm");
    try {
      final userEmail = account.email;
      final docSnapshot = await calendarPrm.doc(userEmail).get();

      if (docSnapshot.exists) {
        Map<String, dynamic> calendarsData =
            docSnapshot.data() as Map<String, dynamic>;
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
      List<gcal.Event> eventsList = []; // Storing all events
      print(eventsList);
      DateTime startOfPeriod = isDayMode
          ? currentDate
          : DateTime(currentDate.year, currentDate.month,
              1); // Stored value or midnight today
      DateTime endOfPeriod = isDayMode // if its daymode
          ? currentDate
              .add(const Duration(days: 1)) // End of period is 12:00am tomorrow
          : DateTime(currentDate.year, currentDate.month + 1,
              0); // Else end of period is 12:00am first day of next month
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

  // Function to create the calendar
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
      rethrow;
    }
  }

  // Method to increment or decrement the Day or Month value of the current date

  // Method to toggle between Day and Month on calendar
  Future<void> toggleDayMode(bool value, CalendarLogic calendarLogic) async {
    isDayMode = value;
    await createCalendarApiInstance(
        calendarLogic); // Update events when mode changes.
  }

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
                'dateTime':
                    event.originalStartTime?.dateTime?.toIso8601String(),
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
}