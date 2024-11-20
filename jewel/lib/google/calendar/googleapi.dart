import 'dart:async';
import 'package:flutter/material.dart';
import 'package:googleapis/calendar/v3.dart' as gcal; // Add a prefix for the googleapis package
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';


const List<String> scopes = <String>[
  'https://www.googleapis.com/auth/calendar',
];

GoogleSignIn _googleSignIn = GoogleSignIn(
  scopes: scopes,
);

class SignInDemo extends StatefulWidget {
  const SignInDemo({Key? key}) : super(key: key);

  @override
  State createState() => _SignInDemoState();
}

class _SignInDemoState extends State<SignInDemo> {
  GoogleSignInAccount? _currentUser;
  bool _isAuthorized = false;
  List<gcal.Event> _events = [];
  DateTime _currentDate = DateTime.now(); // Track the current date for fetching events
  bool _isDayMode = true; // Toggle between Day and Month mode

  @override
  void initState() {
    super.initState();
    _googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount? account) async {
      bool isAuthorized = account != null;
      if (isAuthorized) {
        setState(() {
          _currentUser = account;
          _isAuthorized = isAuthorized;
        });
        createCalendarApiInstance();
      }
    });
    _googleSignIn.signInSilently();
  }

  Future<void> _handleSignIn() async {
    try {
      await _googleSignIn.signIn();
    } catch (error) {
      print('Sign in failed: $error');
    }
  }

  Future<void> _handleSignOut() async {
    await _googleSignIn.disconnect();
    setState(() {
      _currentUser = null;
      _isAuthorized = false;
      _events.clear();
    });
  }

  Future<String?> getGoogleAccessToken() async {
    final GoogleSignInAuthentication auth = await _currentUser!.authentication;
    return auth.accessToken;
  }

  Future<void> createCalendarApiInstance() async {
    String? accessToken = await getGoogleAccessToken();
    if (accessToken == null) {
      print('Access token not available');
      return;
    }

    final httpClient = http.Client();
    final AuthClient authClient = authenticatedClient(
      httpClient,
      AccessCredentials(
        AccessToken('Bearer', accessToken, DateTime.now().toUtc().add(Duration(hours: 1))),
        null,
        scopes,
      ),
    );

    gcal.CalendarApi calendarApi = gcal.CalendarApi(authClient);
    print("API instance created");
    await getAllEvents(calendarApi);
  }

  Future<void> getAllEvents(gcal.CalendarApi calendarApi) async {
    try {
      String? pageToken;
      List<gcal.Event> eventsList = [];
      DateTime startOfPeriod;
      DateTime endOfPeriod;

      startOfPeriod = _currentDate;
      endOfPeriod = _currentDate.add(Duration(days: 1));

      do {
        gcal.Events events = await calendarApi.events.list(
          'primary',
          timeMin: startOfPeriod.toUtc(),
          timeMax: endOfPeriod.toUtc(),
          singleEvents: true,
          orderBy: 'startTime',
          pageToken: pageToken,
        );

        if (events.items != null) {
          eventsList.addAll(events.items!);
        }

        pageToken = events.nextPageToken;
      } while (pageToken != null);

      setState(() {
        _events = eventsList;
      });
    } catch (e) {
      print('Error fetching events: $e');
    }
  }

  // Change the current date based on the toggle mode (Day or Month)
  void _changeDateBy(int daysOrMonths) {
    setState(() {
      if (_isDayMode) {
        _currentDate = _currentDate.add(Duration(days: daysOrMonths));
      } else {
        _currentDate = DateTime(
          _currentDate.year,
          _currentDate.month + daysOrMonths,
          1,
        );
      }
    });
    createCalendarApiInstance();
  }

  @override
  Widget build(BuildContext context) {
    final GoogleSignInAccount? user = _currentUser;
    if (user != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Google Calendar Events'),
          actions: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => _changeDateBy(_isDayMode ? -1 : -1), // Go to the previous day or month
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward),
              onPressed: () => _changeDateBy(_isDayMode ? 1 : 1), // Go to the next day or month
            ),
          ],
        ),
        body: _isAuthorized
            ? Column(
        children: [
          // Day/Month toggle at the top
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _isDayMode
                      ? 'Day Mode: ${DateFormat('MM/dd/yyyy').format(_currentDate)}'
                      : 'Month Mode: ${DateFormat('MM/yyyy').format(_currentDate)}',
                  style: TextStyle(fontSize: 18),
                ),
                Switch(
                  value: _isDayMode,
                  onChanged: (bool value) {
                    setState(() {
                      _isDayMode = value;
                    });
                    createCalendarApiInstance(); // Reload events with the new mode
                  },
                ),
              ],
            ),
          ),
          // Scrollable content for sidebar and main content
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Sidebar with Hours
                  Container(
                    width: 50,
                    color: Colors.grey[200],
                    child: Column(
                      children: List.generate(24, (index) {
                        String timeLabel = _isDayMode
                            ? '${index.toString().padLeft(2, '0')}:00'
                            : '${index}';
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            timeLabel,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        );
                      }),
                    ),
                  ),
                  // Main content area for the calendar view
                  Expanded(
                    child: Column(
                      children: List.generate(24, (hourIndex) {
                        return Column(
                          children: [
                            Container(
                              height: 100.0,
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(color: Colors.grey[300]!),
                                ),
                              ),
                              child: Stack(
                                children: [
                                  ..._events.where((event) {
                                    final start = event.start?.dateTime;
                                    return start != null && start.hour == hourIndex;
                                  }).map((event) {
                                    String eventTitle = event.summary ?? 'No Title';
                                    String eventTime = event.start?.dateTime != null
                                        ? '${event.start?.dateTime} - ${event.end?.dateTime}'
                                        : 'All-day event';

                                    return Positioned(
                                      top: 10,
                                      left: 60,
                                      right: 10,
                                      child: Card(
                                        color: Colors.blueAccent,
                                        margin: EdgeInsets.symmetric(vertical: 2),
                                        child: ListTile(
                                          title: Text(
                                            eventTitle,
                                            style: TextStyle(color: Colors.white),
                                          ),
                                          subtitle: Text(
                                            eventTime,
                                            style: TextStyle(color: Colors.white70),
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ],
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      )
      : Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Please sign in to view calendar events.'),
              ElevatedButton(
                onPressed: _handleSignIn,
                child: const Text('Sign In with Google'),
              ),
            ],
          ),
        ),
      );
    } else {
      return Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: _handleSignIn,
            child: const Text('Sign In with Google'),
          ),
        ),
      );
    }
  }
}
