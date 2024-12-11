import 'package:flutter/foundation.dart';
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
      widget.calendarLogic.events = await getGoogleEventsData(widget.calendarLogic);
      
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
      widget.calendarLogic.events = await getGoogleEventsData(widget.calendarLogic);
    });
  }


 @override
Widget build(BuildContext context) {
  bool isWeb = kIsWeb;
  return Scaffold(
    body: Column(
      children: [
        // AppBar content as a child, now full width
        Container(
          width: double.infinity, // Make the container take up the entire width
          padding: EdgeInsets.all(isWeb ? 10 : 5),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor, // Set the background color
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 5,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min, // Prevent Row from taking infinite space
            children: [
              TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.green,
                  textStyle: const TextStyle(fontSize: 1),
                ),
                icon: FaIcon(
                  FontAwesomeIcons.google,
                  size: isWeb ? 50 : 25,
                ),
                onPressed: () async {
                  await handleSignOut();
                  await handleSignIn();
                  setState(() {});
                },
                label: const Text(''),
              ),
              SizedBox(width: isWeb ? 10 : 5), // Add spacing between widgets
              Flexible(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12), // Set the radius for rounded corners
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 5,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12), // Ensure rounding is applied to the child
                    child: SizedBox(
                      height: isWeb ? 75 : 55, // Constrain height
                      child: AuthenticatedCalendar(
                        calendarLogic: widget.calendarLogic,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10), // Add spacing between widgets
              // Wrapping the image in a container
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12), // Set rounded corners for the image container
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 5,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12), // Ensure the image corners are rounded
                  child: Image.asset(
                    'assets/images/jewel205.png',
                    height: isWeb ? 75 : 35,
                    width: isWeb ? 75 : 25,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Main body content
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