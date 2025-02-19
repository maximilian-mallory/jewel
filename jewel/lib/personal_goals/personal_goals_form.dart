import 'package:flutter/material.dart';

class AddPersonalGoal extends StatefulWidget{
  final void Function(String title, String description, String category)
    onSubmit;
  
  const AddPersonalGoal({super.key, required this.onSubmit});

  @override
  _AddPersonalGoal createState() => _AddPersonalGoal();
}

class _AddPersonalGoal extends State<AddPersonalGoal>{
  final _formKey = GlobalKey<FormState>();
  final _goalTitleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();

    @override
  void dispose() {
    _goalTitleController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
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
            ),
            TextFormField(
              controller: _descriptionController,
            ),
            TextFormField(
              controller: _categoryController,
            ),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  widget.onSubmit(
                    _goalTitleController.text,
                    _descriptionController.text,
                    _categoryController.text,
                  );
                }
              },
              child: const Text("Add Calendar"),
            ),
          ],
        ),
      )
    );
  }
}