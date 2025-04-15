import 'package:flutter/material.dart';

ThemeData buildDeepOceanTheme() {
  return ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF0d1b2a), // Deep navy black
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF468faf),   // Teal for app bars, FAB
      secondary: Color(0xFF778da9), // Grayish-blue accent
      surface: Color(0xFF1b263b),
    ),
    cardColor: const Color(0xFF1b263b), // Cards match surface
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Color(0xFFe0e1dd)),  // Light gray text
      bodyMedium: TextStyle(color: Color(0xFFe0e1dd)),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1b263b),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFF468faf), // Teal FAB
      foregroundColor: Colors.white,
    ),
    useMaterial3: true,
  );
}