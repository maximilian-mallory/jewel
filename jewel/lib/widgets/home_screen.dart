import 'package:flutter/material.dart';
import 'package:googleapis/calendar/v3.dart';
import 'package:jewel/google/calendar/google_events.dart';
import 'package:jewel/google/calendar/googleapi.dart';
import 'package:jewel/screens/test_screen1.dart';
import 'package:jewel/screens/test_screen2.dart';
import 'package:jewel/screens/test_screen3.dart';
import 'package:jewel/google/maps/map_screen.dart';
import 'package:jewel/widgets/calendar_event_list.dart';
import 'package:jewel/widgets/custom_nav.dart';
import 'package:jewel/widgets/settings.dart';


class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    //This is the list of screens, if you need to add one to the navigation bar make sure 
    //it is in the same order as it shows up here
    //You also need to add it to the navigation which is in widgets/custom_nav.dart
    CalendarEventList(), //1
    SignInDemo(),
    MapScreen(),//2
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Jewel'), leading: Builder(
        builder: (BuildContext context) {
          return IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsScreen()),
              );
            },
            tooltip: MaterialLocalizations.of(context).showMenuTooltip,
          );
        },
      ),),
      body: _screens[_selectedIndex],
      bottomNavigationBar: CustomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}