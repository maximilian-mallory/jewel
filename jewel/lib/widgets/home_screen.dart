import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:jewel/google/calendar/add_calendar_form.dart';
import 'package:jewel/google/calendar/googleapi.dart';
import 'package:jewel/models/jewel_user.dart';
import 'package:jewel/user_groups/user_group.dart';
//import 'package:jewel/google/maps/map_screen.dart';
import 'package:jewel/utils/location.dart';
import 'package:jewel/widgets/custom_nav.dart';
import 'package:jewel/widgets/events_view.dart';
import 'package:jewel/widgets/gmap_screen.dart';
import 'package:jewel/widgets/settings.dart';
import 'package:googleapis/calendar/v3.dart' as gcal;
import 'package:provider/provider.dart';
import 'package:jewel/screens/test_screen1.dart';
import 'package:jewel/screens/user_group_screen.dart';

import 'package:jewel/screens/test_screen2.dart';

/// Returns a map of responsive values based on screen width.
/// Breakpoints:
///  - >= 1440px: Extra Large Computer Screen
///  - >= 1024px: Large Computer Screen
///  - >= 768px: Tablet
///  - >= 425px: Large Smartphone
///  - >= 375px: Medium Smartphone
///  - < 375px: Small Smartphone
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

/// SelectedIndexNotifier tracks the selected index and scroll positions.
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
  final CalendarLogic calendarLogic;
  final int initialIndex;
  final JewelUser jewelUser;

  const HomeScreen({
    super.key,
    required this.jewelUser,
    required this.calendarLogic,
    required this.initialIndex,
  });

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
    getLocationData();
    final notifier = Provider.of<SelectedIndexNotifier>(context, listen: false);
    _selectedIndex = widget.initialIndex;
    googleSignIn.onCurrentUserChanged
        .listen((GoogleSignInAccount? account) async {
      setState(() {
        widget.calendarLogic.currentUser = account;
        widget.calendarLogic.isAuthorized = account != null;
      });

      widget.jewelUser.calendarLogicList?[0].events =
          await getGoogleEventsData(widget.calendarLogic, context);
    });
    _screens = [
      // widgets available in the nav bar
      SettingsScreen(
        jewelUser: widget.jewelUser,
      ),
      CalendarEventsView(jewelUser: widget.jewelUser),
      MapSample(),
      Screen1(),
      Screen2(),
      UserGroupScreen(),
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
      widget.calendarLogic.events =
          await getGoogleEventsData(widget.calendarLogic, context);
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

    return Container(
      height: headerHeight,
      width: double.infinity,
      padding: EdgeInsets.all(
          isWeb ? res['horizontalPadding']! : res['horizontalPadding']! * 90.8),
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
        children: [
          logicList(),
          SizedBox(
              width: isWeb
                  ? res['horizontalPadding']! * 0.3
                  : res['horizontalPadding']! * 0.2),
          // calTools container width adjusts based on responsive value
          isWeb
              ? Flexible(child: calTools())
              : Flexible(
                  child: SizedBox(width: res['horizontalPadding']! * 10)),
          const SizedBox(width: 10),
          // Conditionally display Jewel logo only if not a smartphone.
          if (!isSmartphone)
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
                  height:
                      isWeb ? res['iconSize']! * 1.5 : res['iconSize']! * 0.8,
                  width:
                      isWeb ? res['iconSize']! * 1.5 : res['iconSize']! * 0.8,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final res = getResponsiveValues(context);
    return Scaffold(
      body: Column(
        children: [
          if (!kIsWeb) SizedBox(height: 24),
          buildHeader(context),
          if (!kIsWeb) Flexible(child: calTools()),
          Consumer<SelectedIndexNotifier>(
            builder: (context, selectedIndexNotifier, _) {
              return SizedBox(
                height: MediaQuery.of(context).size.height -
                    getHeaderHeight(context) -
                    (kIsWeb ? 0 : 24) -
                    (MediaQuery.of(context).size.height * 0.1325),
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

  PopupMenuButton<int> logicList() {
    return PopupMenuButton<int>(
      icon: FaIcon(
        FontAwesomeIcons.google,
        size: 28,
        color: Colors.green,
      ),
      onSelected: (value) async {
        if (value == 1) {
          await handleSignIn();
        } else if (value == 2) {
          await handleSignOut();
        }
      },
      itemBuilder: (context) {
        List<PopupMenuEntry<int>> menuItems = [];
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
    return Container(
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
        child: SizedBox(
          height: isWeb ? 75 : 55,
          child: Align(
            alignment: Alignment.center,
            child: AuthenticatedCalendar(
            ),
          ),
        ),
      ),
    );
  }
}
