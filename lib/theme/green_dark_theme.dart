import 'package:flutter/material.dart';

ThemeData buildGreenDarkTheme() {
  return ThemeData(
    brightness: Brightness.dark,
    primaryColor: Colors.green,
    scaffoldBackgroundColor: Colors.green[900]!, // Dark green background
    colorScheme: const ColorScheme.dark(
      primary: Colors.green,
      secondary: Colors.greenAccent,
      surface: Colors.green,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.white), // White text for dark background
      bodyMedium: TextStyle(color: Colors.white),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.greenAccent,
        foregroundColor: Colors.black, // Black text/icons on green accent buttons
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Colors.greenAccent,
      foregroundColor: Colors.black,
    ),
  );
}