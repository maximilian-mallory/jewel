import 'package:flutter/material.dart';

class GoalScreen extends StatelessWidget {
  const GoalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Current Goals')), //TODO?: add functionality to change the 'Current' to be the category of goals selected
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          //TODO: Create logic for web/non web
          //TODO: Display all events
          //TODO: Create way of filtering goals
          //if on web:
            //make a grid of goals 
          //else on mobile
            //scrollable column
        ),
      ),
      floatingActionButton: FloatingActionButton(
        elevation: 5.0,
        backgroundColor: Colors.green,
        onPressed: (){}, //TODO: Pull up event creation form
        mini: true,
        child: Icon(Icons.add), 
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.miniEndTop, //floats the action button on the top right (the mini version)
    );
  }
}