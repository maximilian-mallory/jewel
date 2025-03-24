
import 'package:flutter/material.dart';

class MyAppColors {
  static final darkGreen = Colors.green;
  static final lightGreen = Colors.green;
}

class MyAppThemes {
  static ThemeData lightThemeWithTextStyle(String textStyle) {
    TextTheme baseTextTheme = ThemeData.light().textTheme;
    // Determine the modifier based on the chosen text style option.
    double multiplier = _getModifier(textStyle);

    // Apply the multiplier to the base text theme.
    baseTextTheme = _applyModifier(baseTextTheme, multiplier);

    return ThemeData(
      primaryColor: MyAppColors.lightGreen,
      brightness: Brightness.light,
      textTheme: baseTextTheme,
    );
  }

  static ThemeData darkThemeWithTextStyle(String textStyle) {
    TextTheme baseTextTheme = ThemeData.dark().textTheme;
    double multiplier = _getModifier(textStyle);
    baseTextTheme = _applyModifier(baseTextTheme, multiplier);

    return ThemeData(
      primaryColor: MyAppColors.darkGreen,
      brightness: Brightness.dark,
      textTheme: baseTextTheme,
    );
  }

  // Returns a percentage multiplier for the given text style option.
  static double _getModifier(String textStyle) {
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

  // Applies the multiplier to key properties of the text theme.
  static TextTheme _applyModifier(TextTheme theme, double multiplier) {
    return theme.copyWith(
      bodyLarge: theme.bodyLarge?.copyWith(
          fontSize: (theme.bodyLarge?.fontSize ?? 16) * multiplier),
      bodyMedium: theme.bodyMedium?.copyWith(
          fontSize: (theme.bodyMedium?.fontSize ?? 14) * multiplier),
      titleLarge: theme.titleLarge?.copyWith(
          fontSize: (theme.titleLarge?.fontSize ?? 20) * multiplier),
      // Add other text styles if desired.
    );
  }
}
