
import 'package:flutter/material.dart';
import 'package:jewel/personal_goals/personal_goals.dart';
import 'dart:math';

class AddPersonalGoal extends StatefulWidget {
  const AddPersonalGoal({super.key});

  @override
  _AddPersonalGoal createState() => _AddPersonalGoal();
}

class _AddPersonalGoal extends State<AddPersonalGoal> {
  final _formKey = GlobalKey<FormState>();
  final _goalTitleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _durationController = TextEditingController();
  String? _selectedCategory;

  // List of categories
  final List<String> _categories = [
    "Health",
    "Work",
    "Personal Growth",
    "Finance",
    "Education",
    "Hobby",
    "Other"
  ];

  Map<String, dynamic>? _goalSuggestion; // Structured suggestion

  @override
  void initState() {
    super.initState();
    _generateGoalSuggestion();
  }

  void _generateGoalSuggestion() {
    setState(() {
      _goalSuggestion = getGoalSuggestion(_selectedCategory);
    });
  }

  @override
  void dispose() {
    _goalTitleController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  double getFormWidth(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 600) {
      return screenWidth * 0.9;
    } else if (screenWidth < 1200) {
      return screenWidth * 0.6;
    } else {
      return 800;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add a Goal!"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            width: getFormWidth(context),
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // --- Goal Suggestion UI
                  Card(
                    color: Colors.blue[50],
                    margin: const EdgeInsets.only(bottom: 12.0),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: _goalSuggestion != null
                                ? Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Suggestion: ${_goalSuggestion!['title']}",
                                        style: const TextStyle(
                                          fontStyle: FontStyle.italic,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      Text(
                                        "Category: ${_goalSuggestion!['category']}    Time: ${_goalSuggestion!['duration']} min",
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ],
                                  )
                                : const Text(
                                    "No suggestion available.",
                                    style: TextStyle(
                                      fontStyle: FontStyle.italic,
                                      color: Colors.black87,
                                    ),
                                  ),
                          ),
                          IconButton(
                            tooltip: "Regenerate suggestion",
                            icon: const Icon(Icons.refresh),
                            onPressed: _generateGoalSuggestion,
                          ),
                          if (_goalSuggestion != null)
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _goalTitleController.text =
                                      _goalSuggestion!['title'];
                                  _selectedCategory =
                                      _goalSuggestion!['category'];
                                  _durationController.text =
                                      _goalSuggestion!['duration'].toString();
                                });
                              },
                              child: const Text("Use"),
                            ),
                        ],
                      ),
                    ),
                  ),
                  // --- End Goal Suggestion UI
                  TextFormField(
                    controller: _goalTitleController,
                    decoration: const InputDecoration(
                        labelText: "Title", border: OutlineInputBorder()),
                    validator: (value) =>
                        value!.isEmpty ? "Please enter a title" : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                        labelText: "Description",
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true),
                    minLines: 3,
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    validator: (value) =>
                        value!.isEmpty ? "Please enter a description" : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _durationController,
                    decoration: const InputDecoration(
                      labelText: "Time in Minutes",
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Please enter the time in minutes";
                      }
                      if (int.tryParse(value) == null) {
                        return "Please enter a valid number";
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                        labelText: "Category", border: OutlineInputBorder()),
                    value: _selectedCategory,
                    items: _categories.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value;
                      });
                      _generateGoalSuggestion();
                    },
                    validator: (value) =>
                        value == null ? "Please select a category" : null,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        // Create and store the goal
                        PersonalGoals newGoal = PersonalGoals(
                            _goalTitleController.text,
                            _descriptionController.text,
                            _selectedCategory ?? "Other",
                            false,
                            int.tryParse(_durationController.text) ?? 0);
                        newGoal.storeGoal();

                        // Clear input fields and reset the dropdown
                        setState(() {
                          _goalTitleController.clear();
                          _descriptionController.clear();
                          _selectedCategory = null;
                          _durationController.clear();
                        });

                        // Generate a new suggestion for the next goal
                        _generateGoalSuggestion();

                        // Show success message
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text("Goal added successfully!")));
                      }
                    },
                    child: const Text("Create Goal"),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Returns a suggestion as a map with title, category, and duration
Map<String, dynamic> getGoalSuggestion(String? category) {
  // Example suggestions: Each is a map.
  final List<Map<String, dynamic>> suggestions = [
    {
      'title': "Go for a 30-minute walk",
      'category': "Health",
      'duration': 30,
    },
    {
      'title': "Try a new healthy recipe",
      'category': "Health",
      'duration': 45,
    },
    {
      'title': "Drink 8 cups of water today",
      'category': "Health",
      'duration': 2,
    },
    {
      'title': "Finish a small work-related task",
      'category': "Work",
      'duration': 30,
    },
    {
      'title': "Organize your workspace",
      'category': "Work",
      'duration': 15,
    },
    {
      'title': "Respond to all important emails",
      'category': "Work",
      'duration': 20,
    },
    {
      'title': "Read a chapter from a book",
      'category': "Personal Growth",
      'duration': 20,
    },
    {
      'title': "Write one page in a journal",
      'category': "Personal Growth",
      'duration': 10,
    },
    {
      'title': "Spend 10 minutes meditating",
      'category': "Personal Growth",
      'duration': 10,
    },
    {
      'title': "Track all expenses for today",
      'category': "Finance",
      'duration': 15,
    },
    {
      'title': "Review monthly spending",
      'category': "Finance",
      'duration': 20,
    },
    {
      'title': "Make a budget plan",
      'category': "Finance",
      'duration': 30,
    },
    {
      'title': "Watch an educational video",
      'category': "Education",
      'duration': 25,
    },
    {
      'title': "Review class notes",
      'category': "Education",
      'duration': 20,
    },
    {
      'title': "Practice a new skill for 20 minutes",
      'category': "Education",
      'duration': 20,
    },
    {
      'title': "Draw something new",
      'category': "Hobby",
      'duration': 30,
    },
    {
      'title': "Practice your musical instrument",
      'category': "Hobby",
      'duration': 20,
    },
    {
      'title': "Work on your hobby project",
      'category': "Hobby",
      'duration': 40,
    },
    {
      'title': "Call a friend or family member",
      'category': "Other",
      'duration': 10,
    },
    {
      'title': "Tidy up your room",
      'category': "Other",
      'duration': 15,
    },
    {
      'title': "Declutter digital files",
      'category': "Other",
      'duration': 20,
    },
    // Fallbacks
    {
      'title': "Take a short break and stretch",
      'category': "Other",
      'duration': 5,
    },
    {
      'title': "Set a new small personal challenge for the day",
      'category': "Personal Growth",
      'duration': 10,
    },
  ];

  List<Map<String, dynamic>> filtered = category != null
      ? suggestions.where((s) => s['category'] == category).toList()
      : suggestions;

  if (filtered.isEmpty) filtered = suggestions;

  final rand = Random();
  return filtered[rand.nextInt(filtered.length)];
}
