import 'package:flutter/material.dart';

ThemeData buildSkyBlueTheme() {
  return ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFe6f0fa), // Light grayish-blue
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF4fc1e9),   // Sky blue for app bars, FAB
      secondary: Color(0xFFa0d468), // Soft teal accent
      surface: Color(0xFFf5faff),   // Near-white panels
      background: Color(0xFFe6f0fa),
    ),
    cardColor: const Color(0xFFf5faff), // Cards match surface
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Color(0xFF2e4057)),  // Dark gray text
      bodyMedium: TextStyle(color: Color(0xFF2e4057)),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF4fc1e9),
      foregroundColor: Colors.white, // White text/icons for contrast
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFF4fc1e9), // Sky blue FAB
      foregroundColor: Colors.white,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      selectedItemColor: Color(0xFFa0d468), // Teal for selected items
      unselectedItemColor: Color(0xFF2e4057),
    ),
    useMaterial3: true,
  );
}