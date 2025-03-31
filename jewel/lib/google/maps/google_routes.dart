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
import 'package:jewel/widgets/home_screen.dart';
import 'package:provider/provider.dart';
import '../calendar/g_g_merge.dart';
import 'package:google_maps_routes/google_maps_routes.dart';
import 'package:http/http.dart' as http;
 
 
List<LatLng> getCoordFromMarker(List<Marker> eventList) {
  //print("TESTING: $eventList");
  //MapsRoutes route = new MapsRoutes();
  String apiKey = dotenv.env['GOOGLE_MAPS_KEY']!;
  List<LatLng> coords = [];
 
  for (var marker in eventList) {
    coords.add(LatLng(marker.position.latitude, marker.position.longitude));
    //print("Coords: ${coords}");
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
 
  // Filter, map, and sort in one chain
  final arrivalTimes = allEvents
    .where((event) => event.start?.dateTime != null)
    .map((event) => event.start!.dateTime!)
    .toList()
    ..sort((a, b) => a.compareTo(b)); // The .. operator is a cascade that returns the list
 
  print("Sorted arrival times: $arrivalTimes");
  return arrivalTimes;
}
 
Future<List<LatLng>> getRouteCoordinates(
    LatLng start,
    LatLng end,
    CalendarLogic calendarLogic,
    int eventIndex) async {
  try {
    String apiKey = dotenv.env['GOOGLE_MAPS_KEY']!;
 
    // IMPORTANT CHANGE: Get the actual event object directly
    final allEvents = calendarLogic.events;
   
    // Safety check
    if (eventIndex >= allEvents.length) {
      print("ERROR: Event index $eventIndex is out of bounds (max: ${allEvents.length - 1})");
      return [];
    }
   
    // Get the actual event
    final event = allEvents[eventIndex];
   
    // Use the START time of the event for route planning
    final eventStart = event.start?.dateTime;
    if (eventStart == null) {
      print("ERROR: Event $eventIndex has no start time");
      return [];
    }
   
    // Ensure this is a future time
    DateTime now = DateTime.now();
    if (eventStart.isBefore(now)) {
      print("ERROR: Event $eventIndex ($eventStart) start time is in the past compared to $now");
      return [];
    }
   
    // Convert to timestamp
    final eventUtc = eventStart.toUtc();
    print("Using START time for event $eventIndex: $eventUtc");
    int departureTimestamp = (eventUtc.millisecondsSinceEpoch / 1000).round();
 
    // Build the API URL with the correct timestamp
    String url = 'https://maps.googleapis.com/maps/api/directions/json?origin=${start.latitude},${start.longitude}&destination=${end.latitude},${end.longitude}&key=$apiKey&departure_time=$departureTimestamp';
   
    print("Calling Directions API for event $eventIndex with departure_time=$departureTimestamp");
   
    // Make the API call
    http.Response response = await http.get(Uri.parse(url));
    Map<String, dynamic> data = json.decode(response.body);
   
    if (data['status'] != 'OK') {
      print("Error: ${data['status']} - ${data['error_message'] ?? 'No error details'}");
      return [];
    }
 
    // Extract route coordinates from the response
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
  } catch (e) {
    print("Error in getRouteCoordinates: $e");
    return [];
  }
}