import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_geocoding_api/google_geocoding_api.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:googleapis/adsense/v2.dart';
import 'package:googleapis/calendar/v3.dart' as gcal;
import 'package:jewel/google/calendar/event_snap.dart';
import 'package:jewel/google/calendar/googleapi.dart';
import 'package:jewel/google/maps/google_maps_calculate_distance.dart';
import 'package:jewel/widgets/home_screen.dart';
import 'package:provider/provider.dart';
import '../calendar/g_g_merge.dart';
import 'package:google_maps_routes/google_maps_routes.dart';
import 'package:http/http.dart' as http;
import 'package:jewel/google/calendar/calendar_logic.dart';


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

  return allEvents
  .where((event) =>event.end?.dateTime != null)
  .map((event) => event.end!.dateTime!)
  .toList();

}
List<DateTime> getArrivalTime(CalendarLogic calendarLogic) {
  final allEvents = calendarLogic.events;

  return allEvents
  .where((event) =>event.start?.dateTime != null)
  .map((event) => event.start!.dateTime!)
  .toList();

}

Future<void> checkUserHasEnoughTime(CalendarLogic calendarLogic, int totalDuration, int i) async {
  List<DateTime> eventDepartureTimes = getDepatureTime(calendarLogic);
  List<DateTime> eventArrivalTimes = getArrivalTime(calendarLogic);


  int eventDifference = eventDepartureTimes[i].difference(eventArrivalTimes[i+1]).inSeconds.abs();
  
  print("Event ${i+1} Departure Time: ${eventDepartureTimes[i]}\n");
  print("Event ${i+2} Arrival Time: ${eventArrivalTimes[i+1]}\n");
  print("Event Difference: $eventDifference seconds\n");
  if(eventDifference < totalDuration + 300){ // 5 minutes buffer
    print("DEBUG: Not enough time between events ${i+1} and ${i+2}\n");
  }
  else{
    print("DEBUG: Enough time between events ${i+1} and ${i+2}\n");
  }

}



Future<List<LatLng>> getRouteCoordinates(LatLng start, LatLng end, CalendarLogic calendarLogic, int i) async {
  /*TODO:
  Fix polyline snapping by decoding the encoded polyline_overview from the API response
  */
  try{
    //final arrivalTimes = getArrivalTime(calendarLogic);
    //arrivalTimes[i];
    //DateTime eventStart = DateTime.parse(jewelEvent.arrivalTime!);
    //String? arrivalTime = jewelEvent.arrivalTime;
    //print("Jewel Event arrival time: $arrivalTimes");

    String apiKey = dotenv.env['GOOGLE_MAPS_KEY']!;

    List<DateTime> allEvents = getDepatureTime(calendarLogic);
    print("All Events departure times: $allEvents\n");
    DateTime eventEnd = allEvents[i];
    print("Event end of event ${i+1}: $eventEnd\n");

    final eventUtc = eventEnd.toUtc();
    //print("Event UTC: $eventUtc\n");
    int EndTimestamp = (eventUtc.millisecondsSinceEpoch / 1000).round();
    //print("Departure Timestamp: $EndTimestamp\n");
    

    String url = 'https://maps.googleapis.com/maps/api/directions/json?origin=${start.latitude},${start.longitude}&destination=${end.latitude},${end.longitude}&key=$apiKey&departure_time=$EndTimestamp';
    http.Response response = await http.get(Uri.parse(url));
    Map<String, dynamic> data = json.decode(response.body); //Map with a key of type String and a value of type dynamic(any type) stores in the API response
    
    String prettyJson = const JsonEncoder.withIndent('  ').convert(data);
    //print("API Response: $prettyJson\n"); // delete later

    List<LatLng> polylineCoordinates = [];
    if (data['routes'].isNotEmpty) {
      /*routes key is a list of routes, 0 is the first route 
      legs are the part of the route between two points
      Steps are single instructions inside of legs
      each step contains further information about the route such as start, end location, distance, and duration
      */

      /*Parse the total route time using the departure time 
      of the previous event to hit the api 
      and the duration_in_traffic and duration as a response
      */
      final durationTrafficSec = data['routes'][0]['legs'][0]['duration_in_traffic']['value'] ?? 0;
      print("Total Duration in Traffic: $durationTrafficSec seconds\n\n\n\n");
      checkUserHasEnoughTime(calendarLogic, durationTrafficSec, i);

      data['routes'][0]['legs'][0]['steps'].forEach((step) {//for each step in the route of the leg, add the start and end location to the polylineCoordinates list
        polylineCoordinates.add(LatLng(
          step['start_location']['lat'],
          step['start_location']['lng'],
        ));
        polylineCoordinates.add(LatLng(
          step['end_location']['lat'],
          step['end_location']['lng'],
        ));
      });
    }

    return polylineCoordinates;

  } catch (e) {
    print("Error: $e");
    return [];
  }
}