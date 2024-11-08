import "dart:convert";

import "package:universal_html/html.dart" as html;
import 'package:http/http.dart' as http;
import 'package:http/browser_client.dart' as browser_http;


void injectGoogleMapsHtml(String apiKey) {
  // Create the script element
  final script = html.ScriptElement()
    ..src = 'https://maps.googleapis.com/maps/api/js?key=$apiKey&callback=initMap'
    ..type = 'text/javascript'
    ..async = true
    ..defer = true;

  // Add event listeners for load and error
  script.onLoad.listen((event) {
    print('Google Maps script loaded successfully');
  });

  script.onError.listen((event) {
    print('Failed to load Google Maps script');
  });

  // Append the script to the head of the document
  html.document.head!.append(script);
  print('Google Maps script injected');
}

Future<String> injectGoogleMapsMatrix(String apiKey, String origin, String destination) async {
  final url = 'https://maps.googleapis.com/maps/api/distancematrix/json?units=metric&origins=$origin&destinations=$destination&key=$apiKey';
  // Set up the headers to allow CORS
  final headers = {
    'Content-Type': 'application/json',
    'Access-Control-Allow-Origin': '*', // Allow all origins, or specify a particular domain
    'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE', // Specify allowed methods
    'Access-Control-Allow-Headers': 'Content-Type', // Specify allowed headers
  };
  // Use BrowserClient for web-specific HTTP requests
  final client = browser_http.BrowserClient();
  final response = await http.get(Uri.parse(url), headers: headers);
  print('response: $response');
  if(response.statusCode==200){
    final data = json.decode(response.body);
    final distance = data['rows'][0]['elements'][0]['distance']['value'];
    final duration = data['rows'][0]['elements'][0]['duration']['text'];
    print('Duration: $duration');
    return distance;
  }
  else{
    throw Exception('Failed to load distance');
  }

  
}