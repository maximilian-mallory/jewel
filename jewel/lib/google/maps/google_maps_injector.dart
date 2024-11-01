import "package:universal_html/html.dart" as html;

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