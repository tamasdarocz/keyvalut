import 'package:flutter/material.dart';

ThemeData buildSolarizedLightTheme() {
  return ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFfdf6e3), // Solarized base3
    colorScheme: const ColorScheme.light(
      primary: Color(0xFFb58900),   // Yellow for app bars, FAB
      secondary: Color(0xFF2aa198), // Cyan accent
      surface: Color(0xFFeee8d5),
    ),
    cardColor: const Color(0xFFeee8d5), // Cards match surface
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Color(0xFF657b83)),  // Base00 text
      bodyMedium: TextStyle(color: Color(0xFF657b83)),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFb58900),
      foregroundColor: Colors.black87, // Dark text/icons for contrast
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFFb58900), // Yellow FAB
      foregroundColor: Colors.black87,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      selectedItemColor: Color(0xFF2aa198), // Cyan for selected items
      unselectedItemColor: Color(0xFF657b83),
    ),
    useMaterial3: true,
  );
}