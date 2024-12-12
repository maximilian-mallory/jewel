import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_geocoding/google_geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:googleapis/calendar/v3.dart' as gcal;
import 'package:jewel/google/calendar/googleapi.dart';
import 'package:jewel/widgets/home_screen.dart';
import 'package:provider/provider.dart';
import '../calendar/g_g_merge.dart';

Future<List<String>> getStreetAddresses() async {
  Map<String, dynamic> sortedEvents = await fetchEventData();
  List<String> locations = [];

  for (var value in sortedEvents.values) {
    if (value.containsKey('location')) {
      RegExp reg = RegExp(r'([^,]+)');
      Iterable<RegExpMatch> matches = reg.allMatches(value['location']);
      int groupCount = matches.length;
      print('-----------------------------------------------------------------');
      print('count: $groupCount');
      if (groupCount >= 3) {
        print('Street Address: ${value['location']}');
        print('-----------------------------------------------------------------');
        locations.add(value['location']);
      }
    }
  }
  return locations;
}

Future<LatLng> convertAddressToCoords(gcal.Event event) async {
  String? apiKey = dotenv.env['GOOGLE_GEO_KEY'];
  print('API Key: $apiKey');
  if (apiKey == null) {
    throw Exception('Google Maps API key is null');
  }

  GoogleGeocoding googleGeocoding = GoogleGeocoding(apiKey);
  late LatLng coordinate;

      String? address = event.location;
      var response = await googleGeocoding.geocoding.get(address!, []);
      if (response != null && response.results != null && response.results!.isNotEmpty) {
        var location = response.results!.first.geometry?.location;
        if (location != null) {
          coordinate = LatLng(location.lat!, location.lng!);

          print('Address: $address, Coordinates: (${coordinate.latitude}, ${coordinate.longitude})');
        }
    }

  return coordinate;
}

Future<Marker> makeMarker(gcal.Event event, CalendarLogic calendarLogic, BuildContext context) async {
  // Access the SelectedIndexNotifier via Provider
  final selectedIndexNotifier = Provider.of<SelectedIndexNotifier>(context, listen: false);

  // Create a Marker
  Marker marker = Marker(
    markerId: MarkerId(event.id!),
    position: await convertAddressToCoords(event), // Convert address to coordinates
    infoWindow: InfoWindow(
      title: event.summary, // Display the event summary
      snippet: event.description, // Display additional details (optional)
      onTap: () {
        print("Info window tapped for: ${event.summary}");
        
        // Update the selected index using the notifier's setter
        selectedIndexNotifier.selectedIndex = 1; // Change to the appropriate index

        // Optionally, if you need to trigger a UI update, you can call setState here:
        // setState(() {
        //   selectedIndex = 1;
        // }); // This can be used if you need the selected index in the widget itself
      },
    ),
  );

  return marker;
}


/*Future<String> calculateDistance() async{ //Replaced by Google Routes

String? apiKey = dotenv.env['GOOGLE_MAPS_KEY'];
List<String> locations = await getStreetAddresses();

if(locations.isNotEmpty && apiKey != null){
  for(int i=0;i<locations.length-1;i++){
    String origin = locations[i];
    print('Origin: $origin');
    String destination = locations[i+1];
    print('Destination: $destination');
    try{
      Map<String, dynamic> result = await injectGoogleMapsMatrix(apiKey, origin, destination);
      print('-----------------------------------------------------------------');
      print('Distance from $origin to $destination: ${result['distance']} meters');
      print('Time from $origin to $destination: ${result['duration']}');
      print('-----------------------------------------------------------------');
    }catch (e) {
        print('Error calculating distance: $e');
      }
    
  }

}
else{
  print('!!!Not a real address!!!');
}
return 'unable to calculate distance';

}*/



// class LatLon {
//   final double lat;
//   final double lon;

//   LatLon(this.lat, this.lon);
// }
