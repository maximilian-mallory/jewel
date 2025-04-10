
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:jewel/google/calendar/googleapi.dart';
import 'package:jewel/models/jewel_user.dart';
import 'package:provider/provider.dart';
import 'package:jewel/google/calendar/calendar_logic.dart';
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

  final Set<Polyline> _polylines = {}; // Create a set of polylines

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final JewelUser jewelUser = Provider.of<JewelUser>(context);
    final calendarLogic = jewelUser.calendarLogicList![0]; // Access the CalendarLogic instance
    drawRouteOnMap(calendarLogic);
  } 

  void drawRouteOnMap(CalendarLogic calendarLogic) async {
    try {
      // Get the polyline coordinates. drawRouteOnMap helper function in google_routes.dart
      List<LatLng> polylineCoordinates = getCoordFromMarker(calendarLogic.markers.toList());
      List<LatLng> allCoords = [];

      print('DEBUG polylineCoordinates.length = ${polylineCoordinates.length}');
      print('DEBUG allEvents.length = ${getDepatureTime(calendarLogic).length}');

      for (int i = 0; i < polylineCoordinates.length - 1; i++) {
        List<LatLng> routeSegment = await getRouteCoordinates(
            polylineCoordinates[i], polylineCoordinates[i + 1], calendarLogic, i);
        if (allCoords.isNotEmpty && allCoords.last == routeSegment.first) {
          // Removes repeated coordinate if it matches the last one
          routeSegment.removeAt(0);
        }
        allCoords.addAll(routeSegment);
      }
      
      setState(() {
        _polylines.add(Polyline(
          polylineId: const PolylineId('Id'),
          visible: true,
          points: allCoords,
          color: Colors.blue,
          width: 5,
        ));
      });
    } catch (e) {
      print('Error drawing route on map: $e');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Wrap the body in SafeArea to respect system UI padding.
      body: SafeArea(
        child: Column(
          children: [
            // Use an Expanded widget so the map occupies all available space without overflowing.
            Expanded(
              child: Consumer<JewelUser>(
                builder: (context, jewelUser, child) {
                  final calendarLogic = jewelUser.calendarLogicList?[0];
                  
                  if (calendarLogic == null) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                  
                  return GoogleMap(
                    mapType: MapType.hybrid,
                    initialCameraPosition: _statPos,
                    onMapCreated: (GoogleMapController controller) async {
                      _controller.complete(controller);
                    },
                    markers: calendarLogic.markers.toSet(),
                    polylines: _polylines,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _goToTheLake() async {
    final GoogleMapController controller = await _controller.future;
    await controller.animateCamera(CameraUpdate.newCameraPosition(_kLake));
  }
}
