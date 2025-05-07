import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:jewel/google/auth/auth_gate.dart';
import 'package:jewel/google/calendar/add_calendar_form.dart';
import 'package:jewel/google/calendar/googleapi.dart';
import 'package:jewel/models/jewel_user.dart';
import 'package:jewel/screens/goal_screen.dart';
import 'package:jewel/screens/intermediary.dart';
import 'package:jewel/user_groups/user_group.dart';
//import 'package:jewel/google/maps/map_screen.dart';
import 'package:jewel/utils/platform/location.dart';
import 'package:jewel/widgets/custom_nav.dart';
import 'package:jewel/widgets/events_view.dart';
import 'package:jewel/widgets/gmap_screen.dart';
import 'package:jewel/widgets/settings.dart';
import 'package:googleapis/calendar/v3.dart' as gcal;
import 'package:provider/provider.dart';
import 'package:jewel/screens/test_screen1.dart';
import 'package:jewel/screens/user_group_screen.dart';
import 'package:jewel/screens/analytics_screen.dart';
import 'package:jewel/google/calendar/calendar_logic.dart';
import 'package:jewel/google/calendar/google_sign_in.dart';
import 'package:jewel/utils/text_style_notifier.dart';
import 'package:jewel/screens/leaderboard_screen.dart';

Map<String, double> getResponsiveValues(BuildContext context) {
  final double screenWidth = MediaQuery.of(context).size.width;
  double horizontalPadding,
      verticalPadding,
      iconSize,
      buttonPadding,
      titleFontSize;
  if (screenWidth >= 1440) {
    horizontalPadding = 64.0;
    verticalPadding = 40.0;
    iconSize = 50.0;
    buttonPadding = 12.0;
    titleFontSize = 22.0;
  } else if (screenWidth >= 1024) {
    horizontalPadding = 48.0;
    verticalPadding = 32.0;
    iconSize = 45.0;
    buttonPadding = 10.0;
    titleFontSize = 20.0;
  } else if (screenWidth >= 768) {
    horizontalPadding = 32.0;
    verticalPadding = 24.0;
    iconSize = 35.0;
    buttonPadding = 8.0;
    titleFontSize = 18.0;
  } else if (screenWidth >= 425) {
    horizontalPadding = 20.0;
    verticalPadding = 16.0;
    iconSize = 30.0;
    buttonPadding = 6.0;
    titleFontSize = 16.0;
  } else if (screenWidth >= 375) {
    horizontalPadding = 16.0;
    verticalPadding = 12.0;
    iconSize = 25.0;
    buttonPadding = 5.0;
    titleFontSize = 15.0;
  } else {
    horizontalPadding = 8.0;
    verticalPadding = 8.0;
    iconSize = 15.0;
    buttonPadding = 2.0;
    titleFontSize = 14.0;
  }
  return {
    'horizontalPadding': horizontalPadding,
    'verticalPadding': verticalPadding,
    'iconSize': iconSize,
    'buttonPadding': buttonPadding,
    'titleFontSize': titleFontSize,
  };
}

/// SelectedIndexNotifier tracks the selected index and scroll positions.import 'package:jewel/screens/goal_screen.dart';

class SelectedIndexNotifier extends ChangeNotifier {
  int _selectedIndex;
  Map<int, double> _scrollPositions = {};

  SelectedIndexNotifier(this._selectedIndex);

  int get selectedIndex => _selectedIndex;

  set selectedIndex(int newIndex) {
    _selectedIndex = newIndex;
    notifyListeners();
  }

  double getScrollPosition(int index) {
    return _scrollPositions[index] ?? 0.0;
  }

  setScrollPosition(int index, double position) {
    _scrollPositions[index] = position;
    notifyListeners();
  }
}

class HomeScreen extends StatefulWidget {
  final int initialIndex;

  const HomeScreen({
    super.key,
    required this.initialIndex,
  });

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _selectedIndex = widget.initialIndex;
  late gcal.CalendarApi calendarApi;
  late final List<Widget> _screens;
  late JewelUser jewelUser;
  late CalendarLogic calendarLogic;
  bool isWeb = kIsWeb;
  bool _isObfuscationEnabled = false;

  void _toggleObfuscation(bool value) {
    setState(() {
      _isObfuscationEnabled = !_isObfuscationEnabled;
    });
  }

  @override
  void initState() {
    super.initState();
    getLocationData(context);
    final notifier = Provider.of<SelectedIndexNotifier>(context, listen: false);
    jewelUser = Provider.of<JewelUser>(context, listen: false);
    int selectedCalendarIndex = jewelUser.calendarLogicList!.length - 1;
    _selectedIndex = widget.initialIndex;
    googleSignInList[selectedCalendarIndex]
        .onCurrentUserChanged
        .listen((GoogleSignInAccount? account) async {
      setState(() {
        calendarLogic.currentUser = account;
        calendarLogic.isAuthorized = account != null;
      });

      jewelUser.calendarLogicList?[selectedCalendarIndex].events =
          await getGoogleEventsData(calendarLogic, context);
    });
    _screens = [
      // widgets available in the nav bar
      SettingsScreen(
        jewelUser: jewelUser,
      ),
      CalendarEventsView(),
      MapSample(),
      GoalScreen(),
      UserGroupScreen(),
      AnalyticsScreen(),
      LeaderboardScreen(),
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
      calendarLogic.selectedCalendar = calendarId;
      calendarLogic.events = await getGoogleEventsData(calendarLogic, context);
    });
  }

  /// Builds a fixed header height based on screen width rather than a percentage of overall height.
  double getHeaderHeight(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth >= 1440) {
      return 200.0;
    } else if (screenWidth >= 1024) {
      return 150.0;
    } else if (screenWidth >= 768) {
      return 120.0;
    } else if (screenWidth >= 425) {
      return 80.0;
    } else {
      return 70.0;
    }
  }

  /// Builds the top header section with responsive design.
Widget buildHeader(BuildContext context) {
    final res = getResponsiveValues(context);
    final screenWidth = MediaQuery.of(context).size.width;
    // Define smartphone threshold as width <= 426px.
    final bool isSmartphone = screenWidth <= 426;
    final double headerHeight = getHeaderHeight(context);
    
    // Use kIsWeb consistently rather than isWeb for platform detection
    final bool isWebPlatform = kIsWeb;

    return Container(
      // Increase height slightly on Android to accommodate calTools in the header
      height: isWebPlatform ? headerHeight : headerHeight * 1.2,
      width: double.infinity,
      padding: EdgeInsets.all(
          isWebPlatform ? res['horizontalPadding']! : res['horizontalPadding']! * 0.8),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween, // Improved spacing
        crossAxisAlignment: CrossAxisAlignment.center, // Ensure vertical centering
        children: [
          // Force a larger tap target for the account menu on Android
          Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: isWebPlatform ? res['iconSize']! * 1.5 : res['iconSize']! * 1.5,
                width: isWebPlatform ? res['iconSize']! * 1.5 : res['iconSize']! * 1.5,
              alignment: Alignment.center,
              child: accountList(),
            ),
          ),
        ),
          SizedBox(
              width: isWebPlatform
                  ? res['horizontalPadding']! * 0.3
                  : res['horizontalPadding']! * 0.2),
          
          // Place calTools in header for both web and Android
          Expanded(
            child: Container(
              alignment: Alignment.center,
              height: double.infinity,
              child: calTools(),
            ),
          ),
          
          const SizedBox(width: 10),
          
          // Display Jewel logo for all platforms
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                'assets/images/jewel205.png',
                height: isWebPlatform ? res['iconSize']! * 1.5 : res['iconSize']! * 1.5,
                width: isWebPlatform ? res['iconSize']! * 1.5 : res['iconSize']! * 1.5,
                // Ensure the image loads by adding error handling
                errorBuilder: (context, error, stackTrace) {
                  print("Error loading logo: $error");
                  return Container(
                    height: isWebPlatform ? res['iconSize']! * 1.5 : res['iconSize']! * 1.2,
                    width: isWebPlatform ? res['iconSize']! * 1.5 : res['iconSize']! * 1.2,
                    color: Colors.grey.shade300,
                    child: Icon(Icons.image_not_supported),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget accountList() {
    JewelUser jewelUser = Provider.of<JewelUser>(context, listen: false);
    final bool isWebPlatform = kIsWeb;
    
    return PopupMenuButton<int>(
      icon: FaIcon(
        FontAwesomeIcons.google,
        size: isWebPlatform ? 46 : 32, // Larger icon for Android
        color: brightenColor(Theme.of(context).primaryColor),
      ),
      // Center the icon vertically
      padding: EdgeInsets.zero,
      onSelected: (int value) async {
        // Handle selection here instead of individual onTap
        if (value == 1) {
          // Add Account
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => Intermediary()),
          );
        } else if (value == 2) {
          // Sign Out
          FirebaseAuth.instance.signOut();
          if (jewelUser.calendarLogicList != null && 
                jewelUser.calendarLogicList!.isNotEmpty) {
                await googleSignInList[0].signOut();
                
                // Optional: remove the signed out account from the list
                jewelUser.calendarLogicList = [];
                jewelUser.updateFrom(jewelUser);
                }
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => AuthGate()),
          );
        } else if (value >= 100) {
          // Account selection (using offset of 100 to distinguish from actions)
          // jewelUser.updateSelectedCalendarIndex(value - 100);
        }
      },
      itemBuilder: (context) {
        List<PopupMenuEntry<int>> menuItems = [];
        if (jewelUser.calendarLogicList != null) {
          int i = 0;
          for (var calendarLogic in jewelUser.calendarLogicList!) {
            menuItems.add(
              PopupMenuItem<int>(
                value: 100 + i, // Use 100+ to differentiate from action items
                child: Text(calendarLogic.currentUser!.email),
              ),
            );
            i++;
          }
        }
        menuItems.add(
          const PopupMenuItem<int>(
            value: 1,
            child: Text('Add Account'),
          ),
        );
        menuItems.add(
          const PopupMenuItem<int>(
            value: 2,
            child: Text('Sign Out'),
          ),
        );
        return menuItems;
      },
    );
  }

  Widget calTools() {
    // Use kIsWeb consistently rather than isWeb
    final bool isWebPlatform = kIsWeb;
    final res = getResponsiveValues(context);
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).cardColor, // Add background color for better visibility
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          // Adjust size for Android to fit nicely in header
          height: isWebPlatform ? 75 : 50,
          // Constrain width on mobile to fit in header
          width: isWebPlatform ? double.infinity : MediaQuery.of(context).size.width * 0.75,
          child: Align(
            alignment: Alignment.center,
            child: AuthenticatedCalendar(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Add status bar padding only on mobile
          if (!kIsWeb) SizedBox(height: MediaQuery.of(context).padding.top),
          
          // Use buildHeader which now handles both header and calTools
          buildHeader(context),
          
          // Main content area
          Consumer<SelectedIndexNotifier>(
            builder: (context, selectedIndexNotifier, _) {
              // Calculate remaining screen space for main content
              // No need to account for separate calTools height anymore since it's in the header
              double mainContentHeight = MediaQuery.of(context).size.height - 
                  (kIsWeb ? getHeaderHeight(context) : getHeaderHeight(context) * 1.2) - 
                  (kIsWeb ? 0 : MediaQuery.of(context).padding.top) - // Use system status bar height
                  (MediaQuery.of(context).size.height * 0.1325); // Bottom nav height
                  
              return SizedBox(
                height: mainContentHeight,
                child: _screens[selectedIndexNotifier.selectedIndex],
              );
            },
          )
        ],
      ),
      bottomNavigationBar: Container(
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
}