import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jewel/google/calendar/g_g_merge.dart';

class EventListScreen extends StatefulWidget {
  @override
  _EventListScreenState createState() => _EventListScreenState();
}

class _EventListScreenState extends State<EventListScreen> {
  String conflictMessage = "Checking for conflicts...";
  List<Map<String, dynamic>> conflicts = [];

  @override
  void initState() {
    super.initState();
    fetchAndCheckEvents();
  }

  Future<void> fetchAndCheckEvents() async {
    // Fetch event data
    Map<String, dynamic> sortedEvents = await fetchEventData();

    // Identify conflicts
    conflicts = await identifyConflict(sortedEvents);

    // Update UI based on conflicts
    if (conflicts.isNotEmpty) {
      showConflictDialog();
    } else {
      setState(() {
        conflictMessage = 'No conflicts found.';
      });
    }
  }

  void showConflictDialog() {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Event Conflict Manager'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            Text(
              conflictMessage,
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
