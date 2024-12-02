import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jewel/google/calendar/g_g_merge.dart';

// ******************** //
// FOR TESTING ONLY    //


class CalendarEventList extends StatefulWidget {
  const CalendarEventList({super.key});

  @override
  _CalendarEventListState createState() => _CalendarEventListState();
}

class _CalendarEventListState extends State<CalendarEventList> {
  List<dynamic> events = []; // To store event data
  bool isLoading = true; // To show loading indicator
  String conflictMessage = ""; // Initialize as empty string

  @override
  void initState() {
    super.initState();
    fetchEventData(); // Fetch the event data on init
  }

  Future<void> fetchEventData() async {
    try {
      DocumentSnapshot documentSnapshot = await FirebaseFirestore.instance
          .collection('data') // Collection name
          .doc('mockEvents') // Document name
          .get();
      if (documentSnapshot.exists) {
        // Await the merge to get the values
        Map<String, dynamic> eventData = documentSnapshot.data() as Map<String, dynamic>;
        Map<String, dynamic> mergedEvents = await googleCalendarMerge(eventData);
        events = mergedEvents.values.toList(); // Now you can access values
      } else {
        print('Document does not exist');
      }
    } catch (e) {
      print('Error fetching event data: $e');
    } finally {
      setState(() {
        isLoading = false; // Stop loading
      });
    }
  }

  Future<void> checkConflicts() async {
    // Fetch event data as a map for conflict checking
    Map<String, dynamic> sortedEvents = { 
      for (var event in events) event['id']: event // Assuming each event has a unique 'id'
    };

    // Identify conflicts
    List<Map<String, dynamic>> conflicts = await identifyConflict(sortedEvents);

    // Update the UI based on conflicts
    if (conflicts.isNotEmpty) {
      showConflictDialog(conflicts); // Show conflict dialog
    } else {
      setState(() {
        conflictMessage = 'No conflicts found.'; // Update conflict message if no conflicts
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Events Calendar'),
        actions: [
          IconButton(
            icon: Icon(Icons.warning), // Icon for checking conflicts
            onPressed: checkConflicts, // Trigger conflict check
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator()) // Loading indicator
          : events.isEmpty
              ? Center(child: Text('No events found.')) // No events message
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        conflictMessage,
                        style: TextStyle(fontSize: 16, color: Colors.red),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: events.length,
                        itemBuilder: (context, index) {
                          final event = events[index];
                          return Card(
                            margin: EdgeInsets.all(8.0),
                            elevation: 4,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    event['summary'] ?? 'No Title',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    event['location'] ?? 'No Location',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Start: ${event['start']['dateTime']}',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  Text(
                                    'End: ${event['end']['dateTime']}',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }

  // Method to identify conflicts (existing method from EventListScreen)
  Future<List<Map<String, dynamic>>> identifyConflict(Map<String, dynamic> sortedEvents) async {
    List<Map<String, dynamic>> conflicts = []; // List to store conflicting events

    var entries = sortedEvents.entries.toList();

    for (int i = 0; i < entries.length - 1; i++) {
      // Current event
      var currentEvent = entries[i].value;
      var nextEvent = entries[i + 1].value;

      // Parse start and end times
      DateTime currentStart = DateTime.parse(currentEvent['start']['dateTime']);
      DateTime currentEnd = DateTime.parse(currentEvent['end']['dateTime']);
      DateTime nextStart = DateTime.parse(nextEvent['start']['dateTime']);
      DateTime nextEnd = DateTime.parse(nextEvent['end']['dateTime']);

      // Check for overlap
      if (currentStart.isBefore(nextEnd) && nextStart.isBefore(currentEnd)) {
        // Add the conflicting events
        conflicts.add(currentEvent);
        conflicts.add(nextEvent);
      }
    }

    return conflicts; // Return the list of conflicts
  }

  // Method to show conflict dialog (existing method from EventListScreen)
  void showConflictDialog(List<Map<String, dynamic>> conflicts) {
    String conflictDetails = 'Conflict detected between events:\n';

    // Construct the conflict details message
    for (var conflict in conflicts) {
      conflictDetails += '- ${conflict['summary']}\n';
    }

    // Show dialog for prioritization
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Conflict Detected'),
          content: Text(conflictDetails),
          actions: <Widget>[
            TextButton(
              child: Text('Prioritize Event 1'),
              onPressed: () {
                resolveConflict(conflicts[0], conflicts[1]);
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Prioritize Event 2'),
              onPressed: () {
                resolveConflict(conflicts[1], conflicts[0]);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Method to resolve conflict (existing method from EventListScreen)
  void resolveConflict(Map<String, dynamic> prioritizedEvent, Map<String, dynamic> conflictedEvent) {
    DateTime newStartTime = DateTime.parse(prioritizedEvent['end']['dateTime']);
    conflictedEvent['start']['dateTime'] = newStartTime.toIso8601String();

    // Update UI with the new event details
    setState(() {
      conflictMessage = '${conflictedEvent['summary']} has been updated to start after ${prioritizedEvent['summary']}.';
    });

    // Optionally, update Firestore with the new event details if needed
    // You can create an update function here to update the Firestore document
  }
}
