import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_geocoding_api/google_geocoding_api.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:googleapis/calendar/v3.dart' as gcal;
import 'package:jewel/google/calendar/googleapi.dart';
import 'package:jewel/google/maps/google_maps_calculate_distance.dart';
import 'package:jewel/widgets/home_screen.dart';
import 'package:provider/provider.dart';
import '../calendar/g_g_merge.dart';
import 'package:google_maps_routes/google_maps_routes.dart';


Future<void> drawRouteOnMap(List<Marker> eventList, MapsRoutes route) async {
  //print("TESTING: $eventList");
  //MapsRoutes route = new MapsRoutes();
  String apiKey = dotenv.env['GOOGLE_MAPS_KEY']!;
  List<LatLng> coords = [];

  for (var marker in eventList) {
    coords.add(LatLng(marker.position.latitude, marker.position.longitude));
    print("Coords: ${coords}");
  }
  /*List<LatLng> points = [
    LatLng(44.87614689999999, -91.92364239999999),
    LatLng(44.8763198, -91.925625),
    LatLng(44.8761658, -91.9299928)
  ];*/
   //print("Points: ${points}");

  //String formattedCoords = coords.map((coord) => '(${coord.latitude}, ${coord.longitude})').join(', ');
  //print("Formatted Coords: $formattedCoords");

  await route.drawRoute(
      coords,
      eventList.first.infoWindow.title!,
      Color.fromRGBO(130, 78, 210, 1.0),
      apiKey,
      travelMode: TravelModes.driving
    );
  
  
}


