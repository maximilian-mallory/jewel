import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:jewel/auth/auth_gate.dart';
import 'package:jewel/firebase_options.dart';
import 'package:jewel/widgets/custom_nav.dart';
import 'package:jewel/screens/test_screen1.dart';
import 'package:jewel/screens/test_screen2.dart';
import 'package:jewel/screens/test_screen3.dart';
import 'auth/app.dart';

Future<void> main() async {
   WidgetsFlutterBinding.ensureInitialized();
 await Firebase.initializeApp(
   options: DefaultFirebaseOptions.currentPlatform,
 );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, //turns off the "dubug" banner in the top right corner
      title: 'Jewel',
      home: HomeScreen()
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