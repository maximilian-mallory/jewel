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

class AddCalendarForm extends StatefulWidget {
  final void Function(String calendarName, String description, String timeZone)
      onSubmit;

  const AddCalendarForm({Key? key, required this.onSubmit}) : super(key: key);

  @override
  _AddCalendarFormState createState() => _AddCalendarFormState();
}

class _AddCalendarFormState extends State<AddCalendarForm> {
  final _formKey = GlobalKey<FormState>();
  final _calendarNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _timeZoneController = TextEditingController(text: "America/New_York"); // Default timezone

  @override
  void dispose() {
    _calendarNameController.dispose();
    _descriptionController.dispose();
    _timeZoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView( // Ensures the form is scrollable when keyboard appears
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _calendarNameController,
              decoration: const InputDecoration(labelText: "Calendar Name"),
              validator: (value) =>
                  value == null || value.isEmpty ? "Please enter a calendar name" : null,
            ),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: "Description"),
            ),
            TextFormField(
              controller: _timeZoneController,
              decoration: const InputDecoration(labelText: "Time Zone"),
              validator: (value) =>
                  value == null || value.isEmpty ? "Please enter a time zone" : null,
              // Optionally, you can use a dropdown for time zones
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  widget.onSubmit(
                    _calendarNameController.text,
                    _descriptionController.text,
                    _timeZoneController.text,
                  );
                }
              },
              child: const Text("Add Calendar"),
            ),
          ],
        ),
      ),
    );
  }
}

class _SignInDemoState extends State<SignInDemo> {
  late final CalendarLogic _calendarLogic; // This is what we use to make the method calls
  String? selectedCalendar;
  late gcal.CalendarApi calendarApi;
  @override
  void initState() {
    super.initState();
    _calendarLogic = widget.calendarLogic; // widget. calls the Widget level object, which is the shared API instance from HomeScreen
    googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount? account) async { // Auth State listener
      setState(() {
        _calendarLogic.currentUser = account;
        _calendarLogic.isAuthorized = account != null;
      });
      if (account != null) {
        calendarApi = await _calendarLogic.createCalendarApiInstance(); // This is the auth state we give to the API instance
        await _calendarLogic.getAllEvents(calendarApi);
        //updateCalendar();
        //getAllCalendars(calendarApi);
        setState(() {});
      }
    });
  }

  Future<void> getAllCalendars(gcal.CalendarApi calendarApi) async {
    if (_calendarLogic.currentUser == null) {
      _calendarLogic.calendars.clear();
      return;
    }

    try {
      var calendarList = await calendarApi.calendarList.list();
      _calendarLogic.calendars.clear(); // Clear any old data
      for (var calendarEntry in calendarList.items ?? []) {
        _calendarLogic.calendars[calendarEntry.id ?? "unknown"] = calendarEntry.summary ?? "Unnamed Calendar";
      }
    } catch (e) {
      print("Error fetching calendars: $e");
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
            onPressed: () async { // Update based on date query backward
              await _calendarLogic.changeDateBy(_calendarLogic.isDayMode ? -1 : -1);
              gcal.CalendarApi calendarApi = await _calendarLogic.createCalendarApiInstance();
              await _calendarLogic.getAllEvents(calendarApi);
              //getAllCalendars(_calendarLogic.currentUser);
              setState(() {});
            },
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed: () async { // Update based on date query forward
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
              future: _calendarLogic.createCalendarApiInstance().then(
                (calendarApi) => getAllCalendars(calendarApi),
              ),
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

                return DropdownButton<String>(
                  value: selectedCalendar,
                  hint: const Text("Select Calendar"),
                  items: [
                    ..._calendarLogic.calendars.entries.map((entry) {
                      final calendarId = entry.key;
                      final calendarName = entry.value.toString();
                      return DropdownMenuItem<String>(
                        value: calendarId,
                        child: Text(calendarName),
                      );
                    }).toList(),
                    DropdownMenuItem<String>(
                      value: "add_calendar",
                      child: const Text(
                        "Add New Calendar",
                        style: TextStyle(color: Colors.blue),
                      ),
                    ),
                  ],
                  onChanged: (String? newValue) {
                    if (newValue == "add_calendar") {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true, // Allows full-screen modal for the form
                        builder: (BuildContext context) {
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: MediaQuery.of(context).viewInsets.bottom,
                              top: 16.0,
                              left: 16.0,
                              right: 16.0,
                            ),
                            child: AddCalendarForm(
                              onSubmit: (calendarName, description, timeZone) async {
                                try {
                                  await _calendarLogic.createCalendar(
                                      summary: calendarName,
                                      description: description,
                                      timeZone: timeZone,
                                      calendarApi: calendarApi,
                                  );
                                  Navigator.of(context).pop(); // Close the modal
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text("Calendar added successfully")),
                                  );
                                  // Refresh calendars after adding a new one
                                  setState(() {
                                    _calendarLogic.calendars = {}; // Clear and reload
                                    _calendarLogic.createCalendarApiInstance().then(
                                          (calendarApi) =>
                                              getAllCalendars(calendarApi),
                                        );
                                  });
                                } catch (error) {
                                  Navigator.of(context).pop(); // Close the modal
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text("Failed to add calendar")),
                                  );
                                }
                              },
                            ),
                          );
                        },
                      );
                    } else if (newValue != null) {
                      setState(() {
                        selectedCalendar = newValue;
                      });
                    }
                  },
                );
              },
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


