import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:jewel/google/calendar/add_calendar_form.dart';
import 'package:jewel/google/calendar/googleapi.dart';
import 'package:jewel/models/jewel_user.dart';
//import 'package:jewel/google/maps/map_screen.dart';
import 'package:jewel/widgets/custom_nav.dart';
import 'package:jewel/widgets/events_view.dart';
import 'package:jewel/widgets/gmap_screen.dart';
import 'package:jewel/widgets/settings.dart';
import 'package:googleapis/calendar/v3.dart' as gcal;
import 'package:provider/provider.dart';
import 'package:jewel/screens/test_screen1.dart';
import 'package:jewel/screens/test_screen2.dart';

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
  final JewelUser? jewelUser;

  const HomeScreen({super.key, required this.jewelUser, required this.calendarLogic, required this.initialIndex}); //requires the calendarLogic used from main.dart

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  
  late int _selectedIndex = widget.initialIndex; // would be used to track cached page index
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
    _screens = [ // widgets available in the nav bar
      SettingsScreen(jewelUser: widget.jewelUser,),
      CalendarEventsView(),
      MapSample(),
      Screen1(),
      Screen2(),
    ];
  }

  void _onItemTapped(int index) { // updates the index notifier
    final notifier = Provider.of<SelectedIndexNotifier>(context, listen: false);
    setState(() {
      notifier.selectedIndex = index;
    });
  }

  void updateSelectedCalendar(String calendarId) { // updates the calendar selected from the dropdown menu
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
        if (!kIsWeb) SizedBox(height: 24), // some difference in header space on the mobile devices
        // AppBar content as a child, now full width
        Container( // this is the whole top section of the screen. if its a web app caltools is part of is container. if anything else, its a separate element
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
              logicList(),
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
        if (!kIsWeb) Flexible(child: calTools()), // if not web app, caltools is separate
        Consumer<SelectedIndexNotifier>( // this recieves a message from the IndexNotifier and decides what screen to load based on the nav bar index
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
    bottomNavigationBar: Container( // this is the actual nav bar
    height: MediaQuery.of(context).size.height * 0.1325,
    child: CustomNavBar(
      currentIndex: context.watch<SelectedIndexNotifier>().selectedIndex,
      onTap: (index) {
        context.read<SelectedIndexNotifier>().selectedIndex = index;
      },
    ),
  ),
  );
}

PopupMenuButton<int> logicList()
{
  return PopupMenuButton<int>(
      icon: FaIcon(
        FontAwesomeIcons.google,
        size: 28,
        color: Colors.green,
      ),
      onSelected: (value) async {
        if (value == 1) {
          // Handle Add Account
          await handleSignIn();
        } else if (value == 2) {
          // Handle Sign Out
          await handleSignOut();
        }
      },
      itemBuilder: (context) {
        List<PopupMenuEntry<int>> menuItems = [];

        // Add menu items for calendarLogics
        if (widget.jewelUser?.calendarLogicList != null) {
          for (var calendarLogic in widget.jewelUser!.calendarLogicList!) {
            menuItems.add(
              PopupMenuItem<int>(
                value: 0,
                child: Text(calendarLogic.currentUser!.email),
              ),
            );
          }
        }

        // Add "Add Account" button at the bottom
        menuItems.add(
          PopupMenuItem<int>(
            value: 1,
            child: Text('Add Account'),
          ),
        );

        // Add "Sign Out" button at the bottom
        menuItems.add(
          PopupMenuItem<int>(
            value: 2,
            child: Text('Sign Out'),
          ),
        );

        return menuItems;
      },
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
        height: isWeb ? 75 : 55, 
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