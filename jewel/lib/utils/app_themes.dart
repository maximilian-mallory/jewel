import 'package:flutter/material.dart';

class MyAppColors {
  static final darkGreen = Colors.green;
  static final lightGreen = Colors.green;
}

class MyAppThemes {
  static final lightTheme = ThemeData(
    primaryColor: MyAppColors.lightGreen,
    brightness: Brightness.light,
  );

  static final darkTheme = ThemeData(
    primaryColor: MyAppColors.darkGreen,
    brightness: Brightness.dark,
  );
}