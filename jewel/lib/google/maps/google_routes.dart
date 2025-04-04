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

  return allEvents
  .where((event) =>event.start?.dateTime != null)
  .map((event) => event.start!.dateTime!)
  .toList();

}

Future<List<Map<int, bool>>> checkUserHasEnoughTime() async {
  CalendarLogic calendarLogic = CalendarLogic();
  List<DateTime> eventDepartureTimes = getDepatureTime(calendarLogic);
  List<DateTime> eventArrivalTimes = getArrivalTime(calendarLogic);

  final now = DateTime.now();
  List<LatLng> markerCoordinates = getCoordFromMarker(calendarLogic.markers.toList());
  
  /*
   * Event Processing
   */
  final allEvents = calendarLogic.events.where((event) =>
    event.start?.dateTime != null && event.end?.dateTime != null).toList();
  
  final Map<int, gcal.Event> futureEvents = {};
  for (int i = 0; i < allEvents.length; i++) {
    final event = allEvents[i];
    final startTime = event.start?.dateTime;
    
    if (startTime != null && startTime.isAfter(now)) {
      futureEvents[i] = event;
    }
  }
  
  if (futureEvents.isEmpty) {
    print("DEBUG: No future events found; returning empty list");
    return [];
  }
  
  /*
   * Event-to-Marker Mapping
   */
  Map<int, int> eventToMarkerMap = {};
  
  for (final eventIndex in futureEvents.keys) {
    if (eventIndex < markerCoordinates.length) {
      eventToMarkerMap[eventIndex] = eventIndex;
    }
  }
  
  /*
   * Route Drawing
   */
  List<int> sortedEventIndices = futureEvents.keys.toList()..sort();
  List<Map<int, bool>> eventStatus = [];
  for (int i = 0; i < sortedEventIndices.length - 1; i++) {
    int currentEventIndex = sortedEventIndices[i];
    int nextEventIndex = sortedEventIndices[i + 1];
    
    int currentMarkerPos = eventToMarkerMap[currentEventIndex]!;
    int nextMarkerPos = eventToMarkerMap[nextEventIndex]!;
    
    if (currentMarkerPos >= markerCoordinates.length ||
        nextMarkerPos >= markerCoordinates.length) {
      continue;
    }
    
    LatLng startCoord = markerCoordinates[currentMarkerPos];
    LatLng endCoord = markerCoordinates[nextMarkerPos];
    
    List<dynamic> eventDurations = await getRouteData(
      startCoord, 
      endCoord, 
      calendarLogic, 
      0, 
      "getTrafficDurationOfEvents");

    print("Event Arrival Time: ${eventArrivalTimes[i]} Event Departure Time: ${eventDepartureTimes[i]} of event ${i+1}\n");
    print("Event Departure Time: ${eventDepartureTimes[i+1]} Event Arrival Time: ${eventArrivalTimes[i+1]} of event ${i+2}\n");

    int eventDifference = eventDepartureTimes[i].difference(eventArrivalTimes[i+1]).inSeconds.abs();
    
    print("Event ${i+1} Departure Time: ${eventDepartureTimes[i]}\n");
    print("Event ${i+2} Arrival Time: ${eventArrivalTimes[i+1]}\n");
    print("Event Difference: $eventDifference seconds\n");
    if (eventDifference < eventDurations[i] + 300) { // 5 minutes buffer
      print("DEBUG: Not enough time between events ${i+1} and ${i+2}\n");
      eventStatus.add({i: false});
    }
    else {
      print("DEBUG: Enough time between events ${i+1} and ${i+2}\n");
      eventStatus.add({i: true});
    }
  }
  return eventStatus;
}

Future<List<dynamic>> getRouteData (
    LatLng start,
    LatLng end,
    CalendarLogic calendarLogic,
    int eventIndex,
    String command
    ) async {
  try {
    String apiKey = dotenv.env['GOOGLE_MAPS_KEY']!;
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
 
    // used on local version of the app
    String url = 'https://maps.googleapis.com/maps/api/directions/json?origin=${start.latitude},${start.longitude}&destination=${end.latitude},${end.longitude}&key=$apiKey&departure_time=$departureTimestamp';

    // Used in the live version of the app
    //String url = 'https://project-emerald-jewel.eastus.azurecontainer.io/google-maps/json?origin=${start.latitude},${start.longitude}&destination=${end.latitude},${end.longitude}&key=$apiKey&departure_time=$departureTimestamp';
   
    print("Calling Directions API for event $eventIndex with departure_time=$departureTimestamp");
   
    // Make the API call
    http.Response response = await http.get(Uri.parse(url));
    Map<String, dynamic> data = json.decode(response.body);

    
    if (data['status'] != 'OK') {
      print("Error: ${data['status']} - ${data['error_message'] ?? 'No error details'}");
      return [];
    }
    /*final durationTrafficSec = data['routes'][0]['legs'][0]['duration_in_traffic']['value'] ?? 0;
      print("Total Duration in Traffic: $durationTrafficSec seconds\n\n\n\n");
      checkUserHasEnoughTime(calendarLogic, durationTrafficSec);*/
      // Commands to decide what to do with the data
      if(command == "getRouteCoordinates"){
        return getRouteCoordinates(data);
      }
      if(command == "getTrafficDurationOfEvents"){
        return getTrafficDurationOfEvents(data);
      }else {
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

List<int> getTrafficDurationOfEvents(data){
  List<int> eventDurations = [];
  if (data['routes'] != null && data['routes'].isNotEmpty) {
    final legs = data['routes'][0]['legs'];
    for (var leg in legs) {
      eventDurations.add(leg['duration_in_traffic']['value']);
    }
  }

  return eventDurations;
}