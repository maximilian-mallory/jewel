import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:googleapis/serviceusage/v1.dart';
import 'package:jewel/models/jewel_user.dart';
import 'package:jewel/utils/platform/notifications.dart';
import 'package:provider/provider.dart';
import 'package:jewel/utils/text_style_notifier.dart';
import 'package:jewel/utils/platform/location.dart';
import 'package:permission_handler/permission_handler.dart' as handler;
import 'package:jewel/utils/app_themes.dart';
import 'package:jewel/firebase_ops/user_specific.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:jewel/widgets/settings_provider.dart';
import 'package:jewel/utils/app_themes.dart'; // New import for updating theme colors

/// Returns responsive values based on the current screen width.
/// These breakpoints match those used in add_calendar_form.dart.
Map<String, double> getResponsiveValues(BuildContext context) {
  final double screenWidth = MediaQuery.of(context).size.width;
  double horizontalPadding, verticalPadding, titleFontSize;
  if (screenWidth >= 1440) {
    horizontalPadding = 64.0;
    verticalPadding = 40.0;
    titleFontSize = 22.0;
  } else if (screenWidth >= 1024) {
    horizontalPadding = 48.0;
    verticalPadding = 32.0;
    titleFontSize = 20.0;
  } else if (screenWidth >= 768) {
    horizontalPadding = 32.0;
    verticalPadding = 24.0;
    titleFontSize = 18.0;
  } else if (screenWidth >= 425) {
    horizontalPadding = 24.0;
    verticalPadding = 16.0;
    titleFontSize = 16.0;
  } else if (screenWidth >= 375) {
    horizontalPadding = 16.0;
    verticalPadding = 12.0;
    titleFontSize = 16.0;
  } else {
    horizontalPadding = 14.0;
    verticalPadding = 10.0;
    titleFontSize = 14.0;
  }
  // settingFontSize is 2 points smaller than the category title
  final double settingFontSize = titleFontSize - 2.0;
  return {
    'horizontalPadding': horizontalPadding,
    'verticalPadding': verticalPadding,
    'titleFontSize': titleFontSize,
    'settingFontSize': settingFontSize,
  };
}

/// Helper function to convert the selected text style value to a multiplier.
double getTextStyleMultiplier(String textStyle) {
  switch (textStyle) {
    case 'extra Large':
      return 1.2;
    case 'large':
      return 1.1;
    case 'small':
      return 0.8;
    case 'default':
    default:
      return 1.0;
  }
}

class SettingsScreen extends StatelessWidget {
  final JewelUser? jewelUser;
  const SettingsScreen({
    super.key,
    required this.jewelUser,
  });

