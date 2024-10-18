import 'package:flutter/material.dart';
import 'package:jewel/auth/home.dart';
import 'package:jewel/second_screen.dart';
import 'widgets/custom_nav.dart';

class MainLayout extends StatefulWidget {
  @override
  _MainLayoutState createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  final int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Flutter Permanent NavigationBar Demo'),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          HomeScreen(),
          SecondScreen(),
        ],
      ),
      bottomNavigationBar: CustomNavigationBar(
        selectedIndex: _selectedIndex,
      ),
    );
  }
}