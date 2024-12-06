

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:jewel/google/maps/google_maps_injector(UNUSED).dart';

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


Future<String> calculateDistance() async{

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

}

