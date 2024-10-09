import 'package:flutter/material.dart';

class PersonalGoalForm extends StatelessWidget{
  const PersonalGoalForm({super.key});

  @override
  Widget build(BuildContext context) {
    return Form(
      child: Column(
        children: [
          Expanded(
            child: TextField(
              maxLines: null, // Set this 
              expands: true, // and this
              keyboardType: TextInputType.multiline,
            ),
          ),
        ],
      )
    );
  }

}