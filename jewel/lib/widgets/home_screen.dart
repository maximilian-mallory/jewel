import 'package:flutter/material.dart';
import 'package:jewel/google/calendar/authenticated_events.dart';
import 'package:jewel/google/calendar/googleapi.dart';
import 'package:jewel/google/maps/map_screen.dart';
import 'package:jewel/widgets/calendar_event_list.dart';
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
      CalendarEventList(),//calendarLogic: widget.calendarLogic),
      SignInDemo(calendarLogic: widget.calendarLogic),
      MapScreen(), // Pass CalendarLogic if needed
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Jewel'),
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          SettingsScreen()),//calendarLogic: widget.calendarLogic)),
                );
              },
              tooltip: MaterialLocalizations.of(context).showMenuTooltip,
            );
          },
        ),
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: CustomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
