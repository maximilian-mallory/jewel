import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:jewel/google/calendar/authenticated_events.dart';
import 'package:jewel/google/calendar/googleapi.dart';
//import 'package:jewel/google/maps/map_screen.dart';
import 'package:jewel/screens/test_screen1.dart';

import 'package:jewel/widgets/custom_nav.dart';
import 'package:jewel/widgets/settings.dart';


class HomeScreen extends StatefulWidget {
  final CalendarLogic calendarLogic;

  const HomeScreen({super.key, required this.calendarLogic});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 1;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      Screen1(),//calendarLogic: widget.calendarLogic),
      calendarScrollView(widget.calendarLogic),
      //MapScreen(), // Pass CalendarLogic if needed
      Screen1()
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget buildEventsList() {
    return Expanded(
      child: Column(
        children: List.generate(24, (hourIndex) {
          return Container(
            height: 100.0,
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Stack(
              children: widget.calendarLogic.events.where((event) {
                final start = event.start?.dateTime;
                return start != null && start.hour == hourIndex;
              }).map((event) {
                return Positioned(
                  top: 10,
                  left: 60,
                  right: 10,
                  child: Card(
                    color: Colors.blueAccent,
                    child: ListTile(
                      title: Text(
                        event.summary ?? 'No Title',
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        '${event.start?.dateTime} - ${event.end?.dateTime}',
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

  Widget calendarScrollView(CalendarLogic calendarLogic) {
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
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      timeLabel,
                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                      textAlign: TextAlign.center,
                    ),
                  );
                }),
              ),
            ),
            buildEventsList()
          ],
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Builder(
                  builder: (BuildContext context) {
                    return IconButton(
                      icon: const Icon(Icons.settings),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SettingsScreen(),
                          ),
                        );
                      },
                      tooltip: MaterialLocalizations.of(context).showMenuTooltip,
                    );
                  },
                ),
                IconButton(
                  icon: const FaIcon(FontAwesomeIcons.google), // Path to your Google icon asset
                  onPressed: () async {
                    await widget.calendarLogic.handleSignIn();
                    setState(() {});
                  },
                  tooltip: 'Sign In with Google',
                ),
              ],
            ),
            const Expanded(
              child: Center(
                child: Text('Jewel'),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: AuthenticatedCalendar(
              calendarLogic: widget.calendarLogic, // Pass required dependencies
            ),
          ),
          Expanded(
            child: _screens[_selectedIndex], // Controlled by navigation bar
          ),
          
        ],
      ),
      bottomNavigationBar: CustomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
