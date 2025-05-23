
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
  // No change to your class variables
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();
  Set<Polyline> _polylines = {};
  bool didRun = false;

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
  }


  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Only change this line to get JewelUser instead
    final jewelUser = Provider.of<JewelUser>(context);
    if (jewelUser.calendarLogicList == null ||
        jewelUser.calendarLogicList!.isEmpty) return;

    final calendarLogic = jewelUser.calendarLogicList![0];
    // String markerKey = calendarLogic.markers.map((m) => m.markerId.value).join('_');
    // String newDrawKey = "${calendarLogic.selectedDate}_${calendarLogic.events.length}_$markerKey";

    /* if(_lastDrawnKey != newDrawKey) {
      _lastDrawnKey = newDrawKey;*/
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() => _polylines.clear());
      drawRouteOnMap(calendarLogic);
    });

    //}
  }

  /*
   * Main Route Drawing Logic
   */
  void drawRouteOnMap(CalendarLogic calendarLogic) async {
    calendarLogic.events = await getGoogleEventsData(calendarLogic, context);
    String routeId = 'route_${DateTime.now().millisecondsSinceEpoch}';
    List<LatLng> completeRoute = [];
    try {
      setState(() {
        _polylines = {};
      });
      String? apiKey = dotenv.env['GOOGLE_MAPS_KEY'];
      final now = DateTime.now();
      print(
          "DEBUG MARKERS IDS: ${calendarLogic.markers.map((id) => id.markerId.value).toList()}");
      List<LatLng> markerCoordinates =
          getCoordFromMarker(calendarLogic.markers.toList());
      print("DEBUG: Marker Coordinates: $markerCoordinates\n");
      /*
       * Event Processing
       */
      final allEvents = calendarLogic.events
          .where((event) =>
              event.start?.dateTime != null && event.end?.dateTime != null)
          .toList();
      print(
          "DEBUG: All Events: ${allEvents.map((event) => event.location).toList()}");
      //print("DEBUG: All Events Length: ${allEvents.length}");
      final Map<int, gcal.Event> futureEvents = {};
      for (int i = 0; i < allEvents.length; i++) {
        final event = allEvents[i];
        final startTime = event.start?.dateTime;
        print("DEBUG: --------------------------");
        if (startTime != null && startTime.isAfter(now)) {
          futureEvents[i] = event;
          print("DEBUG: Event $i is in the future: $startTime");
        }
      }

      if (futureEvents.isEmpty) {
        return;
      }
      /*
       * Route Drawing
       */
      List<int> sortedEventIndices = futureEvents.keys.toList()..sort();
      for (int i = 0; i < sortedEventIndices.length - 1; i++) {
        int currentEventIndex = sortedEventIndices[i];
        int nextEventIndex = sortedEventIndices[i + 1];

        if (currentEventIndex >= markerCoordinates.length ||
            nextEventIndex >= markerCoordinates.length) {
          continue;
        }

        LatLng startCoord = markerCoordinates[currentEventIndex];
        LatLng endCoord = markerCoordinates[nextEventIndex];

        List<LatLng> segmentCoords = (await getRouteData(
            startCoord,
            endCoord,
            calendarLogic,
            currentEventIndex,
            "getRouteCoordinates",
            apiKey)) as List<LatLng>;
        //print("DEBUG: Segment Coordinates: $segmentCoords");
        if (segmentCoords.isNotEmpty) {
          if (completeRoute.isNotEmpty &&
              completeRoute.last == segmentCoords.first) {
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
      print('Error drawing route on map: $e');
    }
  }
  
  @override
  Widget build(BuildContext context) {
    // Only change this line to get JewelUser instead
    final jewelUser = Provider.of<JewelUser>(context);
    if (jewelUser.calendarLogicList == null ||
        jewelUser.calendarLogicList!.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final calendarLogic = jewelUser.calendarLogicList![0];

    // The rest of your build method remains exactly the same
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
                  
          return Stack(
            children: [
              GoogleMap(
                mapType: MapType.hybrid,
                initialCameraPosition: _statPos,
                onMapCreated: (GoogleMapController controller) async {
                  _controller.complete(controller);
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
                          'Requires at least two future events to calculate routes...',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
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
