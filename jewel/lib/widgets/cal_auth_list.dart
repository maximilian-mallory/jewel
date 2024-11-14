import 'package:flutter/material.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:jewel/google/calendar/get_calendar.dart';


class CalendarScreen extends StatelessWidget {
  final CalendarService _calendarService = CalendarService();

  Future<void> _loadEvents() async {
    try {
      List<calendar.Event> events = await _calendarService.getCalendarEvents();
      for (var event in events) {
        print('Event: ${event.summary}');
      }
    } catch (e) {
      print('Failed to load events: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Google Calendar')),
      body: Center(
        child: ElevatedButton(
          onPressed: _loadEvents,
          child: Text('Load Calendar Events'),
        ),
      ),
    );
  }
}
