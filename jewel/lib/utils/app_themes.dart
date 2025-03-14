
import 'package:flutter/material.dart';

class MyAppColors {
  static final darkGreen = Colors.green;
  static final lightGreen = Colors.green;
}

class MyAppThemes {
  static ThemeData lightThemeWithTextStyle(String textStyle) {
    TextTheme baseTextTheme = ThemeData.light().textTheme;

    // Apply text style modifications based on selection
    switch (textStyle) {
      case 'large':
        baseTextTheme = baseTextTheme.copyWith(
          bodyLarge: baseTextTheme.bodyLarge?.copyWith(fontSize: 20),
          bodyMedium: baseTextTheme.bodyMedium?.copyWith(fontSize: 18),
          titleLarge: baseTextTheme.titleLarge?.copyWith(fontSize: 22),
        );
        break;
      case 'serif':
        baseTextTheme = baseTextTheme.apply(fontFamily: 'Georgia');
        break;
      case 'monospace':
        baseTextTheme = baseTextTheme.apply(fontFamily: 'Courier');
        break;
      case 'default':
      default:
        // No change
        break;
    }

    return ThemeData(
      primaryColor: MyAppColors.lightGreen,
      brightness: Brightness.light,
      textTheme: baseTextTheme,
    );
  }

  static ThemeData darkThemeWithTextStyle(String textStyle) {
    TextTheme baseTextTheme = ThemeData.dark().textTheme;

    // Apply text style modifications based on selection
    switch (textStyle) {
      case 'large':
        baseTextTheme = baseTextTheme.copyWith(
          bodyLarge: baseTextTheme.bodyLarge?.copyWith(fontSize: 20),
          bodyMedium: baseTextTheme.bodyMedium?.copyWith(fontSize: 18),
          titleLarge: baseTextTheme.titleLarge?.copyWith(fontSize: 22),
        );
        break;
      case 'serif':
        baseTextTheme = baseTextTheme.apply(fontFamily: 'Georgia');
        break;
      case 'monospace':
        baseTextTheme = baseTextTheme.apply(fontFamily: 'Courier');
        break;
      case 'default':
      default:
        // No change
        break;
    }

    return ThemeData(
      primaryColor: MyAppColors.darkGreen,
      brightness: Brightness.dark,
      textTheme: baseTextTheme,
    );
  }
}
