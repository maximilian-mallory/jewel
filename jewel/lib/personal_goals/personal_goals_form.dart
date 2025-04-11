import 'package:flutter/material.dart';
import 'package:jewel/personal_goals/personal_goals.dart';

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
      return screenWidth * 0.9; // Mobile: 90% width
    } else if (screenWidth < 1200) {
      return screenWidth * 0.6; // Tablet: 60% width
    } else {
      return 800; // Desktop: Fixed max width
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add a Goal!"),
        centerTitle: true,
      ),
      body: SingleChildScrollView( // Ensures form is scrollable on small screens
        child: Center( // Centers the form on larger screens
          child: Container(
            width: getFormWidth(context), // Responsive width
            padding: const EdgeInsets.all(16), // Adds spacing
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min, // Prevent unnecessary expansion
                children: [
                  TextFormField(
                    controller: _goalTitleController,
                    decoration: const InputDecoration(
                      labelText: "Title",
                      border: OutlineInputBorder()
                    ),
                    validator: (value) => value!.isEmpty ? "Please enter a title" : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: "Description",
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true
                    ),
                    minLines: 3,  // Starts with 3 lines
                    maxLines: null,  // Allows expansion as needed
                    keyboardType: TextInputType.multiline,  // Enables multiline input
                    validator: (value) => value!.isEmpty ? "Please enter a description" : null,
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
                      labelText: "Category",
                      border: OutlineInputBorder()
                    ),
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
                    },
                    validator: (value) => value == null ? "Please select a category" : null,
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
                          int.tryParse(_durationController.text) ?? 0
                        );
                        newGoal.storeGoal();

                        // Clear input fields and reset the dropdown
                        setState(() {
                          _goalTitleController.clear();
                          _descriptionController.clear();
                          _selectedCategory = null; // Reset dropdown selection
                          _durationController.clear();
                        });

                        // Show success message
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Goal added successfully!"))
                        );
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