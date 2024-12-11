import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:jewel/google/maps/google_maps_calculate_distance.dart';
import 'package:universal_html/js.dart' as js;
import 'google_maps_injector(UNUSED).dart';
import "package:universal_html/html.dart" as html; // For web only

class MapScreen extends StatelessWidget {
  final LatLng _center = const LatLng(44.879, -91.9193);
  late GoogleMapController mapController;

  MapScreen({super.key});

void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }



  @override
  Widget build(BuildContext context) {
    // Load the API key from the environment
    String? apiKey = dotenv.env['GOOGLE_MAPS_KEY'];
    if (kIsWeb) {//if a
      print('Running on Web');
      // Web: Inject Google Maps API HTML
      if (apiKey != null) {
        print('Injecting Google Maps HTML with API Key');
        injectGoogleMapsHtml(apiKey);
        // Define the initMap function
        js.context['initMap'] = (){
          Future.delayed(Duration(milliseconds: 500), (){
            initMap();
          }
          
          );
        };
      }
      return Scaffold(
        appBar: AppBar(title: Text('Google Maps - Web')),
        body: Center(
          child: SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: HtmlElementView(viewType: 'map'),
          ),
        ),
      );
    } else {
      // Mobile: Use google_maps_flutter plugin
      return MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.green[700],
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Maps Sample App'),
          elevation: 2,
        ),
        body: GoogleMap(
          onMapCreated: _onMapCreated,
          initialCameraPosition: CameraPosition(
            target: _center,
            zoom: 11.0,
          ),
          markers: {
            const Marker(
              markerId: MarkerId('test'),
              position: LatLng(44.879, -91.9193),
              infoWindow: InfoWindow(
                title: 'Marker 1',
                snippet: '',
              ),
            ),
          },
        ),
      ),
    );
    }
  }

  // Define the initMap function
  void initMap() {
    print('initMap function called');
    final mapOptions = js.JsObject.jsify({
      'center': js.JsObject.jsify({'lat': _center.latitude, 'lng': _center.longitude}),
      'zoom': 11,
    });

      final googleMaps = js.context['google'] as js.JsObject;
      final maps = googleMaps['maps'] as js.JsObject;
      final mapConstructor = maps['Map'] as js.JsFunction;
      final map = js.JsObject(mapConstructor, [html.document.getElementById('map'), mapOptions]);
      //isStreetAddress();
      // calculateDistance();
  }
}