import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:jewel/models/jewel_user.dart';
import 'package:provider/provider.dart';
import 'package:jewel/utils/text_style_notifier.dart';

class SettingsScreen extends StatelessWidget {
  final JewelUser? jewelUser;
  const SettingsScreen({super.key, required this.jewelUser});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            SettingsCategory(
              title: 'Text Style',
              settings: [
                TextStyleSetting(),
              ],
            ),
            SizedBox(height: 20), // Adds some space before the button
            ElevatedButton(
              onPressed: () {
                saveUserToFirestore(jewelUser!);
              },
              child: Text('Save Settings'),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> saveUserToFirestore(JewelUser user) async {
  final docId = user.email; // Use email as document ID
  await FirebaseFirestore.instance
      .collection('users')
      .doc(docId)
      .set(user.toJson());
}

class SettingsCategory extends StatelessWidget {
  final String title;
  final List<Widget> settings;

  const SettingsCategory({super.key, required this.title, required this.settings});

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

  const ToggleSetting({super.key, required this.title});

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

  const ColorPickerSetting({super.key, required this.title});

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

  const NumberInputSetting({super.key, required this.title});

  @override
  _NumberInputSettingState createState() => _NumberInputSettingState();
}

class _NumberInputSettingState extends State<NumberInputSetting> {
  int _currentValue = 0;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(widget.title),
      trailing: SizedBox(
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

// Updated widget for selecting text style using Provider, ensuring the dropdown reflects the global value.
class TextStyleSetting extends StatelessWidget {
  const TextStyleSetting({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TextStyleNotifier>(
      builder: (context, textStyleNotifier, child) {
        return ListTile(
          title: Text('Select Text Style'),
          trailing: DropdownButton<String>(
            value: textStyleNotifier.textStyle,
            items: ['default', 'large', 'serif', 'monospace'].map((String style) {
              return DropdownMenuItem<String>(
                value: style,
                child: Text(style[0].toUpperCase() + style.substring(1)),
              );
            }).toList(),
            onChanged: (String? newStyle) {
              if (newStyle != null) {
                textStyleNotifier.updateTextStyle(newStyle);
              }
            },
          ),
        );
      },
    );
  }
}