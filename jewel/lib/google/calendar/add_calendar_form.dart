import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as gcal;
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:jewel/google/calendar/googleapi.dart';
import 'package:jewel/google/calendar/ical_conversion.dart'; // Added import for iCal conversion
import 'package:jewel/google/calendar/mode_toggle.dart';
import 'package:jewel/models/jewel_user.dart';
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';
import 'package:jewel/google/calendar/calendar_logic.dart';
import 'package:jewel/google/calendar/google_sign_in.dart';
import 'package:jewel/google/calendar/ical_conversion.dart'; // Add this import

/// Returns a map of responsive values based on screen width.
/// Breakpoints based on specific device widths:
///  - >= 1440px: Extra Large Computer Screen
///  - >= 1024px: Large Computer Screen
///  - >= 768px: Tablet
///  - >= 425px: Large Smartphone
///  - >= 375px: Medium Smartphone
///  - < 375px (e.g., 320px): Small Smartphone
Map<String, double> getResponsiveValues(BuildContext context) {
  final double screenWidth = MediaQuery.of(context).size.width;
  double horizontalPadding, verticalPadding, iconSize, buttonPadding, titleFontSize;
  if (screenWidth >= 1440) {
    // Extra Large Computer Screen
    horizontalPadding = 64.0;
    verticalPadding = 40.0;
    iconSize = 40.0;
    buttonPadding = 12.0;
    titleFontSize = 22.0;
  } else if (screenWidth >= 1024) {
    // Large Computer Screen
    horizontalPadding = 48.0;
    verticalPadding = 32.0;
    iconSize = 36.0;
    buttonPadding = 10.0;
    titleFontSize = 20.0;
  } else if (screenWidth >= 768) {
    // Tablet
    horizontalPadding = 32.0;
    verticalPadding = 24.0;
    iconSize = 32.0;
    buttonPadding = 8.0;
    titleFontSize = 18.0;
  } else if (screenWidth >= 425) {
    // Large Smartphone
    horizontalPadding = 24.0;
    verticalPadding = 16.0;
    iconSize = 22.0;
    buttonPadding = 1.0;
    titleFontSize = 0.0;
  } else if (screenWidth >= 375) {
    // Medium Smartphone
    horizontalPadding = 16.0;
    verticalPadding = 12.0;
    iconSize = 19.0;
    buttonPadding = 1.0;
    titleFontSize = 0.0;
  } else {
    // Small Smartphone (e.g., 320px)
    horizontalPadding = 14.0;
    verticalPadding = 10.0;
    iconSize = 18.0;
    buttonPadding = 1.0;
    titleFontSize = 0.0;
  }
  return {
    'horizontalPadding': horizontalPadding,
    'verticalPadding': verticalPadding,
    'iconSize': iconSize,
    'buttonPadding': buttonPadding,
    'titleFontSize': titleFontSize,
  };
}

/// A responsive form allowing users to add a new calendar.
/// The layout adapts its paddings, icon sizes and widget dimensions based on the screen size.
class AddCalendarForm extends StatefulWidget {
  final void Function(String calendarName, String description, String timeZone)
      onSubmit;

  const AddCalendarForm({super.key, required this.onSubmit});

  @override
  _AddCalendarFormState createState() => _AddCalendarFormState();
}

class _AddCalendarFormState extends State<AddCalendarForm> {
  final _formKey = GlobalKey<FormState>();
  final _calendarNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _timeZoneController =
      TextEditingController(text: "America/New_York"); // Default timezone

  @override
  void dispose() {
    _calendarNameController.dispose();
    _descriptionController.dispose();
    _timeZoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final res = getResponsiveValues(context);
    return SingleChildScrollView( // Ensures the form is scrollable when keyboard appears
      padding: EdgeInsets.symmetric(
        horizontal: res['horizontalPadding']!,
        vertical: res['verticalPadding']!,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _calendarNameController,
              decoration: const InputDecoration(labelText: "Calendar Name"),
              validator: (value) => value == null || value.isEmpty
                  ? "Please enter a calendar name"
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: "Description"),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _timeZoneController,
              decoration: const InputDecoration(labelText: "Time Zone"),
              validator: (value) => 
              value == null || value.isEmpty ? "Please enter a time zone" : null,
            ),
            SizedBox(height: res['verticalPadding']!),
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

  const AuthenticatedCalendar({super.key,});

  @override
  State createState() => _AuthenticatedCalendarState();
}

class _AuthenticatedCalendarState extends State<AuthenticatedCalendar> {
  String? selectedCalendar;
  late gcal.CalendarApi calendarApi;
  late JewelUser jewelUser;
  late CalendarLogic calendarLogic;
  late int selectedCalendarIndex;

