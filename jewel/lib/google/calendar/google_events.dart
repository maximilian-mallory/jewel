import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

class CalendarIntegrationExample extends StatefulWidget {
  @override
  _CalendarIntegrationExampleState createState() => _CalendarIntegrationExampleState();
}

class _CalendarIntegrationExampleState extends State<CalendarIntegrationExample> {
  List<calendar.Event> _events = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Google Calendar Events'),
      ),
      body:_events.isEmpty
          ? Center(child: Text('No events found or failed to fetch events')) 
      : ListView.builder(
        itemCount: _events.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(_events[index].summary ?? 'No Title'),
            subtitle: Text(_events[index].start?.dateTime?.toString() ?? 'No Date'),
          );
        },
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _getGoogleAccessToken();
  }

  Future<void> _getGoogleAccessToken() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final googleAuth = await user.getIdTokenResult(true);
      final accessToken = googleAuth.token;
      print('Access Token: $accessToken'); // Debug print
      if (accessToken != null) {
        await _fetchEvents(accessToken);
      }else {
        print('Access token is null');
      }
    } else {
      print('User is not signed in');
    }
  }

  Future<void> _fetchEvents(String accessToken) async {
    try{
    var client = http.Client();
    var authenticatedClient = AuthenticatedClient(client, accessToken);

    var calendarApi = calendar.CalendarApi(authenticatedClient);
    var events = await calendarApi.events.list("primary");

    setState(() {
      _events = events.items??[];
    });
    
    print('Fetched ${_events.length} events'); // Debug print
    } catch (e) {
      print('Error fetching events: $e');
    }
  }
}

class AuthenticatedClient extends http.BaseClient {
  final http.Client _client;
  final String _accessToken;

  AuthenticatedClient(this._client, this._accessToken);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers['Authorization'] = 'Bearer $_accessToken';
    return _client.send(request);
  }
}

class CalendarIntegrationKey extends StatefulWidget {
  @override
  _CalendarIntegrationKeyState createState() => _CalendarIntegrationKeyState();
}

class _CalendarIntegrationKeyState extends State<CalendarIntegrationKey> {
  List<dynamic> _events = [];
  late final String _apiKey; // Use late for non-nullable variable
  late final String _calendarId; // Use late for non-nullable variable

  @override
  void initState() {
    super.initState();
    
    // Load the API key and calendar ID from the .env file
    _apiKey = dotenv.env['GOOGLE_CAL_KEY'] ?? '';
    _calendarId = dotenv.env['CALENDAR_ID'] ?? '';
    
    _fetchEventsWithApiKey();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Google Calendar Events'),
      ),
      body: _events.isEmpty
          ? Center(child: Text('No events found er failed to fetch events')) 
          : ListView.builder(
              itemCount: _events.length,
              itemBuilder: (context, index) {
                var event = _events[index];
                var title = event['summary'] ?? 'No Title';
                var dateTime = event['start']?['dateTime'] ?? event['start']?['date'];
                return ListTile(
                  title: Text(title),
                  subtitle: Text(dateTime ?? 'No Date'),
                );
              },
            ),
    );
  }

  Future<void> _fetchEventsWithApiKey() async {
    final url = Uri.parse(
        'https://www.googleapis.com/calendar/v3/calendars/$_calendarId/events?key=$_apiKey');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _events = data['items'] ?? [];
        });
        print('Fetched ${_events.length} events'); // Debug print
      } else {
        print('Failed to fetch events: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching events: $e');
    }
  }
}
