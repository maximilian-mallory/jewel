import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as gcal;
import 'package:intl/intl.dart';
import 'package:jewel/google/calendar/googleapi.dart';

class SignInDemo extends StatefulWidget {
  const SignInDemo({super.key});

  @override
  State createState() => _SignInDemoState();
}

class _SignInDemoState extends State<SignInDemo> {
  final CalendarLogic _calendarLogic = CalendarLogic();

  @override
  void initState() {
    super.initState();

    googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount? account) async {
      setState(() {
        _calendarLogic.currentUser = account;
        _calendarLogic.isAuthorized = account != null;
      });
      if (account != null) {
        gcal.CalendarApi calendarApi = await _calendarLogic.createCalendarApiInstance();
        await _calendarLogic.getAllEvents(calendarApi);
        setState(() {});
      }
    });
  }

  Widget buildCalendarUI() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Google Calendar Events'),
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              await _calendarLogic.changeDateBy(_calendarLogic.isDayMode ? -1 : -1);
              gcal.CalendarApi calendarApi = await _calendarLogic.createCalendarApiInstance();
              await _calendarLogic.getAllEvents(calendarApi);
              setState(() {});
            },
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed: () async {
              await _calendarLogic.changeDateBy(_calendarLogic.isDayMode ? 1 : 1);
              gcal.CalendarApi calendarApi = await _calendarLogic.createCalendarApiInstance();
              await _calendarLogic.getAllEvents(calendarApi);
              setState(() {});
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _calendarLogic.isDayMode
                      ? 'Day Mode: ${DateFormat('MM/dd/yyyy').format(_calendarLogic.currentDate)}'
                      : 'Month Mode: ${DateFormat('MM/yyyy').format(_calendarLogic.currentDate)}',
                  style: const TextStyle(fontSize: 18),
                ),
                Switch(
                  value: _calendarLogic.isDayMode,
                  onChanged: (bool value) async {
                    await _calendarLogic.toggleDayMode(value);
                    setState(() {});
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 50,
                    color: Colors.grey[200],
                    child: Column(
                      children: List.generate(24, (index) {
                        String timeLabel = '${index.toString().padLeft(2, '0')}:00';
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            timeLabel,
                            style: const TextStyle(fontSize: 12, color: Colors.black54),
                            textAlign: TextAlign.center,
                          ),
                        );
                      }),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: List.generate(24, (hourIndex) {
                        return Container(
                          height: 100.0,
                          decoration: BoxDecoration(
                            border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
                          ),
                          child: Stack(
                            children: _calendarLogic.events.where((event) {
                              final start = event.start?.dateTime;
                              return start != null && start.hour == hourIndex;
                            }).map((event) {
                              return Positioned(
                                top: 10,
                                left: 60,
                                right: 10,
                                child: Card(
                                  color: Colors.blueAccent,
                                  child: ListTile(
                                    title: Text(
                                      event.summary ?? 'No Title',
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                    subtitle: Text(
                                      '${event.start?.dateTime} - ${event.end?.dateTime}',
                                      style: const TextStyle(color: Colors.white70),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _calendarLogic.currentUser != null
        ? buildCalendarUI()
        : Scaffold(
            appBar: AppBar(title: const Text('Google Calendar Integration')),
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  await _calendarLogic.handleSignIn();
                  setState(() {});
                },
                child: const Text('Sign In with Google'),
              ),
            ),
          );
  }
}
