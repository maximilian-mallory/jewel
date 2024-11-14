import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: Center(
        child: ListView(
          padding: EdgeInsets.all(16.0),
          children: [
            SettingsCategory(
              title: 'Calendar',
              settings: [
                ColorPickerSetting(title: 'Event Color'),
              ],
            ),
            SettingsCategory(
              title: 'Notifications',
              settings: [
                NumberInputSetting(title: 'Set Snooze Timer'),
                ToggleSetting(title: 'Do Not Disturb'),
              ],
            ),
            SettingsCategory(
              title: 'Privacy',
              settings: [
                ToggleSetting(title: 'Obfuscate Data'),
                ToggleSetting(title: 'Show Only Shared Events'),
              ],
            ),
            SettingsCategory(
              title: 'Permissions',
              settings: [
                ToggleSetting(title: 'Notification Permission'),
                ToggleSetting(title: 'Location Permission'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsCategory extends StatelessWidget {
  final String title;
  final List<Widget> settings;

  SettingsCategory({required this.title, required this.settings});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            title,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
        ...settings,
        Divider(),
      ],
    );
  }
}

class ToggleSetting extends StatefulWidget {
  final String title;

  ToggleSetting({required this.title});

  @override
  _ToggleSettingState createState() => _ToggleSettingState();
}

class _ToggleSettingState extends State<ToggleSetting> {
  bool _value = false;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Text(widget.title),
      value: _value,
      onChanged: (bool newValue) {
        setState(() {
          _value = newValue;
        });
      },
    );
  }
}

class ColorPickerSetting extends StatefulWidget {
  final String title;

  ColorPickerSetting({required this.title});

  @override
  _ColorPickerSettingState createState() => _ColorPickerSettingState();
}

class _ColorPickerSettingState extends State<ColorPickerSetting> {
  Color _currentColor = Colors.blue;

  void _pickColor() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Pick a color'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: _currentColor,
              onColorChanged: (Color color) {
                setState(() {
                  _currentColor = color;
                });
              },
            ),
          ),
          actions: <Widget>[
            ElevatedButton(
              child: Text('Done'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(widget.title),
      trailing: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: _currentColor,
          shape: BoxShape.circle,
        ),
      ),
      onTap: _pickColor,
    );
  }
}

class NumberInputSetting extends StatefulWidget {
  final String title;

  NumberInputSetting({required this.title});

  @override
  _NumberInputSettingState createState() => _NumberInputSettingState();
}

class _NumberInputSettingState extends State<NumberInputSetting> {
  int _currentValue = 0;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(widget.title),
      trailing: Container(
        width: 100,
        child: TextField(
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: 'Enter number',
          ),
          onChanged: (String value) {
            setState(() {
              _currentValue = int.tryParse(value) ?? 0;
            });
          },
        ),
      ),
    );
  }
}