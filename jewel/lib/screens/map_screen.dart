import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:universal_html/js.dart' as js;
import '/google/maps/google_maps_injector.dart';
import "package:universal_html/html.dart" as html; // For web only

class MapScreen extends StatelessWidget {
  final LatLng _center = const LatLng(45.521563, -122.677433);

  @override
  Widget build(BuildContext context) {
    // Load the API key from the environment
    String? apiKey = dotenv.env['GOOGLE_MAPS_KEY'];
    print('API Key: $apiKey');
    if (kIsWeb) {//if a
      print('Running on Web');
      // Web: Inject Google Maps API HTML
      if (apiKey != null) {
        print('Injecting Google Maps HTML with API Key');
        injectGoogleMapsHtml(apiKey);
        // Define the initMap function
        js.context['initMap'] = initMap;
      }
      return Scaffold(
        appBar: AppBar(title: Text('Google Maps - Web')),
        body: Center(
          child: Container(
            width: double.infinity,
            height: double.infinity,
            child: HtmlElementView(viewType: 'map'),
          ),
        ),
      );
    } else {
      // Mobile: Use google_maps_flutter plugin
      return Scaffold(
        appBar: AppBar(title: Text('Google Maps - Mobile')),
        body: GoogleMap(
          onMapCreated: (GoogleMapController controller) {},
          initialCameraPosition: CameraPosition(
            target: _center,
            zoom: 11.0,
          ),
          mapType: MapType.normal,
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
    final map = js.JsObject(js.context['google']['maps']['Map'], [html.document.getElementById('map'), mapOptions]);
  }
}