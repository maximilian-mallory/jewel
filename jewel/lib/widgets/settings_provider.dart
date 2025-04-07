import 'package:flutter/material.dart';

//Add rest of settings in here as they get implemented
class SettingsProvider extends ChangeNotifier {
  final Map<String, dynamic> _settings = {
    'Obfuscate Event Info': false,
    'Show Only Shared Events': false,
    'Do Not Disturb': false,
  };

  bool _isObfuscationEnabled = false;

  bool get isObfuscationEnabled => _isObfuscationEnabled;

  void toggleObfuscation(bool value) {
    _isObfuscationEnabled = value;
    notifyListeners(); // Notify listeners about the state change
  }

  dynamic getSetting(String title) => _settings[title];

  void setSetting(String title, dynamic value) {
    if (_settings.containsKey(title)) {
      _settings[title] = value;
      notifyListeners();
    }
  }
}