  @override
  void initState() {
    super.initState();
    jewelUser = Provider.of<JewelUser>(context, listen: false);
    selectedCalendarIndex = jewelUser.calendarLogicList!.length -1;
    calendarLogic = jewelUser.calendarLogicList![selectedCalendarIndex];
    // Listen for authentication state changes.
    googleSignInList[selectedCalendarIndex].onCurrentUserChanged.listen((GoogleSignInAccount? account) async {
      setState(() {
        calendarLogic.currentUser = account;
        calendarLogic.isAuthorized = account != null;
      });
      if (account != null) {
        // Fetch events once authenticated.
        calendarLogic.events =
            await getGoogleEventsData(calendarLogic, context);
        setState(() {});
      }
    });
  }

  Future<void> getAllCalendars(gcal.CalendarApi calendarApi) async {
    if (calendarLogic.currentUser == null) {
      calendarLogic.calendars.clear();
      return;
    }
    try {
      var calendarList = await calendarApi.calendarList.list();
      calendarLogic.calendars.clear(); // Clear any old data
      for (var calendarEntry in calendarList.items ?? []) {
        calendarLogic.calendars[calendarEntry.id ?? "unknown"] =
            calendarEntry.summary ?? "Unnamed Calendar";
      }
    } catch (e) {
      print("Error fetching calendars: \$e");
    }
  }

  /// Builds the main scaffold with an adaptive AppBar.
 Widget buildCalendarUI() {
    final res = getResponsiveValues(context);
    // Increase base icon size by 25%
    final adjustedIconSize = res['iconSize']! * 1.25;
    
    return Consumer<JewelUser>(
      builder: (context, jewelUser, child) {
        return Scaffold(
          appBar: AppBar(
            toolbarHeight: 100,
            title: LayoutBuilder(
              builder: (context, constraints) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(width: 1),
                    daymonthBackButton(res, adjustedIconSize),
                    loadCalendarMenu(res, adjustedIconSize),
                    Column(
                      children: [
                        Text(
                          DateFormat('MM/dd/yyyy').format(calendarLogic.selectedDate),
                          style: TextStyle(
                            fontSize: res['titleFontSize'],
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      ],
                    ),
                    dateToggle(res, adjustedIconSize),
                    modeToggleButton(res, adjustedIconSize),
                    daymonthForwardButton(res, adjustedIconSize),
                    SizedBox(width: 1),
                  ],
                  
                );
              },
            ),
          ),
        );
      }
    );
  }

