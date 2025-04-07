
import 'package:flutter/material.dart';

class CustomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const CustomNavBar({
    super.key, 
    required this.currentIndex, 
    required this.onTap
  });

 
  Map<String, double> _getResponsiveSizes(double screenWidth) {
    double iconSize;
    double fontSize;

    if (screenWidth >= 1024) {
      iconSize = 22;
      fontSize = 12;
    } else if (screenWidth >= 768) {
      iconSize = 20;
      fontSize = 12;
    } else if (screenWidth >= 425) {
      iconSize = 18;
      fontSize = 10;
    } else if (screenWidth >= 375) {
      iconSize = 16;
      fontSize = 8;
    } else {
      iconSize = 16;
      fontSize = 8;
    }
    return {'iconSize': iconSize, 'fontSize': fontSize};
  }

  @override
  Widget build(BuildContext context) {
    // Fetch the width of the device screen
    final double screenWidth = MediaQuery.of(context).size.width;
    final sizes = _getResponsiveSizes(screenWidth);

    return BottomAppBar(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // For adding a new option, create a "_buildNavItem".
            // The index here needs to match the index in the main.dart list.
            _buildNavItem(context, Icons.settings, 'Settings', 0, sizes),
            _buildNavItem(context, Icons.calendar_month, 'Calendar', 1, sizes),
            _buildNavItem(context, Icons.map, 'Maps', 2, sizes),
            _buildNavItem(context, Icons.checklist_sharp, 'Goals', 3, sizes),
            _buildNavItem(context, Icons.warning, 'TestEvent', 4, sizes),
            _buildNavItem(context, Icons.man_2_rounded, 'Groups', 5, sizes),
            
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, IconData icon, String label, int index, Map<String, double> sizes) {
    final isSelected = currentIndex == index;
    return GestureDetector(
      onTap: () => onTap(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: sizes['iconSize'],
            color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
          ),
          const SizedBox(height: 4),  // add a little spacing between icon and text
          Text(
            label,
            style: TextStyle(
              fontSize: sizes['fontSize'],
              color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
