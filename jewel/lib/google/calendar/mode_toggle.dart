import 'package:flutter/material.dart';

// This class is used to toggle between daily and monthly view modes
class ModeToggle extends ChangeNotifier {
  bool _isMonthlyView = false; // Default to Daily View

  bool get isMonthlyView => _isMonthlyView; // Getter to expose value

  void toggleViewMode() {
    _isMonthlyView = !_isMonthlyView;
    notifyListeners(); // Notify UI to rebuild
  }
}
