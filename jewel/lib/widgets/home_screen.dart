import 'package:flutter/material.dart';
import 'package:jewel/google/calendar/google_events.dart';
import 'package:jewel/screens/test_screen1.dart';
import 'package:jewel/screens/test_screen2.dart';
import 'package:jewel/screens/test_screen3.dart';
import 'package:jewel/screens/map_screen.dart';
import 'package:jewel/widgets/calendar_event_list.dart';
import 'package:jewel/widgets/custom_nav.dart';

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
    CalendarIntegrationKey(), //0
    CalendarEventList(), //1
    Screen3(), //2
    MapScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Jewel')),
      body: _screens[_selectedIndex],
      bottomNavigationBar: CustomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}