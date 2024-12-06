import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as gcal;
import 'package:intl/intl.dart';
import 'package:jewel/google/calendar/googleapi.dart';

class AuthenticatedCalendar extends StatefulWidget {
  final CalendarLogic calendarLogic;

  const AuthenticatedCalendar({super.key, required this.calendarLogic});

  @override
  State createState() => _AuthenticatedCalendarState();
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

class _AuthenticatedCalendarState extends State<AuthenticatedCalendar> {
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

/*
 * buildCalendarUI is the highest level parent widget
 */
  Widget buildCalendarUI() {
    return Scaffold( // Whatever returns a Scaffold is what we see on the screen
      appBar: AppBar(
        actions: [ 
          dateToggle(), // The actual switch that toggles day or month level view 
          // These buttons are the toggles for going forward and backward one day or month in the event query
          daymonthBackButton(),
          daymonthForwardButton(),
        ],
      ),
      body: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          loadCalendarMenu(), // The dropdown menu to toggle between calendar ids
                             // The actual calendar event list, populated dynamically
        ],
      ),
    );
  }

/*
 * The decrement button for date query
 */
  Widget daymonthBackButton() {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () async { // Update based on date query backward
        await widget.calendarLogic.changeDateBy(_calendarLogic.isDayMode ? -1 : -1);
        gcal.CalendarApi calendarApi = await _calendarLogic.createCalendarApiInstance();
        await widget.calendarLogic.getAllEvents(calendarApi);
        //getAllCalendars(_calendarLogic.currentUser);
        setState(() {});
      },
    );
  }
/*
 * Increment button for date query
 */
  Widget daymonthForwardButton() {
    return IconButton(
      icon: const Icon(Icons.arrow_forward),
      onPressed: () async { // Update based on date query forward
        await widget.calendarLogic.changeDateBy(_calendarLogic.isDayMode ? 1 : 1);
        gcal.CalendarApi calendarApi = await _calendarLogic.createCalendarApiInstance();
        await widget.calendarLogic.getAllEvents(calendarApi);
        setState(() {});
      },
    );
  }

/*
* Calendar scrolling list, sidebar timestamps
*/
  Widget calendarScrollView(CalendarLogic calendarLogic) {
    return Expanded(
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
            buildEventsList(calendarLogic.events)
          ],
        ),
      ),
    );
  }

/*
 * Toggle switch for day / month mode
 */
  Widget dateToggle() {
    return Padding(
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
    );
  }

  /*
  * This widget handles asynchronous loading of the list of available calendars, but nothing more
  */
  Widget loadCalendarMenu() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: FutureBuilder<void>(
        future: widget.calendarLogic.createCalendarApiInstance().then(
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

          return calendarSelectMenu(widget.calendarLogic); // The actual dropdown menu is here
        },
      ),
    );
  }

  /*
   * The actual dropdown list or 'DropdownButton' list of calendar entries, or available calendars
   */
  Widget calendarSelectMenu(CalendarLogic calendarLogic) {
  return FutureBuilder<List<String>>(
    future: _getIcalFeeds(), // Call the async function to fetch calendar names
    builder: (BuildContext context, AsyncSnapshot<List<String>> snapshot) {
      if (snapshot.hasError) {
        return Text('Error: ${snapshot.error}'); // Handle any error that occurred
      } else if (snapshot.hasData) {
        List<String> userCalendars = snapshot.data ?? []; // Get the list of calendars

        return DropdownButton<String>(
          value: selectedCalendar,
          hint: const Text("Select Calendar"),
          items: [
            // Existing calendars from calendarLogic
            ...calendarLogic.calendars.entries.map((entry) {
              final calendarId = entry.key;
              final calendarName = entry.value.toString();
              return DropdownMenuItem<String>(
                value: calendarId,
                child: Text(calendarName),
              );
            }),

            // Add calendars owned by the current user (iCal feeds)
            if (userCalendars.isNotEmpty) 
              ...userCalendars.map((calendarName) {
                return DropdownMenuItem<String>(
                  value: calendarName,
                  child: Text(calendarName),
                );
              }),

            // Add New Calendar option
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
              // Show modal with options: Google, External Calendar, or iCal Link
              showModalBottomSheet(
                context: context,
                isScrollControlled: true, // Allows full-screen modal for the form
                builder: (BuildContext context) {
                  return Column(
                    children: <Widget>[
                      ListTile(
                        title: const Text("Add Google Calendar"),
                        onTap: () {
                          Navigator.pop(context);
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            builder: (BuildContext context) {
                              return addCalendarForm(calendarLogic); // Show Google calendar form
                            },
                          );
                        },
                      ),
                      ListTile(
                        title: const Text("Add External Calendar"),
                        onTap: () {
                          Navigator.pop(context);
                          _showFilePicker(); // Show file picker for external calendar
                        },
                      ),
                      ListTile(
                        title: const Text("Add iCal Feed Link"),
                        onTap: () {
                          Navigator.pop(context);
                          _showIcalFeedLinkForm(); // Show input form for iCal feed link
                        },
                      ),
                    ],
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
      } else {
        return const Text('No calendars found.'); // Handle case where no calendars are found
      }
    },
  );
}

void _showIcalFeedLinkForm() {
  final TextEditingController linkController = TextEditingController();
  final TextEditingController nameController = TextEditingController();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (BuildContext context) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // Header text
            Text(
              'Enter iCal Feed URL and Calendar Name',
              style: Theme.of(context).textTheme.titleLarge, // Replace headline6 with titleLarge
            ),
            SizedBox(height: 8),
            
            // Calendar name input
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                hintText: 'Enter calendar name',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 8),

            // iCal feed URL input
            TextField(
              controller: linkController,
              decoration: InputDecoration(
                hintText: 'Enter the iCal feed URL',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            
            // Submit button
            ElevatedButton(
              onPressed: () {
                String name = nameController.text.trim();
                String url = linkController.text.trim();

                // Validate both fields
                if (name.isNotEmpty && url.isNotEmpty && Uri.tryParse(url)?.hasAbsolutePath == true) {
                  // Process iCal feed link here (e.g., save it to Firestore)
                  _saveIcalFeedLink(name, url);
                  Navigator.pop(context); // Close the bottom sheet
                } else {
                  // Show an error message if any field is invalid
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please enter a valid name and iCal feed URL')),
                  );
                }
              },
              child: Text('Add iCal Feed'),
            ),
          ],
        ),
      );
    },
  );
}