  @override
  Widget build(BuildContext context) {
    final res = getResponsiveValues(context);
    final settingsProvider = Provider.of<SettingsProvider>(
        context); // Access the SettingsProvider without listening to changes
    return Scaffold(
        body: Center(
      child: ListView(
          padding: EdgeInsets.symmetric(
            horizontal: res['horizontalPadding']!,
            vertical: res['verticalPadding']!,
          ),
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
                  initialValue: false, // Default value for the toggle
                  onChanged: (value) {
                    // Implement functionality for Do Not Disturb toggle change
                  },
                ),
              ],
            ),
            SettingsCategory(
              title: 'Privacy',
              settings: [
                ToggleSetting(
                  title: 'Obfuscate Event Info',
                  initialValue: settingsProvider.isObfuscationEnabled,
                  onChanged: (value) {
                    settingsProvider.toggleObfuscation(value);
                  },
                ),
                ToggleSetting(
                    title: 'Show Only Shared Events',
                    initialValue: false,
                    onChanged: (value) {
                      // Implement changed functionality
                    }),
              ],
            ),
            SettingsCategory(
              title: 'Permissions',
              settings: [
                ToggleSetting(
                  title: 'Notification Permission',
                  initialValue: false,
                  onChanged: (value) {
                    // Implement functionality for notification permission change
                  },
                ),
                ToggleSetting(
                  title: 'Location Permission',
                  initialValue: false,
                  onChanged: (value) {
                    // Implement functionality for location permission change
                  },
                ),
              ],
            ),
            SettingsCategory(
              title: 'Text Style',
              settings: [
                TextStyleSetting(),
                SettingsCategory(
                  title: 'Appearance',
                  settings: [
                    BackgroundColorToggle(),
                  ],
                ),
                SizedBox(height: res['verticalPadding']),
                ElevatedButton(
                  onPressed: () {
                    saveUserToFirestore(jewelUser!);
                  },
                  child: const Text('Save Settings'),
                ),
              ],
            ),
          ]),
    ));
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

  const SettingsCategory(
      {super.key, required this.title, required this.settings});

  @override
  Widget build(BuildContext context) {
    final res = getResponsiveValues(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // This is the category header; it uses titleFontSize.
        Consumer<ThemeStyleNotifier>(
          builder: (context, textStyleNotifier, child) {
            double multiplier =
                getTextStyleMultiplier(textStyleNotifier.textStyle);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                title,
                style: TextStyle(
                  fontSize: res['titleFontSize']! * multiplier,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            );
          },
        ),
        ...settings,
        const Divider(),
      ],
    );
  }
}

class ToggleSetting extends StatefulWidget {
  final String title;
  final bool initialValue;
  final Function(bool)? onChanged;
  const ToggleSetting(
      {super.key,
      required this.title,
      this.initialValue = false,
      required this.onChanged});

  @override
  _ToggleSettingState createState() => _ToggleSettingState();
}