  /// Back button with a background that scales with icon size.
  Widget daymonthBackButton(Map<String, double> res, double iconSize) {
    return InkWell(
      onTap: () async {
        calendarLogic.selectedDate =
            changeDateBy(-1, calendarLogic);
        calendarLogic.events =
            await getGoogleEventsData(calendarLogic, context);
        setState(() {
          jewelUser.updateCalendarLogic(calendarLogic, selectedCalendarIndex);
        });
      },
      child: Container(
        padding: EdgeInsets.all(res['buttonPadding']! * 0.8), // Reduced padding
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.arrow_back,
          color: Theme.of(context).primaryColor,
          size: iconSize,
        ),
      ),
    );
  }

  /// Forward button with a background that scales with icon size.
  Widget daymonthForwardButton(Map<String, double> res, double iconSize) {
    return InkWell(
      onTap: () async {
        calendarLogic.selectedDate =
            changeDateBy(1, calendarLogic);
        calendarLogic.events =
            await getGoogleEventsData(calendarLogic, context);
        setState(() {
          jewelUser.updateCalendarLogic(calendarLogic, selectedCalendarIndex);
        });
      },
      child: Container(
        padding: EdgeInsets.all(res['buttonPadding']! * 0.8), // Reduced padding
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.arrow_forward,
          color: Theme.of(context).primaryColor,
          size: iconSize,
        ),
      ),
    );
  }

  /// Button for toggling between monthly and daily view.
  Widget modeToggleButton(Map<String, double> res, double iconSize) {
    return Consumer<ModeToggle>(
      builder: (context, modeToggle, child) {
        return IconButton(
          icon: Icon(
            modeToggle.isMonthlyView ? Icons.calendar_month : Icons.calendar_view_day,
            size: iconSize,
          ),
          tooltip: modeToggle.isMonthlyView
              ? "Switch to Daily View"
              : "Switch to Monthly View",
          onPressed: () => modeToggle.toggleViewMode(),
          padding: EdgeInsets.all(res['buttonPadding']! * 0.5), // Reduced padding
        );
      },
    );
  }

  /// Date picker toggle.
  Widget dateToggle(Map<String, double> res, double iconSize) {
    return Consumer<JewelUser>(
      builder: (context, user, child) {
        return GestureDetector(
          onTap: () async {
            DateTime? selectedDate = await showDatePicker(
              context: context,
              initialDate: calendarLogic.selectedDate,
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (selectedDate != null) {
              calendarLogic.selectedDate = selectedDate;
              calendarLogic.events = await getGoogleEventsData(calendarLogic, context);

                // Update the provider
                user.updateCalendarLogic(calendarLogic, selectedCalendarIndex);

              print('[DATE PICKER] SelectedDate: ${calendarLogic.selectedDate} should match JewelUser SelectedDate: ${user.calendarLogicList![0].selectedDate}');
            }
          },
          child: Container(
            //padding: EdgeInsets.all(res['buttonPadding']! * 0.8), // Reduced padding
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.calendar_today,
              size: iconSize,
              color: Theme.of(context).primaryColor,
            ),
          ),
        );
      },
    );
  }

  /// Loads calendar menu with responsive design.
  Widget loadCalendarMenu(Map<String, double> res, double iconSize) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: res['buttonPadding']!), // Reduced padding
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.0),
        child: FutureBuilder<void>(
          future: getAllCalendars(calendarLogic.calendarApi),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return SizedBox(
                height: 100,
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              );
            } else if (snapshot.hasError) {
              return const Text("Error loading calendars");
            }
            return calendarSelectMenu(calendarLogic, res, iconSize);
          },
        ),
      ),
    );
  }

  /// Dropdown for selecting a calendar from the list.
  Widget calendarSelectMenu(CalendarLogic calendarLogic, Map<String, double> res, double iconSize) {
    return FutureBuilder<List<String>>(
      future: _getIcalFeeds(),
      builder: (BuildContext context, AsyncSnapshot<List<String>> snapshot) {
        if (snapshot.hasError) {
          return Text('CalendarSelect Error: ${snapshot.error}');
        } else if (snapshot.hasData) {
          List<String> userCalendars = snapshot.data ?? [];
                    return Container(
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(8.0), // Rounded corners
    border: Border.all(
      color: Theme.of(context).primaryColor, // Border color
      width: 2, // Border width
    ),
  ),
  clipBehavior: Clip.hardEdge, // Ensures the inner content respects rounded corners
  child: ClipRRect(
    borderRadius: BorderRadius.circular(8.0), // Clip the dropdown content as well
    child: SizedBox(
      width: res['iconSize']! * 6, // Make it wider
      child: DropdownButton<String>(
        value: selectedCalendar,
        hint: Center(
          child: Text(
            calendarLogic.selectedCalendar,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        dropdownColor: Colors.white,
        iconEnabledColor: Theme.of(context).primaryColor,
        iconSize: iconSize * 0.8, // Slightly smaller dropdown icon
        style: const TextStyle(
          color: Colors.black,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
        isExpanded: true, // Allow text to use full width
        isDense: true, // Compact dropdown
        items: [
          ...calendarLogic.calendars.entries.map((entry) {
            return DropdownMenuItem<String>(
              value: entry.key,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: 8.0, horizontal: 12.0), // Reduced padding
                child: Text(
                  entry.value.toString(),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            );
          }),
          if (userCalendars.isNotEmpty)
            ...userCalendars.map((calendarName) {
              return DropdownMenuItem<String>(
                value: calendarName,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 8.0, horizontal: 12.0), // Reduced padding
                  child: Text(
                    calendarName,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black,
                    ),
                  ),
                ),
              );
            }),
          DropdownMenuItem<String>(
            value: "add_calendar",
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  vertical: 8.0, horizontal: 12.0), // Reduced padding
              child: const Text(
                "Add New Calendar",
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: TextStyle(
                  color: Colors.blue,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
        onChanged: (String? newValue) async {
          if (newValue == "add_calendar") {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (BuildContext context) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    ListTile(
                      title: const Text("Add Google Calendar"),
                      onTap: () {
                        Navigator.pop(context);
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          builder: (BuildContext context) {
                            return addCalendarForm(calendarLogic);
                          },
                        );
                      },
                    ),
                    ListTile(
                      title: const Text("Add External Calendar"),
                      onTap: () {
                        Navigator.pop(context);
                        _showFilePicker();
                      },
                    ),
                    ListTile(
                      title: const Text("Add iCal Feed Link"),
                      onTap: () {
                        Navigator.pop(context);
                        _showIcalFeedLinkForm();
                      },
                    ),
                  ],
                );
              },
            );
          } else if (newValue != null) {
            setState(() {
              calendarLogic.selectedCalendar = newValue;
            });
            final newEvents =
                await getGoogleEventsData(calendarLogic, context);
            setState(() {
              calendarLogic.events = newEvents;
            });
          }
        },
      ),
    ),
  ),
);
        } else {
          return const Text('No calendars found.');
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
              Text(
                'Enter iCal Feed URL and Calendar Name',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  hintText: 'Enter calendar name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: linkController,
                decoration: const InputDecoration(
                  hintText: 'Enter the iCal feed URL',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  String name = nameController.text.trim();
                  String url = linkController.text.trim();

                  if (name.isNotEmpty &&
                      url.isNotEmpty &&
                      Uri.tryParse(url)?.hasAbsolutePath == true) {
                    _saveIcalFeedLink(name, url);
                    Navigator.pop(context);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              'Please enter a valid name and iCal feed URL')),
                    );
                  }
                },
                child: const Text('Add iCal Feed'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _saveIcalFeedLink(String name, String url) async {
    try {
      String? userEmail = calendarLogic.currentUser?.email;
      if (userEmail == null) {
        print('User is not logged in.');
        return;
      }
      await FirebaseFirestore.instance.collection('ical_feeds').add({
        'owner': userEmail,
        'name': name,
        'url': url,
        'addedAt': Timestamp.now(),
      });
      setState(() {});
      print('iCal feed URL saved successfully!');
    } catch (e) {
      print('Error saving iCal feed URL: \$e');
    }
  }

  Future<List<String>> _getIcalFeeds() async {
    try {
      String? userEmail = calendarLogic.currentUser?.email;
      if (userEmail == null) {
        print('User is not logged in.');
        return [];
      }
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('ical_feeds')
          .where('owner', isEqualTo: userEmail)
          .get();
      List<String> icalFeeds =
          querySnapshot.docs.map((doc) => doc['name'] as String).toList();
      return icalFeeds;
    } catch (e) {
      print('Error querying iCal feeds: \$e');
      return [];
    }
  }

  void _showFilePicker() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'ics'],
    );
    if (result != null && result.files.isNotEmpty) {
      final file = result.files.single;
      File fileToUpload = File(file.path!);
      String fileName = path.basename(fileToUpload.path);
      final storageRef = FirebaseStorage.instance.ref().child('calendar_files/\$fileName');
      await storageRef.putFile(fileToUpload);
      String fileUrl = await storageRef.getDownloadURL();
      await FirebaseFirestore.instance.collection('calendar_files').add({
        'url': fileUrl,
        'name': fileName,
        'uploadedAt': Timestamp.now(),
      });
    }
  }

  /// Widget to show the add calendar form using a modal bottom sheet.
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
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Calendar added successfully")),
            );
            setState(() {
              calendarLogic.calendars = {};
              getAllCalendars(calendarLogic.calendarApi);
            });
          } catch (error) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Failed to add calendar")),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return buildCalendarUI();
  }
}