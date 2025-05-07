import 'dart:async';
import 'package:flutter/material.dart';
import 'package:googleapis/calendar/v3.dart' as gcal;
import 'package:http/http.dart' as http;
import 'package:icalendar_parser/icalendar_parser.dart';
import 'package:jewel/google/calendar/calendar_logic.dart';

// Fetches and parses events from an iCal feed URL into Google Calendar Event objects.
// Handles both all-day events and time-specific events by determining the format from the data.
// Returns a list of gcal.Event objects representing the iCal feed events.
Future<List<gcal.Event>> loadIcalFeedEvents(
    String feedUrl, CalendarLogic calendarLogic, BuildContext context) async {
  try {
    final response = await http.get(Uri.parse(feedUrl));
    if (response.statusCode != 200) {
      throw Exception('Failed to load iCal feed: ${response.statusCode}');
    }

    final calendar = ICalendar.fromString(response.body);
    List<gcal.Event> events = [];

    for (var eventData in calendar.data) {
      if (eventData['type'] != 'VEVENT') continue;

      final gcalEvent = gcal.Event();
      
      gcalEvent.summary = eventData['summary']?.toString();
      gcalEvent.description = eventData['description']?.toString();
      gcalEvent.location = eventData['location']?.toString();

      DateTime? startTime = _parseICalDateTime(eventData['dtstart']);
      if (startTime != null) {
        bool isAllDayEvent = _isDateOnlyEvent(eventData['dtstart']);
        
        gcalEvent.start = gcal.EventDateTime();
        
        if (isAllDayEvent) {
          String dateStr = "${startTime.year.toString().padLeft(4, '0')}-"
                          "${startTime.month.toString().padLeft(2, '0')}-"
                          "${startTime.day.toString().padLeft(2, '0')}";
          gcalEvent.start!.date = DateTime.parse(dateStr);
        } else {
          gcalEvent.start!.dateTime = startTime;
          gcalEvent.start!.timeZone = 'UTC';
        }
      }

      DateTime? endTime = _parseICalDateTime(eventData['dtend']);
      if (endTime != null) {
        bool isAllDayEvent = _isDateOnlyEvent(eventData['dtend']);
        
        gcalEvent.end = gcal.EventDateTime();
        
        if (isAllDayEvent) {
          String dateStr = "${endTime.year.toString().padLeft(4, '0')}-"
                          "${endTime.month.toString().padLeft(2, '0')}-"
                          "${endTime.day.toString().padLeft(2, '0')}";
          gcalEvent.end!.date = DateTime.parse(dateStr);
        } else {
          gcalEvent.end!.dateTime = endTime;
          gcalEvent.end!.timeZone = 'UTC';
        }
      }

      gcalEvent.extendedProperties = gcal.EventExtendedProperties()
        ..private = {
          'color': '0, 120, 255',
          'source': 'ical'
        };

      gcalEvent.id = 'ical-${eventData['uid'] ?? DateTime.now().millisecondsSinceEpoch}';

      if (gcalEvent.start != null) {
        events.add(gcalEvent);
      }
    }

    print("DEBUG: Total iCal events loaded: ${events.length}");
    return events;
  } catch (e) {
    print('Error loading iCal feed: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error loading iCal feed: $e')),
    );
    return [];
  }
}

// Parses iCal date-time values from different formats.
// Handles both date-only values (for all-day events) and date-time values (for time-specific events).
// Returns a DateTime object or null if parsing fails.
DateTime? _parseICalDateTime(dynamic dtValue) {
  if (dtValue == null) return null;

  if (dtValue.toString().contains('IcsDateTime')) {
    String dtString = dtValue.toString();

    RegExp dateRegex = RegExp(r'dt:\s*([0-9TZ]+)');
    var match = dateRegex.firstMatch(dtString);
    
    if (match != null && match.groupCount >= 1) {
      String dateStr = match.group(1)!.trim();

      try {
        if (dateStr.contains('T')) {
          int year = int.parse(dateStr.substring(0, 4));
          int month = int.parse(dateStr.substring(4, 6));
          int day = int.parse(dateStr.substring(6, 8));
          int hour = int.parse(dateStr.substring(9, 11));
          int minute = int.parse(dateStr.substring(11, 13));
          int second = dateStr.length > 13 ? int.parse(dateStr.substring(13, 15)) : 0;
          
          return DateTime.utc(year, month, day, hour, minute, second);
        } else {
          int year = int.parse(dateStr.substring(0, 4));
          int month = int.parse(dateStr.substring(4, 6));
          int day = int.parse(dateStr.substring(6, 8));
          
          return DateTime.utc(year, month, day);
        }
      } catch (e) {
        print("Error parsing date: $e for $dateStr");
      }
    }
  }
  
  return null;
}

