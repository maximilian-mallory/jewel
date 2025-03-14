import 'package:flutter/foundation.dart';

class TextStyleNotifier extends ChangeNotifier {
  String _textStyle = 'default';

  String get textStyle => _textStyle;

  void updateTextStyle(String newStyle) {
    if (_textStyle != newStyle) {
      _textStyle = newStyle;
      notifyListeners();
    }
  }
}