import 'package:flutter/material.dart';
import 'package:jewel/personal_goals/personal_goals_form.dart';

class GoalScreen extends StatefulWidget {
  const GoalScreen({super.key});

  @override
  _GoalScreenState createState() => _GoalScreenState();
}

class _GoalScreenState extends State<GoalScreen> {
  //Goals from personal_goals_form.dart with the added "All" for when they want to display all goals again
  final List<String> goalCategories = [
      "Health",
      "Work",
      "Personal Growth",
      "Finance",
      "Education",
      "Hobby",
      "Other",
      "All"
    ];
    String? currentValue; //starts off as null but can be used to filter -> changes with drop down selection
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(currentValue == null ? 'Goals' : '$currentValue Goals'), //if currentValue is null, display 'Goals' else, displays the category
        actions: <Widget>[
          Padding( 
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Tooltip(
              message: "Select a category to filter goals",
              child: DropdownButton(
                value: currentValue,
                hint: const Text("Choose Category"), // Displays when value is null
                icon: const Icon(Icons.keyboard_arrow_down),    
                items: goalCategories.map((String items) {
                  return DropdownMenuItem(
                    value: items,
                    child: Text(items),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      currentValue = newValue; // Updates and rebuilds the widget
                    });
                  }
                },
              )
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 10, right: 10),
            child: FloatingActionButton(
              elevation: 5.0,
              backgroundColor: Colors.green,
              onPressed: (){
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddPersonalGoal()), //navigates the user to the personal goals form
                );
              },
              tooltip: 'Create Goal',
              mini: true,
              child: Icon(Icons.add), 
            ),
          ),  
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(10),
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
    );
  }
}