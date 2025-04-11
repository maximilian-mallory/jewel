import 'package:flutter/material.dart';
import 'package:jewel/personal_goals/personal_goals.dart';
 
class EditPersonalGoal extends StatefulWidget {
  final String docId; // Document ID of the goal to edit
  final PersonalGoals goal; // The goal object to edit
 
  const EditPersonalGoal({super.key, required this.docId, required this.goal});
 
  @override
  _EditPersonalGoalState createState() => _EditPersonalGoalState();
}
 
class _EditPersonalGoalState extends State<EditPersonalGoal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _goalTitleController;
  late TextEditingController _descriptionController;
  late TextEditingController _durationController;
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
  void initState() {
    super.initState();
    // Initialize controllers with the current goal's data
    _goalTitleController = TextEditingController(text: widget.goal.title);
    _descriptionController = TextEditingController(text: widget.goal.description);
    _durationController = TextEditingController(text: widget.goal.duration.toString());
    _selectedCategory = widget.goal.category;
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
        title: const Text("Edit Goal"),
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
                  TextFormField(
                    controller: _goalTitleController,
                    decoration: const InputDecoration(
                      labelText: "Title",
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value!.isEmpty ? "Please enter a title" : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: "Description",
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    minLines: 3,
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
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
                      border: OutlineInputBorder(),
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
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        // Update the goal
                        widget.goal.title = _goalTitleController.text;
                        widget.goal.description = _descriptionController.text;
                        widget.goal.category = _selectedCategory ?? "Other";
                        widget.goal.duration = int.tryParse(_durationController.text) ?? 0;
 
                        await widget.goal.updateGoal(widget.docId);
 
                        // Show success message and navigate back
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Goal updated successfully!")),
                        );
                        Navigator.pop(context);
                      }
                    },
                    child: const Text("Update Goal"),
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