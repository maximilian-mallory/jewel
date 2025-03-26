import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:jewel/models/jewel_user.dart';
import 'package:jewel/utils/location.dart';
import 'package:permission_handler/permission_handler.dart' as handler;

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
                ToggleSetting(
                  title: 'Do Not Disturb',
                  ),
              ],
            ),
            SettingsCategory(
              title: 'Privacy',
              settings: [
                ToggleSetting(
                  title: 'Obfuscate Data',
                  ),
                ToggleSetting(
                  title: 'Show Only Shared Events',
                  ),
              ],
            ),
            SettingsCategory(
              title: 'Permissions',
              settings: [
                ToggleSetting(
                  title: 'Notification Permission',
                  ),
                ToggleSetting(
                  title: 'Location Permission',
                  ),
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
    await FirebaseFirestore.instance.collection('users').doc(docId).set(user.toJson());
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

class _ToggleSettingState extends State<ToggleSetting> with WidgetsBindingObserver {
  bool _value = false;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Check permission status on initialization for both platforms
    if (widget.title == 'Location Permission') {
      _updateLocationPermissionStatus();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (widget.title == 'Location Permission' && state == AppLifecycleState.resumed) {
      _updateLocationPermissionStatus();
    }
  }
  
  Future<void> _updateLocationPermissionStatus() async {
    try {
      bool hasPermission = await checkLocationPermission();
      if (mounted) {
        setState(() {
          _value = hasPermission;
          print("Location permission status: $hasPermission");
        });
      }
    } catch (e) {
      print("Error checking location permission: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Remove the permission check from build method to prevent infinite loops
    return SwitchListTile(
      title: Text(widget.title),
      value: _value,
      onChanged: (bool newValue) async {
        if (widget.title == 'Location Permission') {
          // Don't change the toggle state yet - only after confirming permission change
          if (newValue) {
            // User trying to enable location
            var locationData = await getLocationData(context);
            // Only update state after we know if permission was successful
            _updateLocationPermissionStatus();
          } else {
            // User trying to disable location
            if (kIsWeb) {
              // Show a dialog with instructions for web users
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text('Permission Required'),
                    content: Text('Please manually change the location permission in your browser settings to revoke location permissions'),
                    actions: <Widget>[
                      ElevatedButton(
                        child: Text('OK'),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  );
                },
              );
            } else if (!kIsWeb) {
              // Don't change toggle state yet
              try {
                // Request location permission
                await handler.openAppSettings();
                
                // Re-check permission after settings opened
                // Need a small delay to allow user to change settings
                Future.delayed(Duration(seconds: 2), () async {
                  if (mounted) {
                    _updateLocationPermissionStatus();
                  }
                });
                
              } catch (e) {
                print("Error opening app settings: $e");
              }
            }
          }
        } else {
          // For non-location toggles, update immediately
          setState(() {
            _value = newValue;
          });
        }
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