import 'package:flutter/material.dart';
import 'app_themes.dart';

class ThemeStyleNotifier extends ChangeNotifier {
  // Holds the current text style setting.
  String _textStyle = 'default';
  
  // Holds the current ThemeData built based on the text style.
  ThemeData _themeData = AppThemes.lightThemeWithTextStyle('default');

  String get textStyle => _textStyle;
  ThemeData get themeData => _themeData;

  // Updates the text style and rebuilds the theme.
  void updateTextStyle(String newStyle) {
    if (_textStyle != newStyle) {
      _textStyle = newStyle;
      _themeData = AppThemes.lightThemeWithTextStyle(_textStyle);
      notifyListeners();
    }
  }

  // Updates the background color for both lightgreen and darkgreen and rebuilds the theme.
  void updateThemeColor(Color color) {
    AppThemes.lightcolor = color;
    AppThemes.darkcolor = color;
    _themeData = AppThemes.lightThemeWithTextStyle(_textStyle);
    notifyListeners();
  }
}
