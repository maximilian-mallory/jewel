import 'package:flutter/material.dart';
import 'package:googleapis/calendar/v3.dart' as gcal;
import 'package:intl/intl.dart';
import 'package:jewel/google/calendar/googleapi.dart';
import 'package:provider/provider.dart';



class CalendarEventsView extends StatefulWidget {
  final CalendarLogic calendarLogic;

  const CalendarEventsView({Key? key, required this.calendarLogic}) : super(key: key);

  @override
  _CalendarEventsViewState createState() => _CalendarEventsViewState();
}

class _CalendarEventsViewState extends State<CalendarEventsView> {
  @override
Widget build(BuildContext context) {
  final calendarLogic = Provider.of<CalendarLogic>(context);

  return Expanded(
    child: SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time column
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
          // Events column
          FutureBuilder<List<gcal.Event>>(
            future: getGoogleEventsData(calendarLogic),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return CircularProgressIndicator(); // Show loading spinner while fetching
              } else if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              } else if (snapshot.hasData) {
                return buildEventsList(snapshot.data!);
              } else {
                return Text('No events found');
              }
            },
          ),
        ],
      ),
    ),
  );
}

  Widget buildEventsList(List<gcal.Event> events) {
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