// Determines if an event is a date-only (all-day) event based on the format of the date value.
// Returns true for date-only events, false for time-specific events.
bool _isDateOnlyEvent(dynamic dtValue) {
  if (dtValue == null) return false;
  
  String dtString = dtValue.toString();
  
  if (dtString.contains('IcsDateTime')) {
    RegExp dateRegex = RegExp(r'dt:\s*([0-9TZ]+)');
    var match = dateRegex.firstMatch(dtString);
    
    if (match != null && match.groupCount >= 1) {
      String dateStr = match.group(1)!.trim();
      return !dateStr.contains('T');
    }
  }
  
  return false;
}

// Converts an iCal event to a Google Calendar event and inserts it into the primary calendar.
// Preserves event properties including summary, description, location, and handles
// different time formats (all-day vs time-specific events).
// Returns the newly created Google Calendar event or null if conversion fails.
Future<gcal.Event?> convertIcalToGoogleEvent(
    gcal.Event icalEvent, 
    CalendarLogic calendarLogic,
    BuildContext context) async {
  try {
    if (icalEvent.id == null || !icalEvent.id!.startsWith('ical-')) {
      return icalEvent;
    }
    
    var googleEvent = gcal.Event()
      ..summary = icalEvent.summary
      ..description = icalEvent.description
      ..location = icalEvent.location;
    
    googleEvent.extendedProperties = gcal.EventExtendedProperties();
    googleEvent.extendedProperties!.private = {};
      
    googleEvent.extendedProperties!.private!['converted_from_ical'] = 'true';
    googleEvent.extendedProperties!.private!['original_ical_id'] = icalEvent.id!;
    googleEvent.extendedProperties!.private!['color'] = '57, 145, 102';
    
    if (icalEvent.extendedProperties?.private != null) {
      for (var entry in icalEvent.extendedProperties!.private!.entries) {
        if (entry.key != 'source') {
          googleEvent.extendedProperties!.private![entry.key] = entry.value;
        }
      }
    }
    
    bool isAllDayEvent = icalEvent.start?.date != null;
    
    googleEvent.start = gcal.EventDateTime();
    if (isAllDayEvent) {
      googleEvent.start!.date = icalEvent.start?.date;
    } else {
      final startDateTime = icalEvent.start?.dateTime;
      googleEvent.start!.dateTime = startDateTime;
      googleEvent.start!.timeZone = "UTC";
    }
    
    googleEvent.end = gcal.EventDateTime();
    if (isAllDayEvent) {
      googleEvent.end!.date = icalEvent.end?.date;
      
      if (googleEvent.end!.date == null && googleEvent.start!.date != null) {
        DateTime startDate = googleEvent.start!.date!;
        DateTime endDate = startDate.add(Duration(days: 1));
        
        String endDateStr = "${endDate.year.toString().padLeft(4, '0')}-"
                          "${endDate.month.toString().padLeft(2, '0')}-"
                          "${endDate.day.toString().padLeft(2, '0')}";
        googleEvent.end!.date = DateTime.parse(endDateStr);
      }
    } else {
      googleEvent.end!.dateTime = icalEvent.end?.dateTime;
      
      if (googleEvent.end!.dateTime == null && googleEvent.start!.dateTime != null) {
        googleEvent.end!.dateTime = googleEvent.start!.dateTime!.add(Duration(hours: 1));
      }
      
      googleEvent.end!.timeZone = "UTC";
    }
    
    bool hasValidTimes = false;
    if (isAllDayEvent) {
      hasValidTimes = googleEvent.start?.date != null && googleEvent.end?.date != null;
    } else {
      hasValidTimes = googleEvent.start?.dateTime != null && googleEvent.end?.dateTime != null;
    }
    
    if (!hasValidTimes) {
      throw Exception("Failed to create valid start and end times for the event");
    }
    
    try {
      var insertedEvent = await calendarLogic.calendarApi.events.insert(
        googleEvent, 
        "primary"
      );
      
      
      if (insertedEvent.extendedProperties == null) {
        insertedEvent.extendedProperties = gcal.EventExtendedProperties();
      }
      if (insertedEvent.extendedProperties!.private == null) {
        insertedEvent.extendedProperties!.private = {};
      }
      
      insertedEvent.extendedProperties!.private!['converted_from_ical'] = 'true';
      insertedEvent.extendedProperties!.private!['color'] = '57, 145, 102';
      
      return insertedEvent;
    } catch (e) {
      print("Error inserting converted event into Google Calendar: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error converting event: $e')),
      );
      return null;
    }
  } catch (e) {
    print("Error converting iCal event: $e");
    return null;
  }
}

