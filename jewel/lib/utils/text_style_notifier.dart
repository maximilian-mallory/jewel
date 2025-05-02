import 'package:flutter/material.dart';
import 'package:jewel/utils/app_themes.dart';


class ThemeStyleNotifier extends ChangeNotifier {
  String _textStyle = 'default';
  Color  _themeColor = AppThemes.lightcolor; // default green

  String get textStyle  => _textStyle;
  Color  get themeColor => _themeColor;

  void updateTextStyle(String newStyle) {
    if (newStyle == _textStyle) return;
    _textStyle = newStyle;
    notifyListeners();
  }

  void updateThemeColor(Color c) {
    if (c == _themeColor) return;
    _themeColor           = c;
    AppThemes.lightcolor  = c;   // propagate to the global ThemeData builders
    AppThemes.darkcolor   = c;
    notifyListeners();
  }
}

Color brightenColor(Color color, [double amount = 0.2]) {
  final hsl = HSLColor.fromColor(color);
  final hslLight = hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0));
  return hslLight.toColor();
}