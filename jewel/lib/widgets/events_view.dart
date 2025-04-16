import 'package:flutter/material.dart';
import 'package:googleapis/calendar/v3.dart' as gcal;
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:jewel/google/calendar/googleapi.dart';
import 'package:jewel/models/jewel_user.dart';
import 'package:jewel/widgets/home_screen.dart';
import 'package:provider/provider.dart';
import 'package:jewel/google/calendar/mode_toggle.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:jewel/widgets/color_picker.dart';
import 'package:jewel/widgets/event_grouping.dart';
import 'package:jewel/models/event_group.dart';
import 'package:jewel/event_history/event_history.dart';
import 'package:jewel/firebase_ops/event_history_ops.dart';
import 'package:jewel/google/calendar/calendar_logic.dart';
import 'package:jewel/google_events/events_form.dart';

/*
  This widget class builds a Calendar widget
  It does not create the controls
*/
class CalendarEventsView extends StatefulWidget {
  const CalendarEventsView({
    super.key,
  });
  @override
  _CalendarEventsView createState() => _CalendarEventsView();
}

class _CalendarEventsView extends State<CalendarEventsView> {
  late ScrollController _scrollController;
  late JewelUser? jewelUser;
  late CalendarLogic calendarLogic;
  @override
  void initState() {
    super.initState();
    final notifier = Provider.of<SelectedIndexNotifier>(context, listen: false);
    jewelUser = Provider.of<JewelUser>(context, listen: false);
    calendarLogic = jewelUser!.calendarLogicList![0];
    _scrollController =
        ScrollController(initialScrollOffset: notifier.getScrollPosition(1));
    print(
        '[Events View] Jewel user matched to calendar tools: ${jewelUser?.calendarLogicList?[0].selectedCalendar}');
    print(
        '[Events View] Init State events: ${jewelUser?.calendarLogicList?[0].events.toString()}');
    getGoogleEventsData(calendarLogic, context);
  }

  @override
  Widget build(BuildContext context) {
    final isMonthlyViewPrivate = context.watch<ModeToggle>().isMonthlyView;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Events'),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(left: 10, right: 10),
            child: FloatingActionButton(
              elevation: 5.0,
              backgroundColor: Colors.green,
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        AddEvent(calendarApi: calendarLogic.calendarApi),
                  ),
                );

                if (result == true) {
                  setState(() {
                    getGoogleEventsData(calendarLogic, context);
                  });
                }
              },
              tooltip: 'Add Event',
              mini: true,
              child: const Icon(Icons.add),
            ),
          ),
        ],
      ),
      body: Consumer<JewelUser>(builder: (context, jewelUser, child) {
        return Column(
          children: [
            Expanded(
              child: isMonthlyViewPrivate
                  ? buildMonthlyView(context)
                  : buildDailyView(context),
            ),
          ],
        );
      }),
    );
  }

  // Builds the daily view
  Widget buildDailyView(BuildContext context) {
    return FutureBuilder<List<gcal.Event>>(
        future: getGoogleEventsData(calendarLogic,
            context), // Create a method that returns your Future<List<Event>>
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
                child: Text('Error loading events: ${snapshot.error}'));
          }
          final events = snapshot.data;

          return SingleChildScrollView(
            controller: _scrollController,
            scrollDirection: Axis.vertical,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 50,
                  color: Colors.grey[200],
                  child: Column(
                    children: List.generate(24, (index) {
                      String timeLabel =
                          '${index.toString().padLeft(2, '0')}:00';
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 41.5),
                        child: Text(
                          timeLabel,
                          style: const TextStyle(
                              fontSize: 12, color: Colors.black54),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }),
                  ),
                ),
                // Calendar Events column
                Expanded(child: buildEventsList(events!)),
              ],
            ),
          );
        });
  }

