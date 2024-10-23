import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:jewel/google/auth/auth_gate.dart';
import 'package:jewel/firebase_options.dart';
<<<<<<< HEAD
import 'package:jewel/widgets/custom_nav.dart';
import 'package:jewel/screens/test_screen1.dart';
import 'package:jewel/screens/test_screen2.dart';
import 'package:jewel/screens/test_screen3.dart';
import 'auth/app.dart';
=======
import 'package:jewel/widgets/calendar_event_list.dart';
import 'package:jewel/widgets/event_list_screen.dart';
import 'widgets/toggle_button.dart';
import 'package:jewel/widgets/custom_nav.dart';
import '/google/calendar/g_g_merge.dart';
import 'google/auth/app.dart';
import 'package:jewel/notifications.dart';

>>>>>>> 7add08b5dd0f72d912468e052918d58a20e8f76a

Future<void> main() async {
 WidgetsFlutterBinding.ensureInitialized();
 await Firebase.initializeApp(
   options: DefaultFirebaseOptions.currentPlatform,
 );
await NotificationController.initializeLocalNotifications();
NotificationController.createNewNotification(); //sends notification when app is ran
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, //turns off the "dubug" banner in the top right corner
      title: 'Jewel',
<<<<<<< HEAD
      home: HomeScreen()
=======
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
      home: CalendarEventList()
      //MyHomePage(title: 'Flutter Demo Home Page'),
>>>>>>> 7add08b5dd0f72d912468e052918d58a20e8f76a
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    //This is the list of screens, if you need to add one to the navigation bar make sure 
    //it is in the same order as it shows up here
    //You also need to add it to the navigation which is in widgets/custom_nav.dart
    Screen1(), //0
    Screen2(), //1
    Screen3(), //2
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Jewel')),
      body: _screens[_selectedIndex],
      bottomNavigationBar: CustomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}