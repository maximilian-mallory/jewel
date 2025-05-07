import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart'; 
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:googleapis/calendar/v3.dart' as gcal;
import 'package:googleapis_auth/auth_io.dart'; 
import 'package:http/http.dart' as http;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:jewel/google/calendar/event_snap.dart'; 
import 'package:jewel/google/maps/google_maps_calculate_distance.dart';
import 'package:jewel/google/calendar/calendar_logic.dart';
import 'package:jewel/google/calendar/ical_conversion.dart';
import 'package:icalendar_parser/icalendar_parser.dart';

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
  List<gcal.Event> appointments = <gcal.Event>[];
  calendarLogic.markers.clear();

  if (calendarLogic.isUsingIcal) {
    try {
      // Only load the iCal events if they haven't been loaded yet
      if (calendarLogic.events.isEmpty) {
        // Get the feed URL from Firestore
        QuerySnapshot querySnapshot = await FirebaseFirestore.instance
            .collection('ical_feeds')
            .where('owner', isEqualTo: calendarLogic.currentUser?.email)
            .where('name', isEqualTo: calendarLogic.selectedCalendar)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          final feedUrl = (querySnapshot.docs[0].data() as Map<String, dynamic>)['url'] as String;
          
          print("DEBUG: Loading iCal feed for first time");
          // Load all events from iCal feed
          List<gcal.Event> allEvents = await loadIcalFeedEvents(feedUrl, calendarLogic, context);
          
          // Store all events in calendarLogic for future reference
          calendarLogic.events = allEvents;
        }
      }
      
      // Filter events for the selected day
      final now = calendarLogic.selectedDate;
      appointments = calendarLogic.events.where((event) {
        final eventDate = event.start?.dateTime?.toLocal();
        final eventDay = event.start?.date?.toLocal();
        
        if (eventDate != null) {
          // For events with specific times
          return eventDate.year == now.year && 
                 eventDate.month == now.month && 
                 eventDate.day == now.day;
        } else if (eventDay != null) {
          // For all-day events
          return eventDay.year == now.year && 
                 eventDay.month == now.month && 
                 eventDay.day == now.day;
        }
        return false;
      }).toList();
    } catch (e) {
      print("Error handling iCal events: $e");
    }
  } else {
    // Get the current date at midnight local time
  print(
      "[GET EVENTS DayMode] JewelUser CalendarLogic is: ${calendarLogic.calendarApi}");
    DateTime now = calendarLogic.selectedDate;
    DateTime startOfDay = DateTime(now.year, now.month, now.day);
  DateTime endOfDay =
      startOfDay.add(Duration(days: 1)); // Midnight local time tomorrow

    // Convert to UTC for comparison with Google Calendar API times
    DateTime startOfDayUtc = startOfDay.toUtc();
    DateTime endOfDayUtc = endOfDay.toUtc();

    try {
      // Fetch events from the calendar
      final gcal.Events calEvents = await calendarLogic.calendarApi.events.list(
        calendarLogic.selectedCalendar,
        timeMin: startOfDayUtc, // Filter events starting from midnight today UTC
        timeMax: endOfDayUtc, // Filter events up to midnight tomorrow UTC
        singleEvents: true,
      );

      // If events are available and are within the time range, add them to the list
      if (calEvents.items != null) {
        print('[GET EVENTS] calendar events not null!');
        appointments.addAll(calEvents.items!);
        
        // Check for converted iCal events in primary calendar if we're not in primary
        if (calendarLogic.selectedCalendar != "primary") {
          try {
            final convertedEvents = await fetchConvertedIcalEvents(
              calendarLogic, 
              startOfDayUtc, 
              endOfDayUtc
            );
            
            if (convertedEvents.isNotEmpty) {
              print("Found ${convertedEvents.length} converted iCal events in primary calendar");
              appointments.addAll(convertedEvents);
            }
          } catch (e) {
            print("Error checking primary calendar for converted events: $e");
          }
        }
      }
    } catch (e) {
      print("Error fetching Google events: $e");
    }
  }

  // Sort events by start time
  if (appointments.isNotEmpty) {
    appointments = sortEvents(appointments);
  }

  // Create markers for events with locations
  for (var event in appointments) {
    if (event.location != null && event.location!.trim().isNotEmpty) {
      try {
        Marker? marker = await makeMarker(event, calendarLogic, context);
        if (marker != null) {
          calendarLogic.markers.add(marker);
        }
      } catch (e) {
        print("ERROR creating marker for event ${event.summary}: $e");
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

  List<gcal.Event> appointments = <gcal.Event>[];
  calendarLogic.markers.clear();

  // Fetch events from the calendar
  try {
    final gcal.Events calEvents = await calendarLogic.calendarApi.events.list(
      calendarLogic.selectedCalendar,
      timeMin: startOfMonthUtc, // Fetch events from the start of the month
      timeMax: endOfMonthUtc, // Fetch events until the end of the month
      singleEvents: true, // Ensures recurring events are expanded
      orderBy: "startTime", // Orders events by start time
    );

    // If events exist, add them to the list
    if (calEvents.items != null) {
      appointments.addAll(calEvents.items!);
      
      // Check for converted iCal events in primary calendar if we're not in primary
      if (calendarLogic.selectedCalendar != "primary") {
        try {
          final convertedEvents = await fetchConvertedIcalEvents(
            calendarLogic, 
            startOfMonthUtc, 
            endOfMonthUtc
          );
          
          if (convertedEvents.isNotEmpty) {
            appointments.addAll(convertedEvents);
          }
        } catch (e) {
          print("Error checking primary calendar for converted events: $e");
        }
      }
    }
    
    // Sort events
    if (appointments.isNotEmpty) {
      appointments = sortEvents(appointments);
    }
    
    // Create markers
    for (var event in appointments) {
      if (event.location != null && event.location!.trim().isNotEmpty) {
        Marker? marker = await makeMarker(event, calendarLogic, context);
        if (marker != null) {
          calendarLogic.markers.add(marker);
        }
      }
    }
  } catch (e) {
    print("Error fetching Google events for month: $e");
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
      throw("Start time must be before end time.");
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
