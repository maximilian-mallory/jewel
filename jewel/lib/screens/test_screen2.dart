import 'package:flutter/material.dart';
import 'package:jewel/google_events/events_form.dart';
import 'package:jewel/google/calendar/googleapi.dart';
import 'package:googleapis/calendar/v3.dart' as gcal;
import 'package:jewel/google/calendar/calendar_logic.dart';

// Screen2 class to display the AddEvent widget
class Screen2 extends StatelessWidget {
  const Screen2({super.key});

  Future<gcal.CalendarApi> _initializeCalendarApi() async {
    CalendarLogic calendarLogic = CalendarLogic(); // Use CalendarLogic from googleapi.dart
    return await createCalendarApiInstance(calendarLogic); // Pass it to the function
  }

  // Build the UI
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<gcal.CalendarApi>(
      future: _initializeCalendarApi(),
      builder: (context, snapshot) { // Use the snapshot to build the UI
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text("Error initializing Google Calendar API"));
        } else if (snapshot.hasData) {
          return Center(child: AddEvent(calendarApi: snapshot.data!));
        } else {
          return const Center(child: Text("Failed to load Calendar API"));
        }
      },
    );
  }
}