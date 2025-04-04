import 'package:flutter/material.dart';

//Add rest of settings in here as they get implemented
class SettingsProvider extends ChangeNotifier {
  bool _isObfuscationEnabled = false;

  bool get isObfuscationEnabled => _isObfuscationEnabled;

  void toggleObfuscation(bool value) {
    _isObfuscationEnabled = value;
    notifyListeners(); // Notify listeners about the state change
  }
}
