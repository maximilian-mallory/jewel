import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
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



  final Set<Polyline> _polylines = {}; // Create a set of polylines

  @override
  void initState() {
    super.initState();
  }
   @override
    void didChangeDependencies() {
      super.didChangeDependencies();
      final calendarLogic = Provider.of<CalendarLogic>(context); // Access the CalendarLogic instance
      drawRouteOnMap(calendarLogic);
    } 

    void drawRouteOnMap(CalendarLogic calendarLogic) async {
      try{
      // Get the polyline coordinates. drawRouteOnMap helper function in google_routes.dart
      List<LatLng> polylineCoordinates = getCoordFromMarker(calendarLogic.markers.toList());
      List<LatLng> allCoords = [];
      /*List<LatLng> polylineCoordinates = [ //Hard coded coords for testing
        //const LatLng(44.87614689999999, -91.9236423999), //BK
        //const LatLng(44.87171177394303, -91.93048800926618),//kwiktrip
        //const LatLng(44.879669645560085, -91.93005113276051),//fortune cookie
        //const LatLng(44.8763198, -91.925625), //TOPPERS
        //const LatLng(44.8761658, -91.9299928), //LOGJAM
      ];*/
     
      for (int i = 0; i < polylineCoordinates.length - 1; i++) {
      List<LatLng> routeSegment = await getRouteCoordinates(polylineCoordinates[i], polylineCoordinates[i + 1]);
      if (allCoords.isNotEmpty && allCoords.last == routeSegment.first) {
        // Removes repeated coordinate if it matches the last one
        routeSegment.removeAt(0);
      }
      allCoords.addAll(routeSegment);
      print('new route coords at $i: $allCoords\n');
    }
      
      
      setState(() {
          _polylines.add(Polyline(
            polylineId: PolylineId('Id'),
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
  final calendarLogic = Provider.of<CalendarLogic>(context); // Access the CalendarLogic instance
 
  /*List<LatLng> latlen = [];

    calendarLogic.markers.toList().forEach((marker){
      latlen.add(marker.position);
    });

    _polylines.add(
          Polyline(
            polylineId: PolylineId('1'),
            points: latlen,
            color: Colors.green,
          )
      );*/
    
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
             
              },
              polylines: _polylines,
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