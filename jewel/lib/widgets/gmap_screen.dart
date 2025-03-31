import 'dart:async';
import 'dart:math';
import 'dart:math' as Math;
import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:jewel/google/calendar/calendar_logic.dart';
import 'package:jewel/google/calendar/googleapi.dart';
import 'package:jewel/models/jewel_user.dart';
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
  // No change to your class variables
  final Completer<GoogleMapController> _controller = Completer<GoogleMapController>();
  Set<Polyline> _polylines = {};
  String _lastDrawnKey = "";
 
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
  void initState() {
    super.initState();
   
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        // Only change this line to get JewelUser instead
        final jewelUser = Provider.of<JewelUser>(context, listen: false);
        if (jewelUser.calendarLogicList != null && jewelUser.calendarLogicList!.isNotEmpty) {
          final calendarLogic = jewelUser.calendarLogicList![0];
        
          String markerKey = calendarLogic.markers.map((m) => m.markerId.value).join('_');
          _lastDrawnKey = "${calendarLogic.selectedDate}_${calendarLogic.events.length}_$markerKey";
        
          if (calendarLogic.events.isNotEmpty) {
            drawRouteOnMap(calendarLogic);
          }
        }
      } catch (e) {
        // Handle error silently
      }
    });
  }
 
  @override
  Future<void> didChangeDependencies() async {
    super.didChangeDependencies();
    
    // Only change this line to get JewelUser instead
    final jewelUser = Provider.of<JewelUser>(context);
    if (jewelUser.calendarLogicList == null || jewelUser.calendarLogicList!.isEmpty) return;
    
    final calendarLogic = jewelUser.calendarLogicList![0];
    String markerKey = calendarLogic.markers.map((m) => m.markerId.value).join('_');
    String newDrawKey = "${calendarLogic.selectedDate}_${calendarLogic.events.length}_$markerKey";
 
    if(_lastDrawnKey != newDrawKey) {
      _lastDrawnKey = newDrawKey;
     
      setState(() {
        _polylines = {};
      });
     
      Future.delayed(Duration(milliseconds: 50), () {
        drawRouteOnMap(calendarLogic);
      });
    }
  }
 
  /*
   * Main Route Drawing Logic
   */
  void drawRouteOnMap(CalendarLogic calendarLogic) async {
    try {
      setState(() {
        _polylines = {};
      });
     
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
        return;
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
     
      String routeId = 'route_${DateTime.now().millisecondsSinceEpoch}';
      List<LatLng> completeRoute = [];
     
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
       
        List<LatLng> segmentCoords = await getRouteCoordinates(
          startCoord,
          endCoord,
          calendarLogic,
          currentEventIndex
        );
       
        if (segmentCoords.isNotEmpty) {
          if (completeRoute.isNotEmpty && completeRoute.last == segmentCoords.first) {
            segmentCoords.removeAt(0);
          }
         
          completeRoute.addAll(segmentCoords);
        }
      }
     
      /*
       * Rendering the Final Route
       */
      if (completeRoute.isNotEmpty) {
        setState(() {
          _polylines.add(Polyline(
            polylineId: PolylineId(routeId),
            visible: true,
            points: completeRoute,
            color: Colors.blue,
            width: 6,
          ));
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }
 
  /*
   * UI Rendering
   */
   @override
  Widget build(BuildContext context) {
    // Only change this line to get JewelUser instead
    final jewelUser = Provider.of<JewelUser>(context);
    if (jewelUser.calendarLogicList == null || jewelUser.calendarLogicList!.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final calendarLogic = jewelUser.calendarLogicList![0];
   
    // The rest of your build method remains exactly the same
    return Scaffold(
      body: Column(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.735,
            child: Stack(
              children: [
                GoogleMap(
                  mapType: MapType.hybrid,
                  initialCameraPosition: _statPos,
                  onMapCreated: (GoogleMapController controller) {
                    _controller.complete(controller);
                   
                    if (_polylines.isEmpty && calendarLogic.markers.isNotEmpty) {
                      drawRouteOnMap(calendarLogic);
                    }
                  },
                  markers: calendarLogic.markers.toSet(),
                  polylines: _polylines,
                ),
               
                if (_polylines.isEmpty && calendarLogic.markers.length > 1)
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          CircularProgressIndicator(color: Colors.white),
                          SizedBox(height: 8),
                          Text(
                            'Calculating routes...',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
 
  // No changes to _goToTheLake method
  Future<void> _goToTheLake() async {
    final GoogleMapController controller = await _controller.future;
    await controller.animateCamera(CameraUpdate.newCameraPosition(_kLake));
  }
}