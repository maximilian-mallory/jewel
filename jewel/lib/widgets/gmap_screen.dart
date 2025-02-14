import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:jewel/google/calendar/googleapi.dart';
import 'package:provider/provider.dart';

/*
  This widget class returns the map frame and its markers
*/

class MapSample extends StatefulWidget {

  const MapSample({super.key});

  @override
  State<MapSample> createState() => MapSampleState();
}

class MapSampleState extends State<MapSample> {
  final Completer<GoogleMapController> _controller = // this snippet comes from the API docs
      Completer<GoogleMapController>();

  static const CameraPosition _statPos = CameraPosition( // this variable is the default location, or static position, of the user
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
    final calendarLogic = Provider.of<CalendarLogic>(context); // app level Calendar Auth object
    
     return Scaffold(
      body: Column(
        children: [
          // Define a fixed height for the Google Map
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.735, // based on a percentage of the device
            child: GoogleMap(
              mapType: MapType.hybrid, // interface type
              initialCameraPosition: _statPos,
              onMapCreated: (GoogleMapController controller) {
                _controller.complete(controller);
              },
              markers: calendarLogic.markers.toSet(), // this adds the list of markers, markers must be of type Set<Marker>
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _goToTheLake() async { // you can add buttons that will take you to certain locations
    final GoogleMapController controller = await _controller.future;
    await controller.animateCamera(CameraUpdate.newCameraPosition(_kLake));
  }
}