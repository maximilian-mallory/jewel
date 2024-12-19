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

class SelectedIndexNotifier extends ChangeNotifier {
  int _selectedIndex;
  Map<int, double> _scrollPositions = {}; // Map to store scroll positions for each index

  SelectedIndexNotifier(this._selectedIndex);

  int get selectedIndex => _selectedIndex;

  set selectedIndex(int newIndex) {
    _selectedIndex = newIndex;
    notifyListeners();
  }

  double getScrollPosition(int index) {
    return _scrollPositions[index] ?? 0.0; // Return the stored scroll position or 0.0 if not found
  }

  setScrollPosition(int index, double position) {
    _scrollPositions[index] = position;
    notifyListeners();
  }
}


class HomeScreen extends StatefulWidget {
  final CalendarLogic calendarLogic; //have to have so that the page knows it exsists
  final int initialIndex;

  const HomeScreen({super.key, required this.calendarLogic, required this.initialIndex}); //requires the calendarLogic used from main.dart

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  
  late int _selectedIndex = widget.initialIndex;
  late gcal.CalendarApi calendarApi;
  late final List<Widget> _screens;
  bool isWeb = kIsWeb;
  @override
  void initState() {
    super.initState();
    final notifier = Provider.of<SelectedIndexNotifier>(context, listen: false);
    _selectedIndex = widget.initialIndex;
    googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount? account) async { // Auth State listener
      setState(() {
        widget.calendarLogic.currentUser = account;
        widget.calendarLogic.isAuthorized = account != null;
      });
      widget.calendarLogic.events = await getGoogleEventsData(widget.calendarLogic, context);
      
    });
    _screens = [
      SettingsScreen(),//calendarLogic: widget.calendarLogic),
      CalendarEventsView(),
       //takes callendar logic to use for the page
      //MapScreen(), // Pass CalendarLogic if needed
      MapSample(),
    ];
  }

  void _onItemTapped(int index) {
    final notifier = Provider.of<SelectedIndexNotifier>(context, listen: false);
    setState(() {
      notifier.selectedIndex = index;
    });
  }

  void updateSelectedCalendar(String calendarId) {
    setState(() async {
      widget.calendarLogic.selectedCalendar = calendarId;
      widget.calendarLogic.events = await getGoogleEventsData(widget.calendarLogic, context);
    });
  }


@override
Widget build(BuildContext context) {
  return Scaffold(
    body: Column(
      children: [
        if (!kIsWeb) SizedBox(height: 24),
        // AppBar content as a child, now full width
        Container(
          height: MediaQuery.of(context).size.height * 0.1325,
          width: double.infinity, // Make the container take up the entire width
          padding: EdgeInsets.all(kIsWeb ? 10 : 5),
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
            children: [
              TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.green,
                  textStyle: const TextStyle(fontSize: 1),
                ),
                icon: FaIcon(
                  FontAwesomeIcons.google,
                  size: kIsWeb ? 50 : 28,
                ),
                onPressed: () async {
                  await handleSignOut();
                  await handleSignIn();
                  setState(() {});
                },
                label: const Text(''),
              ),
              SizedBox(width: kIsWeb ? 10 : 5), // Add spacing between widgets
              kIsWeb
                  ? Flexible(child: calTools())
                  : Flexible(child: SizedBox(width: 280)),
              const SizedBox(width: 10), // Add spacing between widgets
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12), // Rounded corners
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 5,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12), // Rounded image corners
                  child: Image.asset(
                    'assets/images/jewel205.png',
                    height: kIsWeb ? 75 : 40,
                    width: kIsWeb ? 75 : 34,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!kIsWeb) Flexible(child: calTools()),
        // Main content area, expanded to take remaining space
         // Controlled by the bottom navigation bar
        Consumer<SelectedIndexNotifier>(
  builder: (context, selectedIndexNotifier, _) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.735,
      child: 
          _screens[selectedIndexNotifier.selectedIndex],

    );
  },
)
      ],
    ),
    bottomNavigationBar: Container(
    height: MediaQuery.of(context).size.height * 0.1325, // Set your desired height here
    child: CustomNavBar(
      currentIndex: context.watch<SelectedIndexNotifier>().selectedIndex,
      onTap: (index) {
        context.read<SelectedIndexNotifier>().selectedIndex = index;
      },
    ),
  ),
  );
}

Widget calTools() {
  return Container(
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
        child: Align(
  alignment: Alignment.center, // Vertically and horizontally centers the child
  child: AuthenticatedCalendar(
    calendarLogic: widget.calendarLogic,
  ),
),
      ),
    ),
  );
}
}