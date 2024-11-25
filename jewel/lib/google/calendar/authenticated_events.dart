import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as gcal;
import 'package:intl/intl.dart';
import 'package:jewel/google/calendar/googleapi.dart';

class SignInDemo extends StatefulWidget {
  final CalendarLogic calendarLogic;

  const SignInDemo({super.key, required this.calendarLogic});

  @override
  State createState() => _SignInDemoState();
}

class _SignInDemoState extends State<SignInDemo> {
  late final CalendarLogic _calendarLogic;
  String? selectedCalendar;

  @override
  void initState() {
    super.initState();
    _calendarLogic = widget.calendarLogic;
    googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount? account) async {
      setState(() {
        _calendarLogic.currentUser = account;
        _calendarLogic.isAuthorized = account != null;
      });
      if (account != null) {
        gcal.CalendarApi calendarApi = await _calendarLogic.createCalendarApiInstance();
        await _calendarLogic.getAllEvents(calendarApi);
        updateCalendar();
        getAllCalendars(_calendarLogic.currentUser);
        setState(() {});
      }
    });
  }

  void getAllCalendars(account) async {
    final calendarPrm = FirebaseFirestore.instance.collection("calendar_prm");
    try {
      final userEmail = account.email;
      // Query the document where the owner matches the user's email
      final docSnapshot = await calendarPrm.doc(userEmail).get();
      print(docSnapshot.data());
      if (docSnapshot.exists) {
        Map<String, dynamic> calendarsData = docSnapshot.data() as Map<String, dynamic>;
        
      }
    } 
    catch (error) {
      print("Error updating calendar: $error");
    }
  }

  void updateCalendar() async {
  if (_calendarLogic.currentUser == null) {
    print("No user is signed in.");
    return;
  }

  // Get the signed-in user's email address
  final userEmail = _calendarLogic.currentUser!.email;

  // Reference the Firestore collection
  final calendarSet = FirebaseFirestore.instance.collection("calendars");

  try {
    // Query the document where the owner matches the user's email
    final querySnapshot = await calendarSet.where("owner", isEqualTo: userEmail).get();

    if (querySnapshot.docs.isNotEmpty) {
      // Get the single document
      final doc = querySnapshot.docs.first;

      print("Calendar found: ${doc.id} => ${doc.data()}");

      // Assuming `_calendarLogic.events` contains the events you want to save
      final eventsToSave = _calendarLogic.mapEvents(_calendarLogic.events);

      // Update the document with the events
      await calendarSet.doc(doc.id).update({
        "events": eventsToSave,
      });

      print("Events added to calendar document: ${doc.id}");
    } else {
      print("No calendars found for the user with email: $userEmail");
    }
  } catch (error) {
    print("Error updating calendar: $error");
  }
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
              getAllCalendars(_calendarLogic.currentUser);
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
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: FutureBuilder<void>(
              future: _calendarLogic.getAllCalendars(_calendarLogic.currentUser),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }
                if (snapshot.hasError) {
                  return const Text("Error loading calendars");
                }

                if (_calendarLogic.calendars.isEmpty) {
                  return const Text("No calendars found");
                }

                // Correctly iterate through the Map<String, dynamic>
                return DropdownButton<String>(
                  value: selectedCalendar,
                  hint: const Text("Select Calendar"),
                  items: _calendarLogic.calendars.entries.map((entry) {
                    // Ensure the value is a String and handle dynamic values appropriately
                    final calendarId = entry.key; // Key is expected to be a String
                    final calendarName = entry.value.toString(); // Convert value to a String
                    return DropdownMenuItem<String>(
                      value: calendarId,
                      child: Text(calendarName),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        selectedCalendar = newValue;
                      });
                    }
                  },
                );
              },
            )
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
