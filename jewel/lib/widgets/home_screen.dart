import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:jewel/google/calendar/authenticated_events.dart';
import 'package:jewel/google/calendar/googleapi.dart';
//import 'package:jewel/google/maps/map_screen.dart';
import 'package:jewel/widgets/custom_nav.dart';
import 'package:jewel/widgets/events_view.dart';
import 'package:jewel/widgets/gmap_screen.dart';
import 'package:jewel/widgets/settings.dart';
import 'package:googleapis/calendar/v3.dart' as gcal;
import 'package:provider/provider.dart';


class HomeScreen extends StatefulWidget {
  final CalendarLogic calendarLogic; //have to have so that the page knows it exsists

  const HomeScreen({super.key, required this.calendarLogic}); //requires the calendarLogic used from main.dart

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 1;
  late gcal.CalendarApi calendarApi;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount? account) async { // Auth State listener
      setState(() {
        widget.calendarLogic.currentUser = account;
        widget.calendarLogic.isAuthorized = account != null;
      });
      widget.calendarLogic.events = await getGoogleEventsData(widget.calendarLogic.calendarApi);
      
    });
    _screens = [
      SettingsScreen(),//calendarLogic: widget.calendarLogic),
      CalendarEventsView(calendarLogic: widget.calendarLogic),
       //takes callendar logic to use for the page
      //MapScreen(), // Pass CalendarLogic if needed
      MapSample()
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void updateSelectedCalendar(String? calendarId) {
    setState(() async {
      widget.calendarLogic.selectedCalendar = calendarId;
      widget.calendarLogic.events = await getGoogleEventsData(calendarApi);
    });
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
                TextButton.icon(
                  style: TextButton.styleFrom(
                  foregroundColor: Colors.green,
                  textStyle: const TextStyle(fontSize: 20)),
                  icon: const FaIcon(
              FontAwesomeIcons.google,
              size: 40, // Make the icon size match the image size
            ),
                  onPressed: () async {
                    await handleSignIn();
                    setState(() {});
                  },
                  label: const Text(''),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Padding(padding: const EdgeInsets.symmetric(horizontal: 8.0)),
          Image.asset(
            'assets/images/jewel205.png', // Replace with your image path
            height: 45, // Adjust size for AppBar
            width: 45, // Adjust size for AppBar
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 100, // Set a specific height for the calendar UI
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
