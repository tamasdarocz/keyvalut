import 'package:flutter/material.dart';

ThemeData buildSpaceTheme() {
  return ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF1a2b4f), // Deep cosmic blue
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF6b5b95),   // Purple for app bars, FAB
      secondary: Color(0xFF88bdbc), // Light teal accent
      surface: Color(0xFF2e4372),
    ),
    cardColor: const Color(0xFF2e4372), // Cards match surface
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Color(0xFFd8e2ff)),  // Light text for readability
      bodyMedium: TextStyle(color: Color(0xFFd8e2ff)),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF2e4372),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFF6b5b95), // Purple FAB
      foregroundColor: Colors.white,
    ),
    useMaterial3: true,
  );
}