import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CustomNavigationBar extends StatelessWidget {
  final int selectedIndex;

  const CustomNavigationBar({
    required this.selectedIndex,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      onDestinationSelected: (int index) {
        switch (index) {
          case 0:
            context.go('/'); // Navigate to Home
            break;
          case 1:
            context.go('/second'); // Navigate to Second Screen
            break;
        }
      },
      selectedIndex: selectedIndex,
      destinations: const <NavigationDestination>[
        NavigationDestination(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.settings),
          label: 'Second',
        ),
      ],
    );
  }
}