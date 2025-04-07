import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:jewel/personal_goals/personal_goals_form.dart';
import 'package:jewel/personal_goals/edit_personal_goals_form.dart';
import 'package:jewel/firebase_ops/goals.dart';
import 'package:jewel/personal_goals/personal_goals.dart';

class GoalScreen extends StatefulWidget {
  const GoalScreen({super.key});

  @override
  _GoalScreenState createState() => _GoalScreenState();
}

class _GoalScreenState extends State<GoalScreen> {
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
  String? currentValue;
  Map<String, PersonalGoals> goals = {};
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

    goals.clear();

    final String? userEmail = FirebaseAuth.instance.currentUser?.email;

    if (userEmail == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    if (currentValue == null || currentValue == "All") {
      for (String category in goalCategories) {
        if (category != "All") {
          Map<String, PersonalGoals> categoryGoalsMap =
              await getGoalsFromFireBase(category, userEmail);
          goals.addAll(categoryGoalsMap);
        }
      }
    } else {
      Map<String, PersonalGoals> categoryGoalsMap =
          await getGoalsFromFireBase(currentValue!, userEmail);
      goals = categoryGoalsMap;
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text(currentValue == null ? 'Goals' : '$currentValue Goals'),
      actions: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Tooltip(
            message: "Select a category to filter goals",
            child: DropdownButton(
              value: currentValue,
              hint: const Text("Choose Category"),
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
                    currentValue = newValue;
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
                MaterialPageRoute(builder: (context) => const AddPersonalGoal()),
              ).then((_) => fetchGoals()); // Refresh goals after adding a new goal
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
                  String docId = goals.keys.elementAt(index);
                  PersonalGoals goal = goals[docId]!;

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditPersonalGoal(docId: docId, goal: goal),
                        ),
                      ).then((_) => fetchGoals()); // Refresh goals after editing
                    },
                    child: Card(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        color: Color.fromARGB(255, 57, 145, 102),
                        child: Center(
                          child: Text(
                            goal.title,
                          ),
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