import 'package:flutter/material.dart';

class ToggleButton extends StatefulWidget {
  @override
  _ToggleButtonState createState() => _ToggleButtonState();
}

class _ToggleButtonState extends State<ToggleButton> {
  List<bool> isSelected = [true, false];

  void _toggleButton(int index) {
    setState(() {
      // Set the selected index to true and the other to false
      for (int i = 0; i < isSelected.length; i++) {
        isSelected[i] = i == index;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ToggleButtons(
      isSelected: isSelected,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('On', style: TextStyle(fontSize: 18)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('Off', style: TextStyle(fontSize: 18)),
        ),
      ],
      onPressed: _toggleButton,
    );
  }
}

