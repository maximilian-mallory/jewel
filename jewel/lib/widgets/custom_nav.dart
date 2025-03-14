import 'package:flutter/material.dart';

class CustomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const CustomNavBar(
      {super.key, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          //For adding a new option, you need to create a "_buildNavItem"
          //This creates a widget that has paramaters as an icon, label, and index
          //The index here needs to match the index in the main.dart list
          _buildNavItem(Icons.settings, 'Settings', 0),
          _buildNavItem(Icons.calendar_month, 'Calendar', 1),
          _buildNavItem(Icons.map, 'Maps', 2),
          _buildNavItem(Icons.theater_comedy_sharp, 'Test', 3),
          _buildNavItem(Icons.warning, 'TestEvent', 4),
          _buildNavItem(Icons.man_2_rounded, 'Groups', 5)
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = currentIndex == index;
    return GestureDetector(
      onTap: () => onTap(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? Colors.green : Colors.grey,
          ),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.green : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
