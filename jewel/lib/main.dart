import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:jewel/google/calendar/googleapi.dart';
import 'package:jewel/screens/intermediary.dart';
import 'package:jewel/widgets/home_screen.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'package:jewel/notifications.dart';
import 'package:flutter/foundation.dart';
import '/utils/fake_ui.dart' if (dart.library.html) '/utils/real_ui.dart' as ui;
import "package:universal_html/html.dart" as html;
import 'package:jewel/google/maps/google_maps_calculate_distance.dart';
import 'package:jewel/google/calendar/g_g_merge.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
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
  await NotificationController.initializeLocalNotifications();
  NotificationController.createNewNotification();

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
    providers: [
      ChangeNotifierProvider(
        create: (_) => CalendarLogic(),
      ),
      ChangeNotifierProvider(
        create: (_) => SelectedIndexNotifier(1), // Initialize with a default index, e.g., 0
      ),
    ],
    child: MyApp(),
  ),
);
}

class MyApp extends StatelessWidget {
  final CalendarLogic calendarLogic = CalendarLogic();  //listener for API calls
  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, //turns off the "dubug" banner in the top right corner
      title: 'Jewel',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: Intermediary(calendarLogic: calendarLogic)
      //MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}
