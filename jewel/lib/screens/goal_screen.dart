import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:jewel/personal_goals/personal_goals_form.dart';
import 'package:jewel/firebase_ops/goals.dart';
import 'package:jewel/personal_goals/personal_goals.dart';

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
  List<PersonalGoals> goals = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchGoals();
  }

Future<void> fetchGoals() async {
  setState(() {
    isLoading = true;
  });

  goals = []; // Clear the goals list before fetching

  // Get the current user's email
  final String? userEmail = FirebaseAuth.instance.currentUser?.email;

  if (userEmail == null) {
    // Handle the case where the user is not logged in
    setState(() {
      isLoading = false;
    });
    return;
  }

  if (currentValue == null || currentValue == "All") {
    for (String category in goalCategories) {
      if (category != "All") { // Skip the "All" category as it's not a real category
        List<PersonalGoals> categoryGoals = await getGoalsFromFireBase(category, userEmail);
        
        // Sort categoryGoals alphabetically by title
        categoryGoals.sort((a, b) => a.title.compareTo(b.title));
        
        goals.addAll(categoryGoals); // Append the sorted goals from each category
      }
    }
  } else {
    goals = await getGoalsFromFireBase(currentValue!, userEmail); // Fetch goals for the specified category
  }

  setState(() {
    isLoading = false;
  });
}

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
                    fetchGoals();
                  }
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 10, right: 10),
            child: FloatingActionButton(
              elevation: 5.0,
              backgroundColor: Theme.of(context).primaryColor,
              onPressed: () {
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
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(10),
              child: Center(
                child: ListView.builder(
                  itemCount: goals.length,
                  itemBuilder: (context, index) {
                    return Card(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        color: Color.fromARGB(255, 57, 145, 102),
                        child: Center(
                          child: Text(
                            goals[index].title,
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
    );
  }
}