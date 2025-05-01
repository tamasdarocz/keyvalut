import 'package:flutter/material.dart';

ThemeData buildNightOwlTheme() {
  return ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF011627),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFFc792ea),   // Purple accent
      secondary: Color(0xFF7fdbca), // Teal accent
      surface: Color(0xFF1d3b53),
    ),
    cardColor: const Color(0xFF1d3b53),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Color(0xFFd6deeb)),
      bodyMedium: TextStyle(color: Color(0xFFd6deeb)),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1d3b53),
    ),
    useMaterial3: true,
  );
}