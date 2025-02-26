import 'package:flutter/material.dart';
import 'package:googleapis/calendar/v3.dart' as gcal;
import 'package:intl/intl.dart';
import 'package:jewel/google/calendar/googleapi.dart';
import 'package:jewel/models/jewel_user.dart';
import 'package:jewel/widgets/home_screen.dart';
import 'package:provider/provider.dart';
import 'package:jewel/google/calendar/mode_toggle.dart';

/*
  This widget class builds a Calendar widget
  It does not create the controls
*/
class CalendarEventsView extends StatefulWidget {

  const CalendarEventsView({super.key});
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
    final isMonthlyViewPrivate = context.watch<ModeToggle>().isMonthlyView;
    return Column(
      children: [
        Expanded(
          child: isMonthlyViewPrivate
              ? buildMonthlyView(context)
              : buildDailyView(context),
        ),
      ],
    );
  }

  // Builds the daily view
  Widget buildDailyView(BuildContext context) {
    final calendarLogic = Provider.of<CalendarLogic>(context);

    return SingleChildScrollView(
      controller: _scrollController,
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
                      'EventsViewError: ${snapshot.error}',
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
    );
  }

// Builds the monthly view
  Widget buildMonthlyView(BuildContext context) {
    final calendarLogic = Provider.of<CalendarLogic>(context);
    final DateTime now = calendarLogic.selectedDate;
    final DateTime firstDayOfMonth = DateTime(now.year, now.month, 1);
    final int daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final int firstWeekday = (firstDayOfMonth.weekday % 7) + 1;
    final int totalCells = daysInMonth + firstWeekday;
    final int rows = (totalCells / 7).ceil();

    return FutureBuilder<List<gcal.Event>>(
      future: getGoogleEventsForMonth(
          calendarLogic, context), // Use the new function
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(
            child: Text(
              'EventsViewError: ${snapshot.error}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          );
        } else if (snapshot.hasData) {
          // Get events for the entire month
          Map<int, List<gcal.Event>> eventsByDay =
              groupEventsByDay(snapshot.data!, now);

          return Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                    .map((day) => Expanded(
                          child: Center(
                            child: Text(day,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                          ),
                        ))
                    .toList(),
              ),
              Expanded(
                child: GridView.builder(
                  itemCount: rows * 7,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    childAspectRatio: 1,
                  ),
                  itemBuilder: (context, index) {
                    final int dayNumber = index - (firstWeekday - 2);
                    bool isValidDay = dayNumber > 0 && dayNumber <= daysInMonth;
                    List<gcal.Event>? events =
                        eventsByDay[dayNumber]; // Fetch events for the day

                    return Container(
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        color: isValidDay ? Colors.white : Colors.grey[300],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Align(
                              alignment: Alignment.topLeft,
                              child: Text(
                                isValidDay ? dayNumber.toString() : '',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      isValidDay ? Colors.black : Colors.grey,
                                ),
                              ),
                            ),
                            if (isValidDay && events != null)
                              ...buildEventTexts(events),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        } else {
          return const Center(
            child: Text(
              'No events found',
              textAlign: TextAlign.center,
            ),
          );
        }
      },
    );
  }

  // Helper function to build event texts
  List<Widget> buildEventTexts(List<gcal.Event> events) {
    if (events.isEmpty) return [];

    return [
      // Highlight entire cell background color
      Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Color.fromARGB(255, 57, 145, 102), // Highlight color
          borderRadius: BorderRadius.circular(6),
        ),
        padding: const EdgeInsets.all(4),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.center, // Center the text box horizontally
          children: [
            if (events.length > 3)
              Center(
                child: Container(
                  padding: EdgeInsets.symmetric(
                      vertical: 2, horizontal: 6), // Smaller padding
                  decoration: BoxDecoration(
                    color: Color.fromARGB(255, 57, 145, 102),
                    borderRadius:
                        BorderRadius.circular(4), // Smaller border radius
                  ),
                  child: Text(
                    'Multiple Events Scheduled',
                    style: TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center, // Center text inside box
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
            else
              ...events.map((event) => Center(
                    child: Container(
                      width: double
                          .infinity, // Full-width inside the highlighted box
                      margin: EdgeInsets.symmetric(
                          vertical: 1), // Reduced vertical margin
                      padding: EdgeInsets.symmetric(
                          vertical: 2, horizontal: 4), // Smaller padding
                      decoration: BoxDecoration(
                        color: Color.fromARGB(255, 57, 145, 102),
                        borderRadius:
                            BorderRadius.circular(4), // Smaller border radius
                      ),
                      child: Text(
                        event.summary ?? 'No Title',
                        style: TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center, // Center text
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )),
          ],
        ),
      ),
    ];
  }

  // Group the events by day for the monthly view
  Map<int, List<gcal.Event>> groupEventsByDay(
      List<gcal.Event> events, DateTime month) {
    Map<int, List<gcal.Event>> eventsByDay = {};

    // Initialize all days in the month
    for (int day = 1;
        day <= DateTime(month.year, month.month + 1, 0).day;
        day++) {
      eventsByDay[day] = [];
    }

    for (var event in events) {
      final start = event.start?.dateTime?.toLocal();
      if (start != null) {
        // Ensure the event belongs to the correct month
        if (start.year == month.year && start.month == month.month) {
          final int day = start.day;
          eventsByDay[day]!.add(event);
        }
      }
    }

    return eventsByDay;
  }

  // Builds the list of events for the day view
  Widget buildEventsList(List<gcal.Event> events) {
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
                          )
                        : null),
              );
            }).toList(),
          ),
        );
      }),
    );
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