// Replaces a converted iCal event when changing between all-day and time-specific formats.
// Creates a new event with the updated time format and deletes the old event.
// Preserves all other event properties including description, location, and custom properties.
// Returns the newly created event or null if replacement fails.
Future<gcal.Event?> replaceConvertedIcalEvent(
    gcal.Event oldEvent,
    String summary,
    DateTime startTime,
    DateTime endTime,
    bool wasAllDayEvent,
    bool shouldBeTimeSpecificEvent,
    CalendarLogic calendarLogic,
    BuildContext context) async {
  try {
    var newEvent = gcal.Event()
      ..summary = summary
      ..description = oldEvent.description
      ..location = oldEvent.location;
    
    if (shouldBeTimeSpecificEvent) {
      newEvent.start = gcal.EventDateTime()
        ..dateTime = startTime.toUtc()
        ..timeZone = "UTC";
      
      newEvent.end = gcal.EventDateTime()
        ..dateTime = endTime.toUtc()
        ..timeZone = "UTC";
    } else {
      final startDate = DateTime.utc(startTime.year, startTime.month, startTime.day);
      final endDate = DateTime.utc(endTime.year, endTime.month, endTime.day);
      
      newEvent.start = gcal.EventDateTime()
        ..date = startDate;
      
      newEvent.end = gcal.EventDateTime()
        ..date = endDate;
    }
    
    newEvent.extendedProperties = gcal.EventExtendedProperties();
    newEvent.extendedProperties!.private = {};
    
    if (oldEvent.extendedProperties?.private?['color'] != null) {
      newEvent.extendedProperties!.private!['color'] = 
          oldEvent.extendedProperties!.private!['color']!;
    } else {
      newEvent.extendedProperties!.private!['color'] = '57, 145, 102';
    }
    
    if (oldEvent.extendedProperties?.private != null) {
      for (var key in oldEvent.extendedProperties!.private!.keys) {
        if (key.startsWith('reminder') || 
            key.startsWith('notification') || 
            key == 'group' || 
            key == 'groupColor') {
          newEvent.extendedProperties!.private![key] = 
              oldEvent.extendedProperties!.private![key]!;
        }
      }
    }
    
    newEvent.extendedProperties!.private!['converted_from_ical'] = 'true';
    
    if (oldEvent.extendedProperties?.private?['original_ical_id'] != null) {
      newEvent.extendedProperties!.private!['original_ical_id'] = 
          oldEvent.extendedProperties!.private!['original_ical_id']!;
    } else if (oldEvent.id != null) {
      newEvent.extendedProperties!.private!['original_event_id'] = oldEvent.id!;
    }
    
    var insertedEvent = await calendarLogic.calendarApi.events.insert(
      newEvent, 
      "primary"
    );
    
    if (insertedEvent == null) {
      throw Exception("Failed to insert new event");
    }
    
    try {
      await calendarLogic.calendarApi.events.delete(
        "primary",
        oldEvent.id!
      );
    } catch (e) {
      print("Warning: Could not delete old event: $e");
    }
    
    return insertedEvent;
  } catch (e) {
    print("Error replacing converted iCal event: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Failed to replace converted event: $e"),
        duration: Duration(seconds: 5),
      )
    );
    return null;
  }
}

// Fetches all events from the primary calendar that were converted from iCal feeds.
// Filters events by the 'converted_from_ical' flag in extended properties.
// Used to track and manage converted events separately from native Google Calendar events.
Future<List<gcal.Event>> fetchConvertedIcalEvents(
    CalendarLogic calendarLogic, DateTime startTime, DateTime endTime) async {
  try {
    final gcal.Events primaryEvents = await calendarLogic.calendarApi.events.list(
      "primary",
      timeMin: startTime.toUtc(),
      timeMax: endTime.toUtc(),
      singleEvents: true,
    );
    
    if (primaryEvents.items != null) {
      return primaryEvents.items!.where((event) => 
        event.extendedProperties?.private?['converted_from_ical'] == 'true').toList();
    }
  } catch (e) {
    print("Error checking primary calendar for converted events: $e");
  }
  
  return [];
}

// Checks if an event is a converted iCal event by looking for the 'converted_from_ical' flag.
// Returns true for converted iCal events, false otherwise.
bool isConvertedIcalEvent(gcal.Event event) {
  return event.extendedProperties?.private?['converted_from_ical'] == 'true';
}

// Sorts events by start time, handling both date-only (all-day) and date-time formats.
// Provides consistent ordering for mixed event types in the UI.
// All-day events are treated as starting at midnight for sorting purposes.
List<gcal.Event> sortEvents(List<gcal.Event> events) {
  if (events.isEmpty) return events;

  try {
    events.sort((a, b) {
      final aDateTime = a.start?.dateTime;
      final bDateTime = b.start?.dateTime;
      final aDate = a.start?.date;
      final bDate = b.start?.date;
      
      if (aDateTime != null && bDateTime != null) {
        return aDateTime.compareTo(bDateTime);
      }
      
      if (aDateTime != null && bDate != null) {
        final bDateStartOfDay = DateTime.parse('${bDate}T00:00:00Z');
        return aDateTime.compareTo(bDateStartOfDay);
      }
      
      if (aDate != null && bDateTime != null) {
        final aDateStartOfDay = DateTime.parse('${aDate}T00:00:00Z');
        return aDateStartOfDay.compareTo(bDateTime);
      }
      
      if (aDate != null && bDate != null) {
        return aDate.compareTo(bDate);
      }
      
      if (aDateTime == null && aDate == null) return 1;
      if (bDateTime == null && bDate == null) return -1;
      
      return 0;
    });
  } catch (e) {
    print("Error sorting events: $e");
  }

  return events;
}