// Function to save the iCal feed URL and name to Firestore
void _saveIcalFeedLink(String name, String url) async {
  try {
    String? userEmail = _calendarLogic.currentUser?.email;

    if (userEmail == null) {
      // Handle the case where the user is not logged in
      print('User is not logged in.');
      return;
    }

    // Save the iCal feed link to Firestore
    await FirebaseFirestore.instance.collection('ical_feeds').add({
      'owner': userEmail,
      'name': name,
      'url': url,
      'addedAt': Timestamp.now(),
    });

    // Trigger a rebuild by calling setState
    setState(() {
      // After adding the iCal feed, the list will refresh
    });

    // Optionally, show a success message to the user
    print('iCal feed URL saved successfully!');
  } catch (e) {
    print('Error saving iCal feed URL: $e');
  }
}

Future<List<String>> _getIcalFeeds() async {
  try {
    // Get the current user's email
    String? userEmail = _calendarLogic.currentUser?.email;

    if (userEmail == null) {
      // Handle the case where the user is not logged in
      print('User is not logged in.');
      return [];
    }

    // Query the Firestore collection for documents with the userEmailPrefix field
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('ical_feeds')
        .where('owner', isEqualTo: userEmail)
        .get();

    // Convert the query results to a list of maps
    List<String> icalFeeds = querySnapshot.docs.map((doc) {
      return doc['name'] as String;
    }).toList();

    return icalFeeds;
  } catch (e) {
    print('Error querying iCal feeds: $e');
    return [];
  }
}

// Function to show file picker for external calendar upload
void _showFilePicker() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['csv', 'ics'], // Allow both CSV and ICS (iCal) files
  );
  if (result != null && result.files.isNotEmpty) {
    // Handle the selected file
    final file = result.files.single;
    File fileToUpload = File(file.path!);
    String fileName = path.basename(fileToUpload.path);

    // Upload to Firebase Storage (as described in previous steps)
    final storageRef = FirebaseStorage.instance.ref().child('calendar_files/$fileName');
    await storageRef.putFile(fileToUpload);
    String fileUrl = await storageRef.getDownloadURL();

    // Optionally save file URL to Firestore (metadata) if needed
    await FirebaseFirestore.instance.collection('calendar_files').add({
      'url': fileUrl,
      'name': fileName,
      'uploadedAt': Timestamp.now(),
    });
  }
}

/*
*  Map and card stack building of calendar events
*/
  Widget buildEventsList(List<gcal.Event> events) {
    return Expanded(
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
    );
  }

  /*
  * Add calendar dropdown option, calls the modal widget and handles onsubmit action to create the calendar
  */ 

  Widget addCalendarForm(CalendarLogic calendarLogic) {
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
              await calendarLogic.createCalendar(
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
                calendarLogic.calendars = {}; // Clear and reload
                calendarLogic.createCalendarApiInstance().then(
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
  }

  @override
  Widget build(BuildContext context) {
    return 
        buildCalendarUI();
        // : Scaffold(
        //     // appBar: AppBar(title: const Text('Google Calendar Integration')),
        //     body: Center(
        //       child: ElevatedButton(
        //         onPressed: () async {
        //           await _calendarLogic.handleSignIn();
        //           setState(() {});
        //         },
        //         child: const Text('Sign In with Google'),
        //       ),
        //     ),
        //   );
  }
}


