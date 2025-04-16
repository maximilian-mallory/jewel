import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jewel/google/calendar/googleapi.dart';
import 'package:googleapis/calendar/v3.dart' as gcal;

// AddEvent class to create a new event in Google Calendar
class AddEvent extends StatefulWidget {
  // calendarApi instance to interact with Google Calendar API
  final gcal.CalendarApi calendarApi;
  const AddEvent({super.key, required this.calendarApi});

  @override
  _AddEvent createState() => _AddEvent();
}

// Private state class for AddEvent
class _AddEvent extends State<AddEvent> {
  // Final variables for form key and text controllers
  final _formKey = GlobalKey<FormState>();
  final _eventNameController = TextEditingController();
  final _eventLocationController = TextEditingController();
  final _eventDescriptionController = TextEditingController();

  // Variables to store start and end date and time
  DateTime? startDate;
  DateTime? endDate;

  // DateFormat instance to format date and time
  final DateFormat _dateFormat = DateFormat("yyyy-MM-dd HH:mm");

  // Function to pick date and time
  Future<void> _pickDateTime(BuildContext context, bool isStart) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (pickedTime != null) {
        setState(() {
          final selectedDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
          if (isStart) {
            startDate = selectedDateTime;
          } else {
            endDate = selectedDateTime;
          }
        });
      }
    }
  }

  // Function to submit form
  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (startDate == null || endDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select start and end times.')),
        );
        return;
      }

      if (endDate!.isBefore(startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time.')),
      );
      return;
    }

      String eventName = _eventNameController.text;
      String eventLocation = _eventLocationController.text;
      String eventDescription = _eventDescriptionController.text;

      // Print event details for debugging
      print("\n===== Event Details =====");
      print("Event Name: $eventName");
      print("Location: $eventLocation");
      print("Description: $eventDescription");
      print("Start Time: ${_dateFormat.format(startDate!)}");
      print("End Time: ${_dateFormat.format(endDate!)}");
      print("=========================\n");

      try {
        // Insert Event
        await insertGoogleEvent(
          calendarApi: widget.calendarApi,
          eventName: eventName,
          eventLocation: eventLocation,
          eventDescription: eventDescription,
          startDate: startDate!,
          endDate: endDate!,
        );

        Navigator.pop(context, true); // Notify to update page

        // Show confirmation message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Event "$eventName" Created! Check Google Calendar.')),
        );
      } catch (e) {
        print('Error adding event: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add event: $e')),
        );
      }

      // Reset form fields
      _formKey.currentState!.reset();
      _eventNameController.clear();
      _eventLocationController.clear();
      _eventDescriptionController.clear();
      setState(() {
        startDate = null;
        endDate = null;
      });
    }
  }

  // Clear the forms after submitting
  @override
  void dispose() {
    _eventNameController.dispose();
    _eventLocationController.dispose();
    _eventDescriptionController.dispose();
    super.dispose();
  }

  // Build the form UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Event")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _eventNameController,
                decoration: const InputDecoration(labelText: "Event Name"),
                validator: (value) =>
                    value!.isEmpty ? 'Enter event name' : null,
              ),
              TextFormField(
                controller: _eventLocationController,
                decoration: const InputDecoration(labelText: "Location"),
              ),
              TextFormField(
                controller: _eventDescriptionController,
                decoration: const InputDecoration(labelText: "Description"),
              ),
              ListTile(
                title: Text(
                  "Start Time: ${startDate != null ? _dateFormat.format(startDate!) : "Select"}",
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _pickDateTime(context, true),
              ),
              ListTile(
                title: Text(
                  "End Time: ${endDate != null ? _dateFormat.format(endDate!) : "Select"}",
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _pickDateTime(context, false),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitForm,
                child: const Text("Create Event"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
