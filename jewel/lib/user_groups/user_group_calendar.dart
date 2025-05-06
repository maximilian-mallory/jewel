import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:jewel/user_groups/user_group.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserGroupCalendar extends StatefulWidget {
  final UserGroup userGroup;
  final memberColors;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserGroupCalendar(
      {Key? key, required this.userGroup, required this.memberColors})
      : super(key: key);

  @override
  _UserGroupCalendarState createState() => _UserGroupCalendarState();
}

class _UserGroupCalendarState extends State<UserGroupCalendar> {
  DateTime selectedDate = DateTime.now();
  Map<String, Color> memberColors = {};

  /// Retrieve all events for all members in the group
  Future<Map<String, Map<int, List<Map<String, dynamic>>>>>
      getHourlyGroupEvents() async {
    final Map<String, Map<int, List<Map<String, dynamic>>>> hourlyEvents = {};

    for (final member in widget.userGroup.getMembers) {
      final events = await getUserEvents(member);
      hourlyEvents[member] = {};

      for (final event in events) {
        final start = event['start'] as DateTime;
        final end = event['end'] as DateTime;

        // Only include events for the selected date
        if (start.year == selectedDate.year &&
            start.month == selectedDate.month &&
            start.day == selectedDate.day) {
          final startHour = start.hour;
          final endHour = end.hour;

          for (int hour = startHour; hour < endHour; hour++) {
            hourlyEvents[member]![hour] = (hourlyEvents[member]![hour] ?? [])
              ..add(event);
          }
        }
      }
    }

    return hourlyEvents;
  }

  @override
  Widget build(BuildContext context) {
    // Get the current theme
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // Removes the default back button
        title: Text('${widget.userGroup.getName} Calendar'),
        backgroundColor: theme.primaryColor, // Use the theme's primary color
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () async {
              final pickedDate = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (pickedDate != null) {
                setState(() {
                  selectedDate = pickedDate;
                });
              }
            },
          ),
        ],
      ),
      body: FutureBuilder<Map<String, Map<int, List<Map<String, dynamic>>>>>(
        future: getHourlyGroupEvents(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
                child: Text('No events found for the selected day.'));
          } else {
            final hourlyGroupEvents = snapshot.data!;
            return Container(
              margin: const EdgeInsets.all(
                  16.0), // Add some margin around the calendar
              decoration: BoxDecoration(
                color: isDarkMode
                    ? Colors.grey[900] // Dark mode background
                    : Colors.grey[100], // Light mode background
                borderRadius:
                    BorderRadius.circular(10), // Round off all corners
                border: Border.all(
                  color: isDarkMode
                      ? Colors.grey[700]! // Dark mode border
                      : Colors.grey[400]!, // Light mode border
                  width: 0.5,
                ),
              ),
              child: ClipRRect(
                borderRadius:
                    BorderRadius.circular(10), // Ensure corners are clipped
                child: ListView.builder(
                  itemCount: 24, // 24 hours in a day
                  itemBuilder: (context, hour) {
                    return Row(
                      children: [
                        // Hour label
                        Container(
                          width: 60,
                          height: 60,
                          alignment: Alignment.center,
                          color: isDarkMode
                              ? Colors.grey[800] // Dark mode background
                              : Colors.grey[200], // Light mode background
                          child: Text(
                            '${hour.toString().padLeft(2, '0')}:00',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isDarkMode
                                  ? Colors.white // Dark mode text color
                                  : Colors.black, // Light mode text color
                            ),
                          ),
                        ),
                        // Event columns for each member
                        ...widget.userGroup.getMembers.map((member) {
                          final events = hourlyGroupEvents[member]?[hour] ?? [];
                          final memberColor = widget.memberColors[member];
                          return Expanded(
                            child: Container(
                              height: 60,
                              color: events.isNotEmpty
                                  ? memberColor?.withOpacity(0.4)
                                  : (isDarkMode
                                      ? Colors.grey[850] // Dark mode background
                                      : Colors
                                          .grey[100]), // Light mode background
                              child: Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: events.map((event) {
                                    return Text(
                                      event['title'],
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: memberColor, // Use member color
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    );
                  },
                ),
              ),
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddEventDialog(context); // Open the Add Event dialog
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  /// Show a dialog to add an event for a specific member
  void _showAddEventDialog(BuildContext context) {
    final titleController = TextEditingController();
    DateTime? startDateTime;
    DateTime? endDateTime;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Event'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Event Title'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                  );
                  if (pickedDate != null) {
                    final pickedTime = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (pickedTime != null) {
                      setState(() {
                        startDateTime = DateTime(
                          pickedDate.year,
                          pickedDate.month,
                          pickedDate.day,
                          pickedTime.hour,
                          pickedTime.minute,
                        );
                      });
                    }
                  }
                },
                child: Text(
                  startDateTime == null
                      ? 'Select Start Date & Time'
                      : 'Start: ${startDateTime.toString()}',
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                  );
                  if (pickedDate != null) {
                    final pickedTime = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (pickedTime != null) {
                      setState(() {
                        endDateTime = DateTime(
                          pickedDate.year,
                          pickedDate.month,
                          pickedDate.day,
                          pickedTime.hour,
                          pickedTime.minute,
                        );
                      });
                    }
                  }
                },
                child: Text(
                  endDateTime == null
                      ? 'Select End Date & Time'
                      : 'End: ${endDateTime.toString()}',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (titleController.text.isNotEmpty &&
                    startDateTime != null &&
                    endDateTime != null) {
                  final currentUserEmail = FirebaseAuth.instance.currentUser!
                      .email!; // Get the current user's email
                  await addEventToUser(
                    currentUserEmail,
                    titleController.text,
                    startDateTime!,
                    endDateTime!,
                  );
                  setState(() {}); // Refresh the calendar
                  Navigator.of(context).pop(); // Close the dialog
                }
              },
              child: const Text('Add Event'),
            ),
          ],
        );
      },
    );
  }

  Future<void> createGroupCalendar() async {
    final groupName =
        widget.userGroup.getName; // Use the group name as the unique ID

    final groupDoc =
        widget._firestore.collection('group_calendar').doc(groupName);

    // Check if the group's calendar already exists
    final calendarSnapshot = await groupDoc.get();
    if (!calendarSnapshot.exists) {
      // Create a new calendar document for the group
      await groupDoc.set({
        'groupName': groupName,
        'createdAt': FieldValue.serverTimestamp(),
        'members': widget.userGroup.getMembers,
      });

      print('New calendar created for group: $groupName');
    } else {
      print('Calendar already exists for group: $groupName');
    }
  }

  Future<void> addEventToUser(
      String userEmail, String title, DateTime start, DateTime end) async {
    final groupName = widget.userGroup.getName;

    final event = {
      'title': title,
      'start': start.toIso8601String(),
      'end': end.toIso8601String(),
    };

    await widget._firestore
        .collection('group_calendar')
        .doc(groupName)
        .collection('user_events')
        .doc(userEmail)
        .collection('events')
        .add(event);

    print('Event added for user: $userEmail in group: $groupName');
  }

  Future<List<Map<String, dynamic>>> getUserEvents(String userEmail) async {
    final groupName =
        widget.userGroup.getName; // Use the group name as the unique ID

    final snapshot = await widget._firestore
        .collection('group_calendar')
        .doc(groupName)
        .collection('user_events')
        .doc(userEmail)
        .collection('events')
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'title': data['title'],
        'start': DateTime.parse(data['start']),
        'end': DateTime.parse(data['end']),
      };
    }).toList();
  }
}
