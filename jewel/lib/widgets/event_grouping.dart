import 'package:flutter/material.dart';
import 'package:jewel/models/event_group.dart'; // Import the EventGroup class
import 'package:jewel/widgets/color_picker.dart'; // Import the ColorPickerDialog widget

class CreateGroupDialog extends StatefulWidget {
  @override
  _CreateGroupDialogState createState() => _CreateGroupDialogState();
}

class _CreateGroupDialogState extends State<CreateGroupDialog> {
  TextEditingController _titleController = TextEditingController();
  Color _selectedColor = Colors.blue;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Create Group'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: _titleController,
            decoration: InputDecoration(labelText: "Group Title"),
          ),
          ListTile(
            title: Text("Group Color"),
            trailing: Icon(Icons.color_lens),
            onTap: () async {
              Color? pickedColor = await showDialog(
                context: context,
                builder: (context) =>
                    ColorPickerDialog(initialColor: _selectedColor),
              );
              if (pickedColor != null) {
                setState(() {
                  _selectedColor = pickedColor;
                });
              }
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null), // Close dialog
          child: Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () {
            if (_titleController.text.isNotEmpty) {
              EventGroup newGroup = EventGroup(
                title: _titleController.text,
                color: _selectedColor,
              );
              Navigator.pop(context, newGroup);
            }
          },
          child: Text("Create"),
        ),
      ],
    );
  }
}