class _ToggleSettingState extends State<ToggleSetting>
    with WidgetsBindingObserver {
  bool _value = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Check permission status on initialization for both platforms
    if (widget.title == 'Location Permission') {
      _updateLocationPermissionStatus();
    }
    if (widget.title == 'Notification Permission') {
      _updateNotificationPermissionStatus();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (widget.title == 'Location Permission' &&
        state == AppLifecycleState.resumed) {
      _updateLocationPermissionStatus();
    }
    if (widget.title == 'Notification Permission' &&
        state == AppLifecycleState.resumed) {
      _updateNotificationPermissionStatus();
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

  Future<void> _updateNotificationPermissionStatus() async {
    try {
      bool hasPermission = await checkNotificationPermission();
      if (mounted) {
        setState(() {
          _value = hasPermission;
          print("Notification permission status: $hasPermission");
        });
      }
    } catch (e) {
      print("Error checking notification permission: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeStyleNotifier, SettingsProvider>(
      builder: (context, textStyleNotifier, settingsProvider, child) {
        double multiplier = getTextStyleMultiplier(textStyleNotifier.textStyle);
        final res = getResponsiveValues(context);
        final bool currentValue =
            settingsProvider.getSetting(widget.title) ?? widget.initialValue;
        // Use settingFontSize for individual setting widget titles.
        return SwitchListTile(
          title: Text(
            widget.title,
            style: TextStyle(fontSize: res['settingFontSize']! * multiplier),
          ),
          value: (widget.title == 'Location Permission' ||
                  widget.title == 'Notification Permission')
              ? _value
              : currentValue,
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
                        content: Text(
                            'Please manually change the location permission in your browser settings to revoke location permissions'),
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
            }
            if (widget.title == 'Notification Permission') {
              // Don't change the toggle state yet - only after confirming permission change
              if (newValue) {
                // User trying to enable notifications

                // Only update state after we know if permission was successful
                var status = await handler.Permission.notification.request();
                if (status.isPermanentlyDenied) {
                  // User denied permission
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text('Permission Denied'),
                        content: Text(
                            'Notification permission is denied. Please enable it from the app settings.'),
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
                }
                _updateNotificationPermissionStatus();
              } else {
                // User trying to disable notifications
                if (kIsWeb) {
                  // Show a dialog with instructions for web users
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text('Permission Required'),
                        content: Text(
                            'Please manually change the notification permission in your browser settings to revoke notification permissions'),
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
                    // Request notification permission
                    await handler.openAppSettings();

                    // Re-check permission after settings opened
                    // Need a small delay to allow user to change settings
                    Future.delayed(Duration(seconds: 2), () async {
                      if (mounted) {
                        _updateNotificationPermissionStatus();
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
              settingsProvider.setSetting(widget.title, newValue);
            }
          },
        );
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
  Color _currentColor = Colors.green;

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
              child: const Text('Done'),
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
    return Consumer<ThemeStyleNotifier>(
      builder: (context, textStyleNotifier, child) {
        double multiplier = getTextStyleMultiplier(textStyleNotifier.textStyle);
        final res = getResponsiveValues(context);
        // Use settingFontSize here.
        return ListTile(
          title: Text(
            widget.title,
            style: TextStyle(fontSize: res['settingFontSize']! * multiplier),
          ),
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
      },
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
    return Consumer<ThemeStyleNotifier>(
      builder: (context, textStyleNotifier, child) {
        double multiplier = getTextStyleMultiplier(textStyleNotifier.textStyle);
        final res = getResponsiveValues(context);
        // Use settingFontSize for the individual setting title.
        return ListTile(
          title: Text(
            widget.title,
            style: TextStyle(fontSize: res['settingFontSize']! * multiplier),
          ),
          trailing: SizedBox(
            width: 100,
            child: TextField(
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
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
      },
    );
  }
}

class TextStyleSetting extends StatelessWidget {
  const TextStyleSetting({super.key});

  @override
  Widget build(BuildContext context) {
    final res = getResponsiveValues(context);
    return Consumer<ThemeStyleNotifier>(
      builder: (context, textStyleNotifier, child) {
        double multiplier = getTextStyleMultiplier(textStyleNotifier.textStyle);
        // Use settingFontSize for the widget title.
        return ListTile(
          title: Text(
            'Select Text Style',
            style: TextStyle(fontSize: res['settingFontSize']! * multiplier),
          ),
          trailing: DropdownButton<String>(
            value: textStyleNotifier.textStyle,
            items: ['default', 'extra Large', 'large', 'small']
                .map((String style) {
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

/// New widget that lets the user pick a background color
/// Once selected, it updates the lightgreen and darkgreen variables in app_themes.dart.
class BackgroundColorToggle extends StatefulWidget {
  const BackgroundColorToggle({super.key});

  @override
  _BackgroundColorToggleState createState() => _BackgroundColorToggleState();
}

class _BackgroundColorToggleState extends State<BackgroundColorToggle> {
  // Initialize the selected color with the current lightgreen color from AppThemes.
  Color _selectedColor = AppThemes.lightcolor;

  void _pickColor() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Pick a background color'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: _selectedColor,
              onColorChanged: (Color color) {
                setState(() {
                  _selectedColor = color;
                });
              },
            ),
          ),
          actions: <Widget>[
            ElevatedButton(
              child: const Text('Done'),
              onPressed: () {
                final uid = FirebaseAuth.instance.currentUser!.email!;
                UserSettingsService().saveThemeColor(uid, _selectedColor);
                Provider.of<ThemeStyleNotifier>(context, listen: false)
                    .updateThemeColor(_selectedColor);
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
    return Consumer<ThemeStyleNotifier>(
      builder: (context, textStyleNotifier, child) {
        double multiplier = getTextStyleMultiplier(textStyleNotifier.textStyle);
        final res = getResponsiveValues(context);
        return ListTile(
          title: Text(
            'Background Color',
            style: TextStyle(fontSize: res['settingFontSize']! * multiplier),
          ),
          trailing: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: _selectedColor,
              shape: BoxShape.circle,
            ),
          ),
          onTap: _pickColor,
        );
      },
    );
  }
}
