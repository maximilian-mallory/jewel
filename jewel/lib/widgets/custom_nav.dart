import 'package:flutter/material.dart';

// ignore: must_be_immutable
class CustomNav extends StatelessWidget{
  CustomNav({super.key});

  int currentPageIndex = 0;
  @override
  Widget build(BuildContext context) {
    
    return NavigationBar(
        onDestinationSelected: (int index) {
          setState(() {
            currentPageIndex = index;
          });
        },
        indicatorColor: Colors.cyan,
        selectedIndex: currentPageIndex,
        destinations: const <Widget>[
          NavigationDestination( //first destination option
            selectedIcon: Icon(Icons.home),
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          
          ),
          NavigationDestination( //second destination option
            icon: Badge(child: Icon(Icons.notifications_sharp)),
            label: 'Notifications',
          ),
          NavigationDestination( //third destination option
            icon: Badge(label: Text('2'),child: Icon(Icons.messenger_sharp),),
            label: 'Messages',
          ),
        ],
      );
  }
  
  void setState(Null Function() param0) {}
}