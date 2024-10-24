import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:jewel/google/auth/auth_gate.dart';
import 'package:jewel/firebase_options.dart';
import 'package:jewel/widgets/custom_nav.dart';
import 'package:jewel/screens/test_screen1.dart';
import 'package:jewel/screens/test_screen2.dart';
import 'package:jewel/screens/test_screen3.dart';
import 'package:jewel/widgets/calendar_event_list.dart';
import 'package:jewel/widgets/event_list_screen.dart';
import 'package:jewel/widgets/home_screen.dart';
import 'widgets/toggle_button.dart';
import 'package:jewel/widgets/custom_nav.dart';
import '/google/calendar/g_g_merge.dart';
import 'package:jewel/notifications.dart';


Future<void> main() async {
 WidgetsFlutterBinding.ensureInitialized();
 await Firebase.initializeApp(
   options: DefaultFirebaseOptions.currentPlatform,
 );
await NotificationController.initializeLocalNotifications();
NotificationController.createNewNotification(); //sends notification when app is ran
await dotenv.load(fileName: ".env");
runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, //turns off the "dubug" banner in the top right corner
      title: 'Jewel',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: AuthGate()
      //MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}
