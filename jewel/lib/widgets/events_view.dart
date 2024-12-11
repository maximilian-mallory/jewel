import 'package:flutter/material.dart';
import 'package:googleapis/calendar/v3.dart' as gcal;
import 'package:intl/intl.dart';
import 'package:jewel/google/calendar/googleapi.dart';



class CalendarEventsView extends StatefulWidget {
  final CalendarLogic calendarLogic;

  const CalendarEventsView({super.key, required this.calendarLogic});

  @override
  _CalendarEventsViewState createState() => _CalendarEventsViewState();
}

class _CalendarEventsViewState extends State<CalendarEventsView> {
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 50,
              color: Colors.grey[200],
              child: Column(
                children: List.generate(24, (index) {
                  String timeLabel = '${index.toString().padLeft(2, '0')}:00';
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 41.5),
                    child: Text(
                      timeLabel,
                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                      textAlign: TextAlign.center,
                    ),
                  );
                }),
              ),
            ),
            buildEventsList(widget.calendarLogic.events),
          ],
        ),
      ),
    );
  }

  Widget buildEventsList(List<gcal.Event> events) {
    print('Number of events: ${events.length}'); // Debug print
    return Expanded(
      child: Column(
        children: List.generate(24, (hourIndex) {
          return Container(
            height: 100.0,
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Stack(
              children: events.where((event) {
                final start = event.start?.dateTime!.toLocal();
                return start != null && start.hour == hourIndex;
              }).map((event) {
                return Positioned(
                  top: 10,
                  left: 60,
                  right: 10,
                  child: Card(
                    color: const Color.fromARGB(255, 57, 145, 102),
                    child: ListTile(
                      title: Text(
                        event.summary ?? 'No Title',
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        '${event.start?.dateTime!.toLocal() != null ? DateFormat('hh:mm a').format(event.start!.dateTime!.toLocal()) : 'No Time'} - '
                        '${event.end?.dateTime!.toLocal() != null ? DateFormat('hh:mm a').format(event.end!.dateTime!.toLocal()) : 'No Time'}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        }),
      ),
    );
  }
}
