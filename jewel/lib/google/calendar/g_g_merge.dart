import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

Map<String, dynamic> mock1 = {
  "kind": "calendar#event",
  "etag": "\"1234567890123456\"",
  "id": "event1234567890",
  "status": "confirmed",
  "htmlLink": "https://www.google.com/calendar/event?eid=event1234567890",
  "created": "2024-10-20T12:34:56Z",
  "updated": "2024-10-20T13:34:56Z",
  "summary": "Team Meeting",
  "description": "Weekly team sync-up to discuss project updates.",
  "location": "Zoom Meeting",
  "colorId": "5",
  "creator": {
    "id": "creator123",
    "email": "creator@example.com",
    "displayName": "John Doe",
    "self": true
  },
  "organizer": {
    "id": "organizer123",
    "email": "organizer@example.com",
    "displayName": "Project Manager",
    "self": false
  },
  "start": {
    "dateTime": "2024-10-21T10:00:00Z",
    "timeZone": "America/Los_Angeles"
  },
  "end": {
    "dateTime": "2024-10-21T11:00:00Z",
    "timeZone": "America/Los_Angeles"
  },
  "reminders": {
    "useDefault": false,
    "overrides": [
      {
        "method": "email",
        "minutes": 30
      },
      {
        "method": "popup",
        "minutes": 10
      }
    ]
  },
  "eventType": "default"
};

Map<String, dynamic> mock2 = {
  "kind": "calendar#event",
  "etag": "\"1234567890123457\"",
  "id": "event2234567890",
  "status": "confirmed",
  "htmlLink": "https://www.google.com/calendar/event?eid=event2234567890",
  "created": "2024-10-20T14:00:00Z",
  "updated": "2024-10-20T14:34:56Z",
  "summary": "Project Planning",
  "description": "Discussing the next sprint goals and deliverables.",
  "location": "Conference Room",
  "colorId": "2",
  "creator": {
    "id": "creator123",
    "email": "creator@example.com",
    "displayName": "John Doe",
    "self": true
  },
  "organizer": {
    "id": "organizer123",
    "email": "organizer@example.com",
    "displayName": "Project Manager",
    "self": false
  },
  "start": {
    "dateTime": "2024-10-21T12:00:00Z",
    "timeZone": "America/Los_Angeles"
  },
  "end": {
    "dateTime": "2024-10-21T13:00:00Z",
    "timeZone": "America/Los_Angeles"
  },
  "reminders": {
    "useDefault": true
  },
  "eventType": "default"
};

Map<String, dynamic> mock3 = {
  "kind": "calendar#event",
  "etag": "\"1234567890123458\"",
  "id": "event3234567890",
  "status": "confirmed",
  "htmlLink": "https://www.google.com/calendar/event?eid=event3234567890",
  "created": "2024-10-20T15:00:00Z",
  "updated": "2024-10-20T15:34:56Z",
  "summary": "Client Follow-up",
  "description": "Call with the client to go over feedback and next steps.",
  "location": "Google Meet",
  "colorId": "7",
  "creator": {
    "id": "creator123",
    "email": "creator@example.com",
    "displayName": "John Doe",
    "self": true
  },
  "organizer": {
    "id": "organizer123",
    "email": "organizer@example.com",
    "displayName": "Project Manager",
    "self": false
  },
  "start": {
    "dateTime": "2024-10-21T12:45:00Z",
    "timeZone": "America/Los_Angeles"
  },
  "end": {
    "dateTime": "2024-10-21T13:30:00Z",
    "timeZone": "America/Los_Angeles"
  },
  "reminders": {
    "useDefault": true
  },
  "eventType": "default"
};

Future<void> storeMockEvents() async {
  // Reference to the Firestore collection
  CollectionReference eventsCollection = FirebaseFirestore.instance.collection('data');
  
  // Data to be stored
  Map<String, dynamic> mockDay = {
    "mock1": mock1,
    "mock2": mock2,
    "mock3": mock3,
  };

  try {
    // Store the event data in the 'mockEvents' document
    await eventsCollection.doc('mockEvents').set(mockDay);
    print('Events stored successfully!');
  } catch (e) {
    print('Error storing events: $e');
  }
}

Future<void> fetchEventData() async {
  try {
    DocumentSnapshot documentSnapshot = await FirebaseFirestore.instance
        .collection('data') // Collection name
        .doc('mockEvents') // Document name
        .get();
    if (documentSnapshot.exists) {
      var eventData = documentSnapshot.data() as Map<String, dynamic>;

      // Create a list of entries from the map
      var entries = eventData.entries.toList();

      // Sort the entries based on start.dateTime
      entries.sort((a, b) {
        DateTime startA = DateTime.parse(a.value['start']['dateTime']);
        DateTime startB = DateTime.parse(b.value['start']['dateTime']);
        return startA.compareTo(startB);
      });

      // Create a sorted map (optional, depending on your needs)
      var sortedEvents = {
        for (var entry in entries) entry.key: entry.value,
      };

      print('Sorted Events: $sortedEvents'); // Sorted by start time
    } else {
      print('Document does not exist');
    }
  } catch (e) {
    print('Error fetching event data: $e');
  }
  
}

