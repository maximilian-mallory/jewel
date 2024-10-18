import 'package:flutter/material.dart';

class SecondScreen extends StatefulWidget {
  @override
  _SecondScreenState createState() => _SecondScreenState();
}

class _SecondScreenState extends State<SecondScreen> {
  bool isActive = false;

  void _toggleActive() {
    setState(() {
      isActive = !isActive;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Welcome to the Second Screen!',
            style: TextStyle(fontSize: 24),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20),
          Text(
            isActive ? 'Status: Active' : 'Status: Inactive',
            style: TextStyle(fontSize: 20),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: _toggleActive,
            child: Text('Toggle Status'),
          ),
        ],
      ),
    );
  }
}