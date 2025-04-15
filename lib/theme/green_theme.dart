import 'package:flutter/material.dart';

ThemeData buildGreenTheme() {
  return ThemeData(
    brightness: Brightness.light,
    primaryColor: Colors.green,
    scaffoldBackgroundColor: Colors.green[50]!,
    colorScheme: const ColorScheme.light(
      primary: Colors.green,
      secondary: Colors.greenAccent,
      surface: Colors.green,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.black),
      bodyMedium: TextStyle(color: Colors.black),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.greenAccent,
        foregroundColor: Colors.white,
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Colors.greenAccent,
      foregroundColor: Colors.white,
    ),
  );
}
