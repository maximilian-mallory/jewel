import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:jewel/google/calendar/googleapi.dart';
import 'package:jewel/screens/intermediary.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'package:jewel/widgets/home_screen.dart';
import 'package:jewel/notifications.dart';
import 'package:flutter/foundation.dart';
import '/utils/fake_ui.dart' if (dart.library.html) '/utils/real_ui.dart' as ui;
import "package:universal_html/html.dart" as html;

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


  runApp(
    ChangeNotifierProvider(
      create: (_) => CalendarLogic(),
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
