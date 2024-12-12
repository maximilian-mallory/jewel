import 'package:flutter/material.dart';
import 'package:googleapis/calendar/v3.dart' as gcal;
import 'package:intl/intl.dart';
import 'package:jewel/google/calendar/googleapi.dart';
import 'package:jewel/widgets/home_screen.dart';
import 'package:provider/provider.dart';



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
    _scrollController = ScrollController(initialScrollOffset: notifier.getScrollPosition(1) );
  }

  @override
Widget build(BuildContext context) {
  final calendarLogic = Provider.of<CalendarLogic>(context);

  return Expanded(
    child: Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
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
                Expanded(
                  child: FutureBuilder<List<gcal.Event>>(
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
                        return buildEventsList(snapshot.data!);
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
    ),
  );
}

Widget buildEventsList(List<gcal.Event> events) {
  return Column(
    children: List.generate(24, (hourIndex) {
      return Container(
        height: 100.0,
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
        ),
        child: Stack(
          children: events.where((event) {
            final start = event.start?.dateTime?.toLocal();
            final end = event.end?.dateTime?.toLocal();
            return start != null &&
                end != null &&
                start.hour <= hourIndex &&
                end.hour > hourIndex;
          }).map((event) {
            final start = event.start?.dateTime?.toLocal();
            final end = event.end?.dateTime?.toLocal();

            // Calculate the duration of the event
            final durationInHours = end != null && start != null
                ? end.difference(start).inHours
                : 1;

            // Determine the height dynamically (spans blocks fully if additional entry)
            final height = durationInHours > 1
                ? 100.0 * durationInHours
                : 100.0; // Ensure single-hour events fill the block fully

            return Positioned.fill(
              child: Card(
                margin: const EdgeInsets.all(0),
                color: const Color.fromARGB(255, 57, 145, 102),
                child: (hourIndex == start!.hour) ?
                  ListTile(
                  title: Text(
                    event.summary ?? 'No Title',
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    '${start != null ? DateFormat('hh:mm a').format(start) : 'No Time'} - '
                    '${end != null ? DateFormat('hh:mm a').format(end) : 'No Time'}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                
                ) : null
              ),
            );
          }).toList(),
        ),
      );
    }),
  );
}

   @override
  void dispose() {
    // Save the current scroll position before disposing the controller
    final scrollNotifier = Provider.of<SelectedIndexNotifier>(context, listen: false); // Renamed variable
    scrollNotifier.setScrollPosition(1, _scrollController.offset); // Save scroll position
    _scrollController.dispose();
    super.dispose();
  }
}