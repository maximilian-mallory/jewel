import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapSample extends StatefulWidget {
  const MapSample({super.key});

  @override
  State<MapSample> createState() => MapSampleState();
}

class MapSampleState extends State<MapSample> {
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();

  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  static const CameraPosition _statPos = CameraPosition(
    target: LatLng(44.8742, -91.9195),
    zoom: 14.4746,
  );

  static const CameraPosition _kLake = CameraPosition(
      bearing: 192.8334901395799,
      target: LatLng(44.882, -91.9193),
      tilt: 59.440717697143555,
      zoom: 19.151926040649414);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GoogleMap(
        mapType: MapType.hybrid,
        initialCameraPosition: _statPos, // initial position
        onMapCreated: (GoogleMapController controller) {
          _controller.complete(controller);
        },
        markers: {
         const Marker(
               markerId: const MarkerId("Here"),
               position: LatLng(44.8794, -91.9093),
            ),
            const Marker(
               markerId: const MarkerId("There"),
               position:LatLng(44.869, -91.923),
            ), 
            const Marker(
               markerId: const MarkerId("Anywhere"),
               position: LatLng(44.871, -91.9110)
            ),  // Marker
            const Marker(
               markerId: const MarkerId("Now"),
               position: LatLng(44.9005, -91.9177)
            ),  // Marker
      }
      ),
      
      // floatingActionButton: FloatingActionButton.extended(
      //   onPressed: _goToTheLake,
      //   label: const Text('To the lake!'),
      //   icon: const Icon(Icons.directions_boat),
      // ),
    );
  }

  Future<void> _goToTheLake() async {
    final GoogleMapController controller = await _controller.future;
    await controller.animateCamera(CameraUpdate.newCameraPosition(_kLake));
  }
}