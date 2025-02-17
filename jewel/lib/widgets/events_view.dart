import 'package:flutter/material.dart';
import 'package:googleapis/calendar/v3.dart' as gcal;
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:jewel/google/calendar/googleapi.dart';
import 'package:jewel/widgets/home_screen.dart';
import 'package:provider/provider.dart';

/*
  This widget class builds a Calendar widget
  It does not create the controls
*/
class CalendarEventsView extends StatefulWidget {
  @override
  _CalendarEventsView createState() => _CalendarEventsView();
}

class _CalendarEventsView extends State<CalendarEventsView> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    final notifier = Provider.of<SelectedIndexNotifier>(context, listen: false);
    _scrollController =
        ScrollController(initialScrollOffset: notifier.getScrollPosition(1));
  }

  @override
  Widget build(BuildContext context) {
    final calendarLogic = Provider.of<CalendarLogic>(
        context); // provider gives us app level access to the same CalendarLogic object

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            scrollDirection: Axis.vertical,
            child: Row(
              // this is the actual widget with the calendar in it
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  // Lefthand time column
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
                Expanded(
                  child: FutureBuilder<List<gcal.Event>>(
                    // FutureBuilders lets us make asyncronous calls to methods that return lists of widgets with the asynchronously retrieved data
                    future: getGoogleEventsData(calendarLogic, context),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      } else if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Error: ${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.red),
                          ),
                        );
                      } else if (snapshot.hasData) {
                        return buildEventsList(snapshot
                            .data!); // this is our list of widgets that we pass the list building method, which returns our second column
                      } else {
                        return const Center(
                          child: Text(
                            'No events found',
                            textAlign: TextAlign.center,
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget buildEventsList(List<gcal.Event> events) {
    // notice that the events list is no longer of type Future<List>
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
              // this determines what events we are stacking
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
              return Positioned.fill(
                // builds the actual card that will be added to the list
                child: Card(
                    margin: const EdgeInsets.all(0),
                    color: const Color.fromARGB(255, 57, 145, 102),
                    child: (hourIndex == start!.hour)
                        ? ListTile(
                            title: Text(
                              event.summary ?? 'No Title',
                              style: const TextStyle(color: Colors.white),
                            ),
                            subtitle: Text(
                              '${start != null ? DateFormat('hh:mm a').format(start) : 'No Time'} - '
                              '${end != null ? DateFormat('hh:mm a').format(end) : 'No Time'}',
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
    TextEditingController titleController =
        TextEditingController(text: event.summary ?? "No Title");

    final oldSummary = event.summary ?? "No Title";

    DateTime startTime = event.start?.dateTime ?? DateTime.now();
    DateTime endTime =
        event.end?.dateTime ?? DateTime.now().add(Duration(hours: 1));

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
                final updatedEvent = gcal.Event();
                updatedEvent.summary = titleController.text;
                updatedEvent.start = gcal.EventDateTime();
                updatedEvent.start?.dateTime = startTime.toUtc();
                updatedEvent.start?.timeZone = "UTC";
                updatedEvent.end = gcal.EventDateTime();
                updatedEvent.end?.dateTime = endTime.toUtc();
                updatedEvent.end?.timeZone = "UTC";

                final calendarLogic =
                    Provider.of<CalendarLogic>(context, listen: false);

                final newSummary = updatedEvent.summary ?? "No Title";

                String changeLog = "Updated:\n"
                    "Title: $oldSummary → $newSummary\n"
                    "Start: ${formatDateTime(event.start?.dateTime?.toLocal())} → ${formatDateTime(updatedEvent.start?.dateTime?.toLocal())}\n"
                    "End: ${formatDateTime(event.end?.dateTime?.toLocal())} → ${formatDateTime(updatedEvent.end?.dateTime?.toLocal())}";

                calendarLogic.addToHistory(event.id!, changeLog);

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
    final calendarLogic = Provider.of<CalendarLogic>(context, listen: false);
    final history = calendarLogic.getHistory(eventId);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Event History'),
          content: Container(
            constraints: BoxConstraints(
              maxHeight: 300, // Set a maximum height for the scrollable area
            ),
            child: history.isEmpty
                ? Text('No changes recorded for this event.')
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: history
                          .map((change) => Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Text(change),
                              ))
                          .toList(),
                    ),
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
