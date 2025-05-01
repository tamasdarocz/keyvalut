import 'package:flutter/material.dart';

ThemeData buildSolarizedDarkTheme() {
  return ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF002b36), // Solarized base03
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFFb58900),   // Yellow for app bars, FAB
      secondary: Color(0xFF2aa198), // Cyan accent
      surface: Color(0xFF073642),
    ),
    cardColor: const Color(0xFF073642), // Cards match surface
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Color(0xFF839496)),  // Base0 text
      bodyMedium: TextStyle(color: Color(0xFF839496)),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF073642),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFFb58900), // Yellow FAB
      foregroundColor: Colors.black87,
    ),
    useMaterial3: true,
  );
}