import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'; // Unused
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:googleapis/calendar/v3.dart' as gcal;
import 'package:googleapis_auth/auth_io.dart'; // Unused
import 'package:http/http.dart' as http; // Unused
import 'package:google_sign_in/google_sign_in.dart';
import 'package:jewel/google/calendar/event_snap.dart'; // Unused
import 'package:jewel/google/maps/google_maps_calculate_distance.dart';
import 'package:jewel/google/calendar/calendar_logic.dart';

/* --- Google API Functions --- */
// Define the scopes for the Google Calendar API
const List<String> scopes = <String>[
  'https://www.googleapis.com/auth/calendar',
];

// Method returns an instance of a calendar API for a users Gmail
Future<gcal.CalendarApi> createCalendarApiInstance(
    CalendarLogic calendarLogic) async {
  if (calendarLogic.currentUser == null) {
    print('No current user found.');
  }

  final auth = await calendarLogic.currentUser?.authentication; // Authenticated against the active user
  final accessToken = auth?.accessToken;

  if (accessToken == null) {
    throw Exception('Access token is null.');
  }

  final httpClient = http.Client();
  final authClient = authenticatedClient(
    httpClient,
    AccessCredentials(
      AccessToken(
          'Bearer',
          accessToken,
          DateTime.now()
              .toUtc()
              .add(const Duration(hours: 24))), // One day session
      null,
      scopes,
    ),
  );

  return gcal.CalendarApi(
      authClient); // This is used to make requests to the Google Calendar API
}

// Function to get events for the current selected day
Future<List<gcal.Event>> getGoogleEventsData(
    CalendarLogic calendarLogic, BuildContext context) async {
  // Get the current date at midnight local time
  print(
      "[GET EVENTS DayMode] JewelUser CalendarLogic is: ${calendarLogic.calendarApi}");
  DateTime now = calendarLogic.selectedDate;
  DateTime startOfDay = DateTime(now.year, now.month, now.day);
  // Midnight local time today
  DateTime endOfDay =
      startOfDay.add(Duration(days: 1)); // Midnight local time tomorrow

  // Convert to UTC for comparison with Google Calendar API times
  DateTime startOfDayUtc = startOfDay.toUtc();
  DateTime endOfDayUtc = endOfDay.toUtc();

  // Fetch events from the calendar
  final gcal.Events calEvents = await calendarLogic.calendarApi.events.list(
    calendarLogic.selectedCalendar,
    timeMin: startOfDayUtc, // Filter events starting from midnight today UTC
    timeMax: endOfDayUtc, // Filter events up to midnight tomorrow UTC
  );

  List<gcal.Event> appointments = <gcal.Event>[];
  calendarLogic.markers.clear();
  // If events are available and are within the time range, add them to the list
  if (calEvents.items != null) {
    print('[GET EVENTS] calendar events not null!');
    for (int i = 0; i < calEvents.items!.length; i++) {
      final gcal.Event event = calEvents.items![i];
      print(event.toString());
      if (event.start == null) {
        continue;
      }
      DateTime eventStart = DateTime.parse(event.start!.dateTime.toString());
      if (eventStart.isAfter(startOfDayUtc) &&
          eventStart.isBefore(endOfDayUtc)) {
        appointments.add(event);

        /*if(await checkDocExists('jewelevents', event.id))
        {
          print('[FIREBASE PART REFRESH]: ${event.id}');
        }
        else
        {
          JewelEvent.fromGoogleEvent(event).store();
        }*/
        Marker? marker = await makeMarker(event, calendarLogic, context);
        if (marker != null) {
          calendarLogic.markers.add(marker);
        }
      }
    }
  }
  print('[GET EVENTS] Appointments: ${appointments.toString()}');
  return appointments;
}

// Function to get all events for the selected month from the Google Calendar API
Future<List<gcal.Event>> getGoogleEventsForMonth(
    CalendarLogic calendarLogic, BuildContext context) async {
  // Get the first and last day of the current month
  DateTime now = calendarLogic.selectedDate;
  DateTime startOfMonth = DateTime(now.year, now.month, 1);
  DateTime endOfMonth =
      DateTime(now.year, now.month + 1, 0, 23, 59, 59); // Last day of the month

  // Convert to UTC for Google Calendar API
  DateTime startOfMonthUtc = startOfMonth.toUtc();
  DateTime endOfMonthUtc = endOfMonth.toUtc();

  // Fetch events from the calendar
  final gcal.Events calEvents = await calendarLogic.calendarApi.events.list(
    calendarLogic.selectedCalendar,
    timeMin: startOfMonthUtc, // Fetch events from the start of the month
    timeMax: endOfMonthUtc, // Fetch events until the end of the month
    singleEvents: true, // Ensures recurring events are expanded
    orderBy: "startTime", // Orders events by start time
  );

  List<gcal.Event> appointments = <gcal.Event>[];
  calendarLogic.markers.clear();

  // If events exist, add them to the list
  if (calEvents.items != null) {
    for (int i = 0; i < calEvents.items!.length; i++) {
      final gcal.Event event = calEvents.items![i];
      if (event.start == null) {
        continue;
      }
      // Parse the event start time
      DateTime eventStart = DateTime.parse(event.start!.dateTime.toString());

      // Ensure event is within the selected month
      if (eventStart.isAfter(startOfMonthUtc) &&
          eventStart.isBefore(endOfMonthUtc)) {
        appointments.add(event);
        Marker? marker = await makeMarker(event, calendarLogic, context);
        if (marker != null) {
          calendarLogic.markers.add(marker);
        }
      }
    }
  }

  return appointments; // Return all events for the month
}

// Function to insert an event into Google Calendar
Future<void> insertGoogleEvent({
  required gcal.CalendarApi calendarApi,
  required String eventName,
  required String eventLocation,
  required String eventDescription,
  required DateTime startDate,
  required DateTime endDate,
}) async {
  try {
    if (startDate.isAfter(endDate) || startDate.isAtSameMomentAs(endDate)) {
      print("Error: Start time must be before end time.");
      return;
    }
    // Create a new event
    var event = gcal.Event()
      ..summary = eventName
      ..location = eventLocation
      ..description = eventDescription
      ..start = (gcal.EventDateTime()
        ..dateTime = startDate.toUtc()
        ..timeZone = "UTC")
      ..end = (gcal.EventDateTime()
        ..dateTime = endDate.toUtc()
        ..timeZone = "UTC");

    var createdEvent = await calendarApi.events
        .insert(event, "primary"); // Insert the event into the primary calendar
    print("Event created successfully: ${createdEvent.htmlLink}");
  } catch (e) {
    // Catch any errors that occur during the insertion process
    print("Error inserting event into Google Calendar: $e");
  }
}

// Function to check if the docSnapshot exists
/* *** UNUSED *** */
Future<bool> checkDocExists(String collectionPath, String? docId) async {
  try {
    DocumentSnapshot docSnapshot = await FirebaseFirestore.instance
        .collection(collectionPath)
        .doc(docId)
        .get();

    return docSnapshot.exists;
  } catch (e) {
    print('Error checking document existence: $e');
    return false;
  }
}

// Function to change the date
DateTime changeDateBy(int days, CalendarLogic calendarLogic){
    
      return calendarLogic.selectedDate.add(Duration(days: days));
      
      // currentDate = DateTime(currentDate.year, currentDate.month + daysOrMonths, 1);
 
     // Update events when date changes.
}
