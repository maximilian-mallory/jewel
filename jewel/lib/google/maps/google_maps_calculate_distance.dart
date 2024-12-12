import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_geocoding/google_geocoding.dart';
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

Future<List<LatLon>> convertAddressesToCoords(Map<String, dynamic> sortedEvents) async {
  String? apiKey = dotenv.env['GOOGLE_GEO_KEY'];
  print('API Key: $apiKey');
  if (apiKey == null) {
    throw Exception('Google Maps API key is null');
  }

  GoogleGeocoding googleGeocoding = GoogleGeocoding(apiKey);
  List<LatLon> coordinates = [];

  for (var value in sortedEvents.values) {
    if (value.containsKey('location')) {
      String address = value['location'];
      var response = await googleGeocoding.geocoding.get(address, []);
      if (response != null && response.results != null && response.results!.isNotEmpty) {
        var location = response.results!.first.geometry?.location;
        if (location != null) {
          LatLon coord = LatLon(location.lat!, location.lng!);
          coordinates.add(coord);
          print('Address: $address, Coordinates: (${coord.lat}, ${coord.lon})');
        }
      }
    }
  }

  return coordinates;
}

class LatLon {
  final double lat;
  final double lon;

  LatLon(this.lat, this.lon);
}
