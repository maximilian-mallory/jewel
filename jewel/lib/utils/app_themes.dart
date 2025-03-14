
import 'package:flutter/material.dart';

class MyAppColors {
  static final darkGreen = Colors.green;
  static final lightGreen = Colors.green;
}

class MyAppThemes {
  static ThemeData lightThemeWithTextStyle(String textStyle) {
    TextTheme baseTextTheme = ThemeData.light().textTheme;

    // Modify the base text theme based on the selected text style option.
    switch (textStyle) {
      case 'large':
        baseTextTheme = baseTextTheme.copyWith(
          bodyLarge: baseTextTheme.bodyLarge?.copyWith(fontSize: 20),
          bodyMedium: baseTextTheme.bodyMedium?.copyWith(fontSize: 18),
          titleLarge: baseTextTheme.titleLarge?.copyWith(fontSize: 22),
        );
        break;
      case 'serif':
        // Instead of applying a font family, adjust sizes so there's a visible difference.
        baseTextTheme = baseTextTheme.copyWith(
          bodyLarge: baseTextTheme.bodyLarge?.copyWith(fontSize: 18),
          bodyMedium: baseTextTheme.bodyMedium?.copyWith(fontSize: 16),
          titleLarge: baseTextTheme.titleLarge?.copyWith(fontSize: 20),
        );
        break;
      case 'monospace':
        // Adjust to slightly smaller sizes for a noticeable effect.
        baseTextTheme = baseTextTheme.copyWith(
          bodyLarge: baseTextTheme.bodyLarge?.copyWith(fontSize: 16),
          bodyMedium: baseTextTheme.bodyMedium?.copyWith(fontSize: 14),
          titleLarge: baseTextTheme.titleLarge?.copyWith(fontSize: 18),
        );
        break;
      case 'default':
      default:
        // No modifications for default
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

    // Modify the base text theme based on the selected text style option.
    switch (textStyle) {
      case 'extra Large':
        baseTextTheme = baseTextTheme.copyWith(
          bodyLarge: baseTextTheme.bodyLarge?.copyWith(fontSize: 20),
          bodyMedium: baseTextTheme.bodyMedium?.copyWith(fontSize: 18),
          titleLarge: baseTextTheme.titleLarge?.copyWith(fontSize: 22),
        );
        break;
      case 'large':
        baseTextTheme = baseTextTheme.copyWith(
          bodyLarge: baseTextTheme.bodyLarge?.copyWith(fontSize: 18),
          bodyMedium: baseTextTheme.bodyMedium?.copyWith(fontSize: 16),
          titleLarge: baseTextTheme.titleLarge?.copyWith(fontSize: 20),
        );
        break;
      case 'small':
        baseTextTheme = baseTextTheme.copyWith(
          bodyLarge: baseTextTheme.bodyLarge?.copyWith(fontSize: 10),
          bodyMedium: baseTextTheme.bodyMedium?.copyWith(fontSize: 8),
          titleLarge: baseTextTheme.titleLarge?.copyWith(fontSize: 12),
        );
        break;
      case 'default':
      default:
        // No modifications for default
        break;
    }

    return ThemeData(
      primaryColor: MyAppColors.darkGreen,
      brightness: Brightness.dark,
      textTheme: baseTextTheme,
    );
  }
}
