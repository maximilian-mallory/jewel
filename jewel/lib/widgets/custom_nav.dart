import 'package:flutter/material.dart';

class CustomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const CustomNavBar({super.key, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          //For adding a new option, you need to create a "_buildNavItem"
          //This creates a widget that has paramaters as an icon, label, and index
          //The index here needs to match the index in the main.dart list
          _buildNavItem(Icons.business, 'Business', 0),
          _buildNavItem(Icons.school, 'School', 1),
          _buildNavItem(Icons.school, 'Maps', 2),
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
          Icon(icon,color: isSelected ? Colors.blue : Colors.grey,),
          Text(label,style: TextStyle(color: isSelected ? Colors.blue : Colors.grey,),),
        ],
      ),
    );
  }
}