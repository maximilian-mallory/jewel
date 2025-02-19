import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:jewel/google/calendar/googleapi.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_routes/google_maps_routes.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:jewel/google/maps/google_maps_calculate_distance.dart';
import 'package:jewel/google/maps/google_routes.dart';
import 'package:jewel/google/calendar/g_g_merge.dart';
import 'package:googleapis/calendar/v3.dart' as gcal;

class MapSample extends StatefulWidget {
  

  const MapSample({super.key});

  @override
  State<MapSample> createState() => MapSampleState();
}

class MapSampleState extends State<MapSample> {
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();
  MapsRoutes route = MapsRoutes();
  
  static const CameraPosition _statPos = CameraPosition(
    target: LatLng(44.8742, -91.9195),
    zoom: 14.4746,
  );

  static const CameraPosition _kLake = CameraPosition(
    bearing: 192.8334901395799,
    target: LatLng(44.882, -91.9193),
    tilt: 59.440717697143555,
    zoom: 19.151926040649414,
  );

  @override
  Widget build(BuildContext context) {
    final calendarLogic = Provider.of<CalendarLogic>(context);
    

     return Scaffold(
      body: Column(
        children: [
          // Define a fixed height for the Google Map
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.735, // 50% of the screen height
            child: GoogleMap(
              mapType: MapType.hybrid,
              initialCameraPosition: _statPos,
              onMapCreated: (GoogleMapController controller) async {
                _controller.complete(controller);
                //<LatLng> coords = await convertAddressToCoords(calendarLogic.events);
                //for (int marker = 0; marker < calendarLogic.markers.length; marker++) {
                 drawRouteOnMap(calendarLogic.markers.toList(), route);
          
                
              },
              polylines: route.routes,
              markers: calendarLogic.markers.toSet(),
              
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _goToTheLake() async {
    final GoogleMapController controller = await _controller.future;
    await controller.animateCamera(CameraUpdate.newCameraPosition(_kLake));
  }

}