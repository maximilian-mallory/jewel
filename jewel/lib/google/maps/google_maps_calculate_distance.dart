

import '../calendar/g_g_merge.dart';

Future<bool> isStreetAddress() async{
  Map<String, dynamic> sortedEvents = await fetchEventData();

  sortedEvents.forEach((key, value){
    if(value.containsKey('location')){
      RegExp reg = new RegExp(r'([^,]+)');
      Iterable<RegExpMatch> matches = reg.allMatches(value['location']);
      for(var match in matches){
        print('location: ${match.group(0)}');
      }
 
    }
  });
  return true;
}