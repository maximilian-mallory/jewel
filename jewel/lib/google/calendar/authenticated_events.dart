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
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';

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

class AuthenticatedCalendar extends StatefulWidget {
  final CalendarLogic calendarLogic;

  const AuthenticatedCalendar({super.key, required this.calendarLogic});

  @override
  State createState() => _AuthenticatedCalendarState();
}

class _AuthenticatedCalendarState extends State<AuthenticatedCalendar> {
// This is what we use to make the method calls
  String? selectedCalendar;
  late gcal.CalendarApi calendarApi;
  @override
  void initState() {
    super.initState();// widget. calls the Widget level object, which is the shared API instance from HomeScreen
    googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount? account) async { // Auth State listener
      setState(() {
        widget.calendarLogic.currentUser = account;
        widget.calendarLogic.isAuthorized = account != null;
      });
      if (account != null) {
        // print("creating api instance");        
        // calendarApi = await _calendarLogic.createCalendarApiInstance(); // This is the auth state we give to the API instance
        print("fetch init");
        widget.calendarLogic.events = await getGoogleEventsData(widget.calendarLogic);
        print(widget.calendarLogic.events); 
        setState(() async {
        });
      }
    });
  }

  Future<void> getAllCalendars(gcal.CalendarApi calendarApi) async {
    if (widget.calendarLogic.currentUser == null) {
      widget.calendarLogic.calendars.clear();
      return;
    }

    try {
      var calendarList = await calendarApi.calendarList.list();
      widget.calendarLogic.calendars.clear(); // Clear any old data
      for (var calendarEntry in calendarList.items ?? []) {
        widget.calendarLogic.calendars[calendarEntry.id ?? "unknown"] = calendarEntry.summary ?? "Unnamed Calendar";
      }
    } catch (e) {
      print("Error fetching calendars: $e");
    }
  }

/*
 * buildCalendarUI is the highest level parent widget
 */
  Widget buildCalendarUI() {
  return Scaffold(
    appBar: AppBar(
      // toolbarHeight: 20.0,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Evenly space all elements
        children: [
          daymonthBackButton(), // Left arrow button

          loadCalendarMenu(), // Calendar menu dropdown

          Column(
            children: [
              // Text widget for the date
              Consumer<CalendarLogic>(
                builder: (context, calendarLogic, child) {
                  return Text(
                    DateFormat('MM/dd/yyyy').format(calendarLogic.selectedDate),
                    style: TextStyle(
                      fontSize: kIsWeb ? 16 : 13, // Adjust font size if needed
                      fontWeight: FontWeight.bold, // Optional: Set font weight
                    ),
                  );
                },
              ),
            ],
          ),

          dateToggle(), // Toggle button for changing the view (day/month)

          daymonthForwardButton(), // Right arrow button
        ],
      ),
    ),
  );
}

/*
 * The decrement button for date query
 */
  
  Widget daymonthBackButton() {
  bool isWeb = kIsWeb; // Check if the app is on the web

  return TextButton.icon(
    onPressed: () async {
      // Navigate backward
      widget.calendarLogic.selectedDate = changeDateBy(-1, widget.calendarLogic);
      print(widget.calendarLogic.selectedDate);
      widget.calendarLogic.events = await getGoogleEventsData(widget.calendarLogic);
      print(widget.calendarLogic.events.toList());
    },
    icon: Icon(
      Icons.arrow_back,
      color: Colors.green, // Add a color for visual emphasis
      size: isWeb ? 45 : 20, // Adjust icon size for web vs mobile
    ),
    label: const Text(
      "",
      style: TextStyle(color: Colors.green, fontSize: 1),
    ),
    style: TextButton.styleFrom(
      padding: EdgeInsets.symmetric(
        horizontal: isWeb ? 12.0 : 2.0, // Adjust padding for web vs mobile
        vertical: isWeb ? 8.0 : 1.0, // Adjust padding for web vs mobile
      ),
      backgroundColor: Colors.green.withOpacity(0.1), // Light green background
      
    ),
  );
}

Widget daymonthForwardButton() {
  bool isWeb = kIsWeb; // Check if the app is on the web

  return TextButton.icon(
    onPressed: () async {
      // Navigate backward
      widget.calendarLogic.selectedDate = changeDateBy(1, widget.calendarLogic);
      print(widget.calendarLogic.selectedDate);
      widget.calendarLogic.events = await getGoogleEventsData(widget.calendarLogic);
      print(widget.calendarLogic.events.toList());
    },
    icon: Icon(
      Icons.arrow_forward,
      color: Colors.green, // Add a color for visual emphasis
      size: isWeb ? 45 : 20, // Adjust icon size for web vs mobile
    ),
    label: const Text(
      "",
      style: TextStyle(color: Colors.green, fontSize: 1),
    ),
    style: TextButton.styleFrom(
      padding: EdgeInsets.symmetric(
        horizontal: isWeb ? 12.0 : 2.0, // Adjust padding for web vs mobile
        vertical: isWeb ? 8.0 : 1.0, // Adjust padding for web vs mobile
      ),
      backgroundColor: Colors.green.withOpacity(0.1), // Light green background
      
    ),
  );
}
  
/*
 * Toggle switch for day / month mode
 */
  Widget dateToggle() {
  bool isWeb = kIsWeb;
  return Padding(
    padding: EdgeInsets.all(isWeb ? 8.0 : 4.0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () async {
            DateTime? selectedDate = await showDatePicker(
              context: context,
              initialDate: widget.calendarLogic.currentDate,
              firstDate: DateTime(2000), // Earliest selectable date
              lastDate: DateTime(2100), // Latest selectable date
            );
            if (selectedDate != null) {
              widget.calendarLogic.selectedDate = selectedDate;
              setState(() {});
            }
          },
          child: Stack(
            alignment: Alignment.center, // Aligns the date text in the center
            children: [
              Icon(
                Icons.calendar_today,
                size: isWeb ? 45: 20, // Adjust icon size
                color: Colors.green,
              ),
              
            ],
          ),
        ),
      ],
    ),
  );
}

  /*
  * This widget handles asynchronous loading of the list of available calendars, but nothing more
  */
  Widget loadCalendarMenu() {
    bool isWeb = kIsWeb;
  return Padding(
    padding:  EdgeInsets.all(isWeb ?16.0 : 4.0),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(12.0), // Round corners of child content
      child: FutureBuilder<void>(
        future: getAllCalendars(widget.calendarLogic.calendarApi),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Instead of CircularProgressIndicator, return an empty list or widget
           return SizedBox(
              height: 100, // Set an appropriate height to reserve space
              child: Center(
                child: CircularProgressIndicator(), // Optional spinner
              ),
            ); // Empty list when data is loading
          } else if (snapshot.hasError) {
            return const Text("Error loading calendars");
          }

          return calendarSelectMenu(widget.calendarLogic); // The actual dropdown menu is here
        },
      ),
    ),
  );
}

  /*
   * The actual dropdown list or 'DropdownButton' list of calendar entries, or available calendars
   */
 Widget calendarSelectMenu(CalendarLogic calendarLogic) {
  bool isWeb = kIsWeb;
  return FutureBuilder<List<String>>(
    future: _getIcalFeeds(), // Call the async function to fetch calendar names
    builder: (BuildContext context, AsyncSnapshot<List<String>> snapshot) {
      if (snapshot.hasError) {
        return Text('Error: ${snapshot.error}'); // Handle any error that occurred
      } else if (snapshot.hasData) {
        List<String> userCalendars = snapshot.data ?? []; // Get the list of calendars

        return Container(
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(12.0), // Add rounded corners
    color: Colors.white, // Set background color of the container
    boxShadow: [
      BoxShadow(
        color: Colors.grey.withOpacity(0.2),
        spreadRadius: 2,
        blurRadius: 5,
      ),
    ], // Optional shadow for the dropdown
  ),
  child: ClipRect( // Ensures content respects the container boundaries
    child: SizedBox(
      width: kIsWeb ? 250:130, // Set a fixed width for the dropdown
      child: FittedBox( // Prevents overflow by resizing
        child: DropdownButton<String>(
          value: selectedCalendar,
          hint: const Text("Select Calendar"),
          dropdownColor: Colors.white, // Set background color of the dropdown
          iconEnabledColor: Colors.green, // Set color of the dropdown icon
          iconSize: kIsWeb ? 30 : 12, // Set size of the dropdown icon
          style: const TextStyle(
            color: Colors.black, // Set text color
            fontSize: 16, // Set text size
            fontWeight: FontWeight.bold, // Optional: Set font weight
          ),
          underline: Container(
            height: 2,
            color: Colors.green, // Color of the underline (border beneath the button)
          ),
          items: [
            ...calendarLogic.calendars.entries.map((entry) {
              final calendarId = entry.key;
              final calendarName = entry.value.toString();
              return DropdownMenuItem<String>(
                value: calendarId,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 15.0),
                  child: Text(
                    calendarName,
                    overflow: TextOverflow.ellipsis, // Add ellipsis for long text
                    maxLines: 1, // Ensure text remains on a single line
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              );
            }),

            if (userCalendars.isNotEmpty)
              ...userCalendars.map((calendarName) {
                return DropdownMenuItem<String>(
                  value: calendarName,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 15.0),
                    child: Text(
                      calendarName,
                      overflow: TextOverflow.ellipsis, // Add ellipsis for long text
                      maxLines: 1, // Ensure text remains on a single line
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black, // Text color for user calendars
                      ),
                    ),
                  ),
                );
              }),
            DropdownMenuItem<String>(
              value: "add_calendar",
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 15.0),
                child: Text(
                  "Add New Calendar",
                  overflow: TextOverflow.ellipsis, // Add ellipsis for long text
                  maxLines: 1, // Ensure text remains on a single line
                  style: TextStyle(
                    color: Colors.blue, // Add new calendar option text color
                    fontSize: 16,
                    fontWeight: FontWeight.w600, // Bold style for emphasis
                  ),
                ),
              ),
            ),
          ],
          onChanged: (String? newValue) async {
            if (newValue == "add_calendar") {
              // Handle add new calendar logic
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
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
              // Update selected calendar
              setState(() {
                selectedCalendar = newValue;
              });

              // Fetch the new events from the calendar API
              final newEvents = await getGoogleEventsData(widget.calendarLogic);

              // Update the calendar events
              setState(() {
                print("setting event state");
                widget.calendarLogic.events = newEvents;
              });
            }
          },
        ),
      ),
    ),
  ),
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
    String? userEmail = widget.calendarLogic.currentUser?.email;

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
    String? userEmail = widget.calendarLogic.currentUser?.email;

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

                          getAllCalendars(widget.calendarLogic.calendarApi);

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