// Builds the monthly view
  Widget buildMonthlyView(BuildContext context) {
    final calendarLogic = jewelUser?.calendarLogicList?[0];
    final DateTime now = calendarLogic!.selectedDate;
    final DateTime firstDayOfMonth = DateTime(now.year, now.month, 1);
    final int daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final int firstWeekday = (firstDayOfMonth.weekday % 7) + 1;
    final int totalCells = daysInMonth + firstWeekday;
    final int rows = (totalCells / 7).ceil();

    return FutureBuilder<List<gcal.Event>>(
      future: getGoogleEventsForMonth(
          calendarLogic, context), // Use the new function
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(
            child: Text(
              'EventsViewError: ${snapshot.error}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          );
        } else if (snapshot.hasData) {
          // Get events for the entire month
          Map<int, List<gcal.Event>> eventsByDay =
              groupEventsByDay(snapshot.data!, now);

          return Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                    .map((day) => Expanded(
                          child: Center(
                            child: Text(day,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                          ),
                        ))
                    .toList(),
              ),
              Expanded(
                child: GridView.builder(
                  itemCount: rows * 7,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    childAspectRatio: 1,
                  ),
                  itemBuilder: (context, index) {
                    final int dayNumber = index - (firstWeekday - 2);
                    bool isValidDay = dayNumber > 0 && dayNumber <= daysInMonth;
                    List<gcal.Event>? events =
                        eventsByDay[dayNumber]; // Fetch events for the day

                    return Container(
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        color: isValidDay ? Colors.white : Colors.grey[300],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Align(
                              alignment: Alignment.topLeft,
                              child: Text(
                                isValidDay ? dayNumber.toString() : '',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      isValidDay ? Colors.black : Colors.grey,
                                ),
                              ),
                            ),
                            if (isValidDay && events != null)
                              ...buildEventTexts(events),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        } else {
          return const Center(
            child: Text(
              'No events found',
              textAlign: TextAlign.center,
            ),
          );
        }
      },
    );
  }

  // Helper function to build event texts
  List<Widget> buildEventTexts(List<gcal.Event> events) {
    if (events.isEmpty) return [];

    return [
      // Highlight entire cell background color
      Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Color.fromARGB(255, 57, 145, 102), // Highlight color
          borderRadius: BorderRadius.circular(6),
        ),
        padding: const EdgeInsets.all(4),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.center, // Center the text box horizontally
          children: [
            if (events.length > 3)
              Center(
                child: Container(
                  padding: EdgeInsets.symmetric(
                      vertical: 2, horizontal: 6), // Smaller padding
                  decoration: BoxDecoration(
                    color: Color.fromARGB(255, 57, 145, 102),
                    borderRadius:
                        BorderRadius.circular(4), // Smaller border radius
                  ),
                  child: Text(
                    'Multiple Events Scheduled',
                    style: TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center, // Center text inside box
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
            else
              ...events.map((event) => Center(
                    child: Container(
                      width: double
                          .infinity, // Full-width inside the highlighted box
                      margin: EdgeInsets.symmetric(
                          vertical: 1), // Reduced vertical margin
                      padding: EdgeInsets.symmetric(
                          vertical: 2, horizontal: 4), // Smaller padding
                      decoration: BoxDecoration(
                        color: Color.fromARGB(255, 57, 145, 102),
                        borderRadius:
                            BorderRadius.circular(4), // Smaller border radius
                      ),
                      child: Text(
                        event.summary ?? 'No Title',
                        style: TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center, // Center text
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )),
          ],
        ),
      ),
    ];
  }

  // Group the events by day for the monthly view
  Map<int, List<gcal.Event>> groupEventsByDay(
      List<gcal.Event> events, DateTime month) {
    Map<int, List<gcal.Event>> eventsByDay = {};

    // Initialize all days in the month
    for (int day = 1;
        day <= DateTime(month.year, month.month + 1, 0).day;
        day++) {
      eventsByDay[day] = [];
    }

    for (var event in events) {
      final start = event.start?.dateTime?.toLocal();
      if (start != null) {
        // Ensure the event belongs to the correct month
        if (start.year == month.year && start.month == month.month) {
          final int day = start.day;
          eventsByDay[day]!.add(event);
        }
      }
    }

    return eventsByDay;
  }

  // Builds the list of events for the day view
  Widget buildEventsList(List<gcal.Event> events) {
    return Column(
      children: List.generate(24, (hourIndex) {
        // hourIndex lets us place the events with a startTime of hourIndex and at the corresponding index in the list
        return Container(
          height: 100.0,
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
          ),
          child: Stack(
            children: events.where((event) {
              final start = event.start?.dateTime?.toLocal();
              final end = event.end?.dateTime?.toLocal();
              return start != null &&
                  end != null &&
                  start.hour <= hourIndex &&
                  end.hour > hourIndex;
            }).map((event) {
              // this takes the determined events and processes the cards, then turns them into a list down at .toList()
              final start = event.start?.dateTime?.toLocal();
              final end = event.end?.dateTime?.toLocal();

              // Calculate the duration of the event to determine how many cards to build
              final durationInHours = end != null && start != null
                  ? end.difference(start).inHours
                  : 1;

              // Determine the height dynamically (spans blocks fully if additional entry)
              final height = durationInHours > 1
                  ? 100.0 * durationInHours
                  : 100.0; // Ensure single-hour events fill the block fully

              Color eventColor;
              String? groupTitle;
              if (event.extendedProperties?.private?['groupColor'] != null) {
                final groupColorString =
                    event.extendedProperties!.private!['groupColor']!;
                final groupColorValues = groupColorString
                    .split(',')
                    .map((e) => int.parse(e.trim()))
                    .toList();
                eventColor = Color.fromARGB(255, groupColorValues[0],
                    groupColorValues[1], groupColorValues[2]);
                groupTitle = event.extendedProperties!.private!['group'];
              } else {
                final colorString =
                    event.extendedProperties?.private?['color'] ??
                        '57, 145, 102';
                final colorValues = colorString
                    .split(',')
                    .map((e) => int.parse(e.trim()))
                    .toList();
                eventColor = Color.fromARGB(
                    255, colorValues[0], colorValues[1], colorValues[2]);
              }

              return Positioned.fill(
                // builds the actual card that will be added to the list
                child: Card(
                    margin: const EdgeInsets.all(0),
                    color: eventColor,
                    child: (hourIndex == start!.hour)
                        ? ListTile(
                            title: Text(
                              event.summary ?? 'No Title',
                              style: const TextStyle(color: Colors.white),
                            ),
                            subtitle: Text(
                              '${start != null ? DateFormat('hh:mm a').format(start) : 'No Time'} - '
                              '${end != null ? DateFormat('hh:mm a').format(end) : 'No Time'}'
                              '${groupTitle != null ? '\n$groupTitle' : ''}',
                              style: const TextStyle(color: Colors.white70),
                            ),
                            onTap: () {
                              _editEvent(context, event);
                              print("Event tapped");
                            },
                            trailing: IconButton(
                              icon: Icon(Icons.history),
                              onPressed: () {
                                _showHistoryDialog(context, event.id!);
                              },
                            ),
                          )
                        : null),
              );
            }).toList(),
          ),
        );
      }),
    );
  }

  Future<void> _editEvent(BuildContext context, gcal.Event event) async {
    final calendarLogic = jewelUser?.calendarLogicList?[0];
    final events = await getGoogleEventsData(calendarLogic!, context);

    TextEditingController titleController =
        TextEditingController(text: event.summary ?? "No Title");

    final oldSummary = event.summary ?? "No Title";

    DateTime startTime = event.start?.dateTime ?? DateTime.now();
    DateTime endTime =
        event.end?.dateTime ?? DateTime.now().add(Duration(hours: 1));

    final colorString =
        event.extendedProperties?.private?['color'] ?? '57, 145, 102';
    final colorValues =
        colorString.split(',').map((e) => int.parse(e.trim())).toList();
    Color eventColor =
        Color.fromARGB(255, colorValues[0], colorValues[1], colorValues[2]);

    // Options for groups that are already made
    List<EventGroup> availableGroups = getAvailableGroups(events);
    EventGroup? selectedGroup;

    final oldGroup = event.extendedProperties?.private?['group'];
    final oldGroupColor = event.extendedProperties?.private?['groupColor'];

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Edit Event"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Event Title
              TextFormField(
                controller: titleController,
                decoration: InputDecoration(labelText: "Event Title"),
              ),

              // Start Time Picker
              ListTile(
                title: Text(
                    "Start Time: ${DateFormat('yyyy-MM-dd HH:mm').format(startTime)}"),
                trailing: Icon(Icons.calendar_today),
                onTap: () async {
                  DateTime? picked =
                      await showDateTimePicker(context, startTime);
                  if (picked != null) {
                    startTime = picked;
                  }
                },
              ),

              // End Time Picker
              ListTile(
                title: Text(
                    "End Time: ${DateFormat('yyyy-MM-dd HH:mm').format(endTime)}"),
                trailing: Icon(Icons.calendar_today),
                onTap: () async {
                  DateTime? picked = await showDateTimePicker(context, endTime);
                  if (picked != null) {
                    endTime = picked;
                  }
                },
              ),
              ListTile(
                title: Text("Event Reminder"),
                trailing: Icon(Icons.alarm),
                onTap: () => _showReminderDialog(context, event),
              ),
              ListTile(
                title: Text("Event Color"),
                trailing: Icon(Icons.color_lens),
                onTap: () async {
                  Color? pickedColor = await showDialog(
                    context: context,
                    builder: (context) =>
                        ColorPickerDialog(initialColor: eventColor),
                  );
                  if (pickedColor != null) {
                    eventColor = pickedColor;
                  }
                },
              ),
              ListTile(
                title: Text("Add to Group"),
                trailing: Icon(Icons.group_add),
                onTap: () async {
                  EventGroup? newGroup = await showDialog(
                    context: context,
                    builder: (context) => CreateGroupDialog(),
                  );
                  if (newGroup != null) {
                    // Assign the event to the created group
                    event.extendedProperties!.private!['group'] =
                        newGroup.title;
                    event.extendedProperties!.private!['groupColor'] =
                        '${newGroup.color.red}, ${newGroup.color.green}, ${newGroup.color.blue}';
                  }
                },
              ),
              DropdownButton<EventGroup>(
                hint: Text("Select Group"),
                value: selectedGroup,
                onChanged: (EventGroup? newValue) {
                  setState(() {
                    selectedGroup = newValue;
                  });
                },
                items: availableGroups.map((EventGroup group) {
                  return DropdownMenuItem<EventGroup>(
                    value: group,
                    child: Text(group.title),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), // Close dialog
              child: Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                // Update event with new details
                final history = await getHistoryFromFireBase(event.summary!);
                final updatedEvent = gcal.Event();
                updatedEvent.summary = titleController.text;
                updatedEvent.start = gcal.EventDateTime();
                updatedEvent.start?.dateTime = startTime.toUtc();
                updatedEvent.start?.timeZone = "UTC";
                updatedEvent.end = gcal.EventDateTime();
                updatedEvent.end?.dateTime = endTime.toUtc();
                updatedEvent.end?.timeZone = "UTC";

                updatedEvent.extendedProperties =
                    gcal.EventExtendedProperties();
                updatedEvent.extendedProperties!.private = {
                  'color':
                      '${eventColor.red}, ${eventColor.green}, ${eventColor.blue}'
                };

                // Check if the event is part of a group and include the group's color
                if (selectedGroup != null) {
                  updatedEvent.extendedProperties!.private!['group'] =
                      selectedGroup!.title;
                  updatedEvent.extendedProperties!.private!['groupColor'] =
                      '${selectedGroup!.color.red}, ${selectedGroup!.color.green}, ${selectedGroup!.color.blue}';
                } else if (event.extendedProperties?.private?['group'] !=
                        null &&
                    event.extendedProperties?.private?['groupColor'] != null) {
                  updatedEvent.extendedProperties!.private!['group'] =
                      event.extendedProperties!.private!['group']!;
                  updatedEvent.extendedProperties!.private!['groupColor'] =
                      event.extendedProperties!.private!['groupColor']!;
                }

                final calendarLogic = jewelUser?.calendarLogicList?[0];

                final newSummary = updatedEvent.summary ?? "No Title";

                String changeLog = "Updated:\n"
                    "Title: $oldSummary → $newSummary\n"
                    "Start: ${formatDateTime(event.start?.dateTime?.toLocal())} → ${formatDateTime(updatedEvent.start?.dateTime?.toLocal())}\n"
                    "End: ${formatDateTime(event.end?.dateTime?.toLocal())} → ${formatDateTime(updatedEvent.end?.dateTime?.toLocal())}";

                if (colorString !=
                    '${eventColor.red}, ${eventColor.green}, ${eventColor.blue}') {
                  changeLog += "\nColor Changed";
                }
                if (oldGroup !=
                        updatedEvent.extendedProperties?.private?['group'] ||
                    oldGroupColor !=
                        updatedEvent
                            .extendedProperties?.private?['groupColor']) {
                  changeLog += "\nGroup Changed";
                }

                calendarLogic!.addToHistory(event.id!, changeLog);

                try {
                  await calendarLogic.calendarApi.events.patch(
                    updatedEvent,
                    'primary', // Change if using another calendar ID
                    event.id!,
                  );

                  Navigator.pop(context); // Close dialog
                  setState(() {}); // Refresh UI

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Event Updated Successfully!')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error updating event: $e')),
                  );
                }
              },
              child: Text("Save"),
            ),
          ],
        );
      },
    );
  }

  void _showHistoryDialog(BuildContext context, String eventId) {
    CalendarLogic? calendarLogic = jewelUser!.calendarLogicList?[0];
    final history = calendarLogic!.getHistory(eventId);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Event History'),
          content: Container(
            constraints: BoxConstraints(
              maxHeight: 300, // Set a maximum height for the scrollable area
            ),
            child: FutureBuilder<List<String>>(
              future: history,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Text('No changes recorded for this event.');
                } else {
                  return SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: snapshot.data!
                          .map((change) => Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Text(change),
                              ))
                          .toList(),
                    ),
                  );
                }
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<DateTime?> showDateTimePicker(
      BuildContext context, DateTime initial) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initial),
      );

      if (pickedTime != null) {
        return DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
      }
    }
    return null;
  }

  String formatDateTime(DateTime? dateTime) {
    return dateTime != null
        ? DateFormat('MM/dd/yyyy HH:mm').format(dateTime)
        : "Unknown";
  }

  List<EventGroup> getAvailableGroups(List<gcal.Event> events) {
    // Extract group information from the events
    final Map<String, EventGroup> groups = {};
    for (var event in events) {
      if (event.extendedProperties?.private?['group'] != null &&
          event.extendedProperties?.private?['groupColor'] != null) {
        final groupTitle = event.extendedProperties!.private!['group']!;
        final groupColorString =
            event.extendedProperties!.private!['groupColor']!;
        final groupColorValues = groupColorString
            .split(',')
            .map((e) => int.parse(e.trim()))
            .toList();
        final groupColor = Color.fromARGB(
            255, groupColorValues[0], groupColorValues[1], groupColorValues[2]);
        groups[groupTitle] = EventGroup(title: groupTitle, color: groupColor);
      }
    }
    return groups.values.toList();
  }

  Future<void> _showReminderDialog(BuildContext context, gcal.Event event) async {
  // Define variables to track user selections
  int selectedMinutes = 15; // Default: 15 minutes before
  int notificationCount = 1; // Default: 1 notification
  TextEditingController customReminder = TextEditingController(); // Placeholder for custom reminder text
  // Check if event already has reminder settings
  if (event.extendedProperties?.private != null) {
    selectedMinutes = int.tryParse(
        event.extendedProperties!.private!['reminderMinutes'] ?? '15') ?? 15;
    notificationCount = int.tryParse(
        event.extendedProperties!.private!['reminderCount'] ?? '1') ?? 1;
    customReminder = TextEditingController(
        text: event.extendedProperties!.private!['customReminder'] ?? "");
  }
  
  // Show reminder settings dialog
  await showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text("Set Reminder"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Set a custom event reminder:"),
                SizedBox(height: 10),

                TextFormField(
                  decoration: InputDecoration(labelText: "Custom Reminder"),
                  controller: customReminder,
                  onChanged: (value) {
                    setState(() {
                      customReminder.text = value;
                    });
                  },
                ),
                SizedBox(height: 10),
                Text("Notify me before the event:"),
                SizedBox(height: 10),
                
                // Time before event selector
                DropdownButton<int>(
                  isExpanded: true,
                  value: selectedMinutes,
                  items: [
                    DropdownMenuItem(value: 5, child: Text("5 minutes before")),
                    DropdownMenuItem(value: 10, child: Text("10 minutes before")),
                    DropdownMenuItem(value: 15, child: Text("15 minutes before")),
                    DropdownMenuItem(value: 30, child: Text("30 minutes before")),
                    DropdownMenuItem(value: 45, child: Text("45 minutes before")),
                    DropdownMenuItem(value: 60, child: Text("1 hour before")),
                    DropdownMenuItem(value: 120, child: Text("2 hours before")),
                    DropdownMenuItem(value: 1440, child: Text("1 day before")),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedMinutes = value!;
                    });
                  },
                ),
                
                SizedBox(height: 20),
                
                Text("Number of reminders:"),
                SizedBox(height: 10),
                
                // Number of notifications selector
                DropdownButton<int>(
                  isExpanded: true,
                  value: notificationCount,
                  items: [1, 2, 3].map((count) {
                    return DropdownMenuItem(
                      value: count,
                      child: Text("$count ${count == 1 ? 'reminder' : 'reminders'}"),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      notificationCount = value!;
                    });
                  },
                ),
                
                if (notificationCount == 2 ) ...[
                  SizedBox(height: 10),
                  Text("Reminders will be sent at: $selectedMinutes and ${(selectedMinutes / 2).toInt()} minutes prior to the event"), 
                ],
                if (notificationCount == 3 ) ...[
                  SizedBox(height: 10),
                  Text("Reminders will be sent at: $selectedMinutes, ${(selectedMinutes / 2).toInt()}, and ${(selectedMinutes / 4).toInt()} minutes prior to the event"), 
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () async {
                  // Initialize extendedProperties if needed
                  if (event.extendedProperties == null) {
                    event.extendedProperties = gcal.EventExtendedProperties();
                  }
                  if (event.extendedProperties!.private == null) {
                    event.extendedProperties!.private = {};
                  }
                  
                  // Save notification settings to the event
                  event.extendedProperties!.private!['reminderMinutes'] = 
                      selectedMinutes.toString();
                  event.extendedProperties!.private!['reminderCount'] = 
                      notificationCount.toString();
                  event.extendedProperties!.private!['customReminder'] =
                      customReminder.text;
                  
                  // Calculate notification times based on user preferences
                  List<int> notificationMinutes = [];
                  if (notificationCount == 1) {
                    notificationMinutes = [selectedMinutes];
                  } else if (notificationCount == 2) {
                    notificationMinutes = [selectedMinutes, selectedMinutes * 2];
                  } else if (notificationCount == 3) {
                    notificationMinutes = [
                      selectedMinutes, 
                      (selectedMinutes / 2).toInt(), 
                      (selectedMinutes / 4).toInt()
                    ];
                  }
                  
                  // Store the calculated minutes as a comma-separated string
                  event.extendedProperties!.private!['notificationTimes'] = 
                      notificationMinutes.join(',');

                  final updatedEvent = gcal.Event();
                  updatedEvent.extendedProperties = gcal.EventExtendedProperties();
                  updatedEvent.extendedProperties!.private = 
                      Map<String, String>.from(event.extendedProperties!.private!);
                 try {
                    // Update the event on Google Calendar
                    final calendarLogic = jewelUser!.calendarLogicList![0];
                    await calendarLogic.calendarApi.events.patch(
                      updatedEvent,
                      'primary',  // Or use the specific calendar ID
                      event.id!,
                    );
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(
                        'Reminder set: ${notificationCount} ${notificationCount == 1 ? "notification" : "notifications"}'
                      )),
                    );
                    
                    Navigator.pop(context);
                  } catch (e) {
                    print("Error updating event reminders: $e");
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Failed to save reminder settings: ${e.toString()}")),
                    );
                  }
                },
                child: Text("Save"),
              ),
            ],
          );
        }
      );
    },
  );
}
// @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();
//     // Save reference to the notifier here to avoid accessing context in dispose
//     final scrollNotifier = Provider.of<SelectedIndexNotifier>(context, listen: false);
//   }

//    @override
//   void dispose() {
//     // Save the current scroll position before disposing the controller
//     final scrollNotifier = Provider.of<SelectedIndexNotifier>(context, listen: false); // Renamed variable
//     scrollNotifier.setScrollPosition(1, _scrollController.offset); // Save scroll position
//     _scrollController.dispose();
//     super.dispose();
//   }
}
