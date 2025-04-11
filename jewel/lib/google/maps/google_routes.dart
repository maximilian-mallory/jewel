import 'dart:convert';


import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_geocoding_api/google_geocoding_api.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:googleapis/adsense/v2.dart';
import 'package:googleapis/calendar/v3.dart' as gcal;
import 'package:jewel/google/calendar/calendar_logic.dart';
import 'package:jewel/google/calendar/event_snap.dart';
import 'package:jewel/google/calendar/googleapi.dart';
import 'package:jewel/google/maps/google_maps_calculate_distance.dart';
import 'package:jewel/models/jewel_user.dart';
import 'package:jewel/utils/platform/notifications.dart';
import 'package:jewel/widgets/home_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../calendar/g_g_merge.dart';
import 'package:google_maps_routes/google_maps_routes.dart';
import 'package:http/http.dart' as http;

List<LatLng> getCoordFromMarker(List<Marker> eventList) {
  //print("TESTING: $eventList");
  //MapsRoutes route = new MapsRoutes();
  //String apiKey = dotenv.env['GOOGLE_MAPS_KEY']!;

  List<LatLng> coords = [];


  for (var marker in eventList) {
    coords.add(LatLng(marker.position.latitude, marker.position.longitude));
  }

  return coords;
}


List<DateTime> getDepatureTime(CalendarLogic calendarLogic) {
  final allEvents = calendarLogic.events;

  // Filter, map to DateTime, and then sort
  final departureTimes = allEvents
      .where((event) => event.end?.dateTime != null)
      .map((event) => event.end!.dateTime!)
      .toList();

  // Sort chronologically (earliest first)
  departureTimes.sort((a, b) => a.compareTo(b));

  print("Sorted departure times: $departureTimes");
  return departureTimes;
}

List<DateTime> getArrivalTime(CalendarLogic calendarLogic) {
  final allEvents = calendarLogic.events;

  final arrivalTimes = allEvents
      .where((event) => event.start?.dateTime != null)
      .map((event) => event.start!.dateTime!)
      .toList();
  // Sort chronologically (earliest first)
  arrivalTimes.sort((a, b) => a.compareTo(b));
  print("Sorted arrival times: $arrivalTimes");
  return arrivalTimes;
}

//This function is setup to be ran in the background now
//To see an implementation of this running in the foreground
// see the Jeremy_routes branch
Future<List<Map<String, dynamic>>> checkUserHasEnoughTime(
    List<Marker> markerList, String? apiKey) async {
  final prefs = SharedPreferencesAsync();
  final accessToken = await prefs.getString('calendar_access_token');
  if (accessToken != null) {
    final httpClient = GoogleHttpClient(accessToken, timeout: 15);
    final calendarApi = gcal.CalendarApi(httpClient);

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(Duration(days: 1));

    final calEvents = await httpClient.withTimeout(
        15,
        () => calendarApi.events.list(
              'primary',
              timeMin: startOfDay.toUtc(),
              timeMax: endOfDay.toUtc(),
              singleEvents: true,
              orderBy: 'startTime',
            ));

    final calendarLogic = CalendarLogic()..calendarApi = calendarApi;
    calendarLogic.events = calEvents.items ?? [];
    List<LatLng> markerCoordinates = getCoordFromMarker(markerList.toList());
    print("DEBUG2: Marker coordinates: $markerCoordinates");

    /*
     * Event Processing
     */
    final allEvents = calendarLogic.events
        .where((event) =>
            event.start?.dateTime != null && event.end?.dateTime != null)
        .toList();

    final List<MapEntry<int, gcal.Event>> sortedFutureEvents = allEvents
        .asMap()
        .entries
        .where((entry) =>
            entry.value.start?.dateTime != null &&
            entry.value.start!.dateTime!.isAfter(now))
        .toList()
      ..sort((a, b) =>
          a.value.start!.dateTime!.compareTo(b.value.start!.dateTime!));

    if (sortedFutureEvents.isEmpty) {
      print("DEBUG: No future events found; returning empty list");
      return [];
    }

    /*
 * Event-to-Marker Mapping - Corrected version
 */
    final Map<int, gcal.Event> futureEvents = {};
    for (int i = 0; i < allEvents.length; i++) {
      final event = allEvents[i];
      final startTime = event.start?.dateTime;
      if (startTime != null && startTime.isAfter(now)) {
        futureEvents[i] = event;
        print("DEBUG: Event $i is in the future: $startTime");
      }
    }
    if (futureEvents.isEmpty) {
      return [];
    }

    List<int> sortedEventIndices = futureEvents.keys.toList()..sort();

    List<Map<String, dynamic>> eventStatus = [];
    for (int i = 0; i < sortedEventIndices.length - 1; i++) {
      int currentEventIndex = sortedEventIndices[i];
      int nextEventIndex = sortedEventIndices[i + 1];


      if (currentEventIndex >= markerCoordinates.length ||
          nextEventIndex >= markerCoordinates.length) {
        continue;
      }

      LatLng startCoord = markerCoordinates[currentEventIndex];
      LatLng endCoord = markerCoordinates[nextEventIndex];

      print("DEBUG: Start Coord: $startCoord End Coord: $endCoord");

      // Pass the original event index (currentEventIndex) to getRouteData
      List<dynamic> eventDurationsWithNames = (await getRouteData(
        startCoord,
        endCoord,
        calendarLogic,
        currentEventIndex, // Use the original event index
        "getTrafficDurationOfEvents",
        apiKey,
      ));

      if (eventDurationsWithNames.isEmpty) {
        print(
            "DEBUG: No route data available for events ${currentEventIndex} and ${currentEventIndex + 1}");
        eventStatus.add({
          "eventIndex": currentEventIndex,
          "status": false,
          "reason": "No route data available",
        }); // Mark as failed
        continue;
      }

      print(
          "DEBUG: Event traffic durations for events ${currentEventIndex} and ${currentEventIndex + 1}: $eventDurationsWithNames['duration'] seconds");

      DateTime? departureTime = allEvents[currentEventIndex].end?.dateTime;

      DateTime? arrivalTime = allEvents[nextEventIndex].start?.dateTime;

      if (departureTime == null || arrivalTime == null) {
        print(
            "DEBUG: Missing departure or arrival time for events ${currentEventIndex} and ${currentEventIndex + 1}");
        eventStatus.add({
          "eventIndex": currentEventIndex,
          "status": false,
          "reason": "Missing departure or arrival time",
        }); // Mark as failed
        continue;
      }

      int eventDifference =
          departureTime.difference(arrivalTime).inSeconds.abs();
      int duration = eventDurationsWithNames[0]['duration'] ?? 0;

      if (eventDifference < duration + 300) {
        String currentName =
            eventDurationsWithNames[0]['name'] ?? "Unknown Event";

        String nextName =
            eventDurationsWithNames[0]['nextName'] ?? "Unknown Event";
        print(
            "DEBUG: Not enough time between events ${eventDurationsWithNames[0]['name']} and ${eventDurationsWithNames[0]['name']}");
        eventStatus.add({
          "eventIndex": currentEventIndex,
          "status": false,
          "reason": "Not enough time between events",
          "eventName": currentName,
          "nextEventName": nextName,
        });
      } else {
        String currentName =
            eventDurationsWithNames[0]['name'] ?? "Unknown Event";

        String nextName =
            eventDurationsWithNames[0]['nextName'] ?? "Unknown Event";
        print(
            "DEBUG: Enough time between events $currentName and $nextName");
        eventStatus.add({
          "eventIndex": currentEventIndex,
          "status": true,
          "eventName": currentName,
          "nextEventName": nextName,
        });
      }
    }

    return eventStatus;
  }

  // Ensure a return or throw statement at the end
  throw Exception(
      "Unable to check user time due to missing access token or other issues.");
}

Future<List<dynamic>> getRouteData(LatLng start, LatLng end,
    CalendarLogic calendarLogic, int i, String command, String? apiKey) async {
  try {
    if (apiKey == null) {
      print(
          "ERROR: Google Maps API key is null. Make sure dotenv is properly loaded.");
      return [];
    }
    final allEvents = calendarLogic.events;

    // Safety check
    if (i >= allEvents.length) {
      print(
          "ERROR: Event index $i is out of bounds (max: ${allEvents.length - 1})");
      return [];
    }

    // Get the actual event
    final event = allEvents[i];

    // Use the START time of the event for route planning
    final eventStart = event.start?.dateTime;
    if (eventStart == null) {
      print("ERROR: Event $i has no start time");
      return [];
    }

    // Ensure this is a future time
    DateTime now = DateTime.now();
    if (eventStart.isBefore(now)) {
      print(
          "ERROR: Event $i ($eventStart) start time is in the past compared to $now");
      return [];
    }

    // Convert to timestamp
    final eventUtc = eventStart.toUtc();
    print("Using START time for event $i: $eventUtc");
    int departureTimestamp = (eventUtc.millisecondsSinceEpoch / 1000).round();

    // used on local version of the app
    String url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=${start.latitude},${start.longitude}&destination=${end.latitude},${end.longitude}&key=$apiKey&departure_time=$departureTimestamp';

    // Used in the live version of the app
    //String url = 'https://project-emerald-jewel.eastus.azurecontainer.io/google-maps/json?origin=${start.latitude},${start.longitude}&destination=${end.latitude},${end.longitude}&key=$apiKey&departure_time=$departureTimestamp';

    print(
        "Calling Directions API for event $i with departure_time=$departureTimestamp");

    // Make the API call
    http.Response response = await http.get(Uri.parse(url));
    Map<String, dynamic> data = json.decode(response.body);
    //print("DEBUG: Response: ${data.toString()}");
    if (data['status'] != 'OK') {
      print(
          "Error: ${data['status']} - ${data['error_message'] ?? 'No error details'}");
      return [];
    }
    /*final durationTrafficSec = data['routes'][0]['legs'][0]['duration_in_traffic']['value'] ?? 0;
      print("Total Duration in Traffic: $durationTrafficSec seconds\n\n\n\n");
      checkUserHasEnoughTime(calendarLogic, durationTrafficSec);*/
    // Commands to decide what to do with the data
    if (command == "getRouteCoordinates") {
      return getRouteCoordinates(data);
    }
    if (command == "getTrafficDurationOfEvents") {
      return getTrafficDurationOfEvents(data, calendarLogic.events, i);
    } else {
      return [data];
    }
    // Return the top level just in case its needed in the future
    //return data;
    // Extract route coordinates from the response
  } catch (e) {
    print("Error in getRouteData: $e");
    return [];
  }
}

List<LatLng> getRouteCoordinates(data) {
  List<LatLng> routeCoordinates = [];
  if (data['routes'] != null && data['routes'].isNotEmpty) {
    final steps = data['routes'][0]['legs'][0]['steps'];
    for (var step in steps) {
      routeCoordinates.add(LatLng(
        step['start_location']['lat'],
        step['start_location']['lng'],
      ));
      routeCoordinates.add(LatLng(
        step['end_location']['lat'],
        step['end_location']['lng'],
      ));
    }
  }
  return routeCoordinates;
}

List<Map<String, dynamic>> getTrafficDurationOfEvents(
    data, List<gcal.Event> events, int currentEventIndex) {
  List<Map<String, dynamic>> eventDurationsWithNames = [];
  if (data['routes'] != null && data['routes'].isNotEmpty) {
    final legs = data['routes'][0]['legs'];
    for (int i = 0; i < legs.length; i++) {
      final leg = legs[0];
      final durationData = leg['duration_in_traffic'];
      int duration = 0;

      if (durationData != null && durationData['value'] != null) {
        duration = durationData['value'];
      } else if (leg['duration'] != null && leg['duration']['value'] != null) {
        // Fallback to regular duration if traffic info not available
        duration = leg['duration']['value'];
      }

      String currentName = "Unknown Event";
      String nextName = "Unknown Event";

      if (currentEventIndex >= 0 && currentEventIndex < events.length) {
        currentName = events[currentEventIndex].summary ?? "Unknown Event";

        int nextEventIndex = currentEventIndex + 1;
        if (nextEventIndex < events.length) {
          nextName = events[nextEventIndex].summary ?? "Unknown Event";
        }
      }

      // Add the event name and duration to the list
      eventDurationsWithNames.add({
        "name": currentName,
        "nextName": nextName,
        "duration": duration,
      });
    }
  }

  if (eventDurationsWithNames.isEmpty) {
    print("ERROR: No event durations found in the response data.");
  } else {
    print("DEBUG: Event durations with names: $eventDurationsWithNames");
  }

  return eventDurationsWithNames;
}
