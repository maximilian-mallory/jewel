import 'package:flutter/material.dart';
import 'package:jewel/personal_goals/personal_goals.dart';

class AddPersonalGoal extends StatefulWidget{
  const AddPersonalGoal({super.key});

  @override
  _AddPersonalGoal createState() => _AddPersonalGoal();
}

class _AddPersonalGoal extends State<AddPersonalGoal>{
  final _formKey = GlobalKey<FormState>();
  final _goalTitleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedCategory;
  // List of categories
  final List<String> _categories = [
    "Health",
    "Work",
    "Personal Growth",
    "Finance",
    "Education",
    "Hobbies",
    "Other"
  ];
    @override
  void dispose() {
    _goalTitleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context){
    return SingleChildScrollView(// Ensures the form is scrollable when keyboard appears
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: _goalTitleController,
              decoration: const InputDecoration(labelText: "Goal Title"),
              validator: (value) => value!.isEmpty ? "Please enter a title" : null,
            ),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: "Description"),
              validator: (value) => value!.isEmpty ? "Please enter a description" : null,
            ),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: "Category"),
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
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  PersonalGoals newGoal = PersonalGoals(
                    _goalTitleController.text,
                    _descriptionController.text,
                    _selectedCategory ?? "Other",
                    false,
                    0
                  );
                  newGoal.storeGoal();
                }
              },
              child: const Text("Create Goal"),
            ),
          ],
        ),
      )
    );
  }
}