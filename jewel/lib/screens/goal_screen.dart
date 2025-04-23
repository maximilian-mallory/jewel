import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:jewel/personal_goals/personal_goals_form.dart';
import 'package:jewel/personal_goals/edit_personal_goals_form.dart';
import 'package:jewel/firebase_ops/goals.dart';
import 'package:jewel/personal_goals/personal_goals.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

    await deleteExpiredCompletedGoals();

    setState(() {
      isLoading = false;
    });
  }

  Future<void> deleteExpiredCompletedGoals() async {
    final now = DateTime.now();
    final String? userEmail = FirebaseAuth.instance.currentUser?.email;
    if (userEmail == null) return;

    List<String> docsToDelete = [];
    for (final entry in goals.entries) {
      final goal = entry.value;
      if (goal.completed && goal.completedAt != null) {
        final completedTime = goal.completedAt!;
        if (now.difference(completedTime).inHours >= 24) {
          docsToDelete.add(entry.key);
          // Delete from Firestore
          await FirebaseFirestore.instance
              .collection('goals')
              .doc(goal.category)
              .collection(userEmail)
              .doc(entry.key)
              .delete();
        }
      }
    }

    // Remove from local map
    for (final docId in docsToDelete) {
      goals.remove(docId);
    }
  }

  Future<void> toggleGoalCompletion(String docId, PersonalGoals goal) async {
    try {
      final wasComplete = goal.completed;
      if (!wasComplete) {
        // Marking as complete – set completedAt
        goal.completed = true;
        goal.completedAt = DateTime.now();
      } else {
        // Marking as incomplete – clear completedAt
        goal.completed = false;
        goal.completedAt = null;
      }

      // Update the goal in Firebase
      await goal.updateGoal(docId);

      // Refresh the UI (fetchGoals includes expired-goal deletion)
      setState(() {
        fetchGoals();
      });

      print(
          'Goal "${goal.title}" marked as ${goal.completed ? "complete" : "incomplete"}.');
    } catch (e) {
      print('Error updating goal: $e');
    }
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
                  MaterialPageRoute(
                      builder: (context) => const AddPersonalGoal()),
                ).then((_) =>
                    fetchGoals()); // Refresh goals after adding a new goal
              },
              tooltip: 'Create Goal',
              mini: true,
              child: const Icon(Icons.add),
            ),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Current Goals Section
                  const Text(
                    'Current Goals',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  goals.values.any((goal) => !goal.completed)
                      ? ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: goals.length,
                          itemBuilder: (context, index) {
                            String docId = goals.keys.elementAt(index);
                            PersonalGoals goal = goals[docId]!;

                            if (goal.completed) return const SizedBox.shrink();

                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EditPersonalGoal(
                                        docId: docId, goal: goal),
                                  ),
                                ).then((_) => fetchGoals());
                              },
                              child: Card(
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(20),
                                  color:
                                      const Color.fromARGB(255, 57, 145, 102),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      // Centered Goal Title
                                      Expanded(
                                        child: Center(
                                          child: Text(
                                            goal.title,
                                            style: const TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                      // "Mark as Complete" Button
                                      ElevatedButton(
                                        onPressed: () {
                                          toggleGoalCompletion(docId, goal);
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blue,
                                        ),
                                        child: const Text(
                                          'Mark as Complete',
                                          style: TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        )
                      : const Center(
                          child: Text(
                            'All goals completed. Nice Job!',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                  const SizedBox(height: 20),
                  // Completed Goals Section
                  const Text(
                    'Completed Goals',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  goals.values.any((goal) => goal.completed)
                      ? ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: goals.length,
                          itemBuilder: (context, index) {
                            String docId = goals.keys.elementAt(index);
                            PersonalGoals goal = goals[docId]!;

                            if (!goal.completed) return const SizedBox.shrink();

                            return Card(
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(20),
                                color: const Color.fromARGB(255, 100, 100, 100),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Centered Goal Title
                                    Expanded(
                                      child: Center(
                                        child: Text(
                                          goal.title,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                    // "Mark as Incomplete" Button
                                    ElevatedButton(
                                      onPressed: () {
                                        toggleGoalCompletion(docId, goal);
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.orange,
                                      ),
                                      child: const Text(
                                        'Mark as Incomplete',
                                        style: TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        )
                      : const Center(
                          child: Text(
                            'No completed goals.',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                ],
              ),
            ),
    );
  }
}
