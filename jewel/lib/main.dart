import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:jewel/google/auth/auth_gate.dart';
import 'package:jewel/google/calendar/googleapi.dart';
import 'package:jewel/models/jewel_user.dart';
import 'package:jewel/screens/firebase_login_screen.dart';
import 'package:jewel/screens/intermediary.dart';
import 'package:jewel/screens/test_screen1.dart';
import 'package:jewel/widgets/home_screen.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'package:jewel/notifications.dart';
import 'package:flutter/foundation.dart';
import '/utils/fake_ui.dart' if (dart.library.html) '/utils/real_ui.dart' as ui;
import "package:universal_html/html.dart" as html;
import 'package:jewel/google/maps/google_maps_calculate_distance.dart';
import 'package:jewel/google/calendar/g_g_merge.dart';
import 'package:jewel/google/calendar/mode_toggle.dart';
import 'package:jewel/utils/app_themes.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables, web app needs to have an assets folder
  if (kIsWeb) {
    await dotenv.load(fileName: "assets/.env");
  } else {
    await dotenv.load(fileName: ".env");
  }

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize notifications
  /*await NotificationController.initializeLocalNotifications();
  NotificationController.createNewNotification();*/

  // Register the view type for the map
  if (kIsWeb) {
    ui.platformViewRegistry.registerViewFactory('map', (int viewId) {
      return html.DivElement()..id = 'map';
    });
  }

  // Fetch sorted events and convert addresses to coordinates
  // Map<String, dynamic> sortedEvents = await fetchEventData();
  // List<LatLng> coordinates = await convertAddressesToCoords(sortedEvents);
  // for (var coord in coordinates) {
  //   print('Coordinates: (${coord.latitude}, ${coord.longitude})');
  // }

  runApp(
    MultiProvider(
      // providers allow us to have app level access to objects
      providers: [
        ChangeNotifierProvider(
          // for the auth object
          create: (_) => JewelUser(),
        ),
        ChangeNotifierProvider(
          // keeps track of what screen the user is on
          create: (_) => SelectedIndexNotifier(
              1), // Initialize with a default index, e.g., 0
        ),
        ChangeNotifierProvider( // Keeps track of what calendar mode the user is in
          create: (context) => ModeToggle()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  final List<CalendarLogic> calendarLogicList = []; // listener for API calls
  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // if we can use BuildContext instead of Providers that would be cool
    return MaterialApp(
        debugShowCheckedModeBanner:
            false, //turns off the "dubug" banner in the top right corner
        title: 'Jewel',
        theme: MyAppThemes.lightTheme,
        darkTheme: MyAppThemes.darkTheme,
        themeMode: ThemeMode.system,
        home: AuthGate() // we immediately force the user to the loading screen, which makes the app unusable without a login
        );
  }
}
