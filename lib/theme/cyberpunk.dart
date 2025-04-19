import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';


ThemeData buildCyberpunkTheme() {
  const Color neonCyan = Color(0xFF00FFFF);
  const Color neonPink = Color(0xFFFF00FF);
  const Color neonPurple = Color(0xFFAA00FF);
  const Color darkBackground = Color(0xFF121212); // Near-black background
  const Color secondaryDark = Color(0xFF1E1E1E); // Slightly lighter for cards

  return ThemeData(
    // Primary color scheme
    primarySwatch: Colors.blueGrey,
    primaryColor: neonCyan,
    scaffoldBackgroundColor: darkBackground,

    // AppBar theme
    appBarTheme: const AppBarTheme(
      backgroundColor: secondaryDark,
      foregroundColor: neonCyan,
      elevation: 4,
      shadowColor: neonCyan,
    ),

    // Text theme with futuristic font
    textTheme: TextTheme(
      bodyMedium: GoogleFonts.orbitron(
        color: Colors.white70,
        fontSize: 16,
      ),
      titleLarge: GoogleFonts.orbitron(
        color: neonCyan,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      headlineSmall: GoogleFonts.orbitron(
        color: neonPink,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    ),

    // Card theme for Cyberpunk cards
    cardTheme: CardTheme(
      color: secondaryDark,
      elevation: 8,
      shadowColor: neonCyan.withOpacity(0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: neonCyan, width: 1),
      ),
    ),

    // Button theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: neonPurple,
        foregroundColor: Colors.white,
        textStyle: GoogleFonts.orbitron(fontSize: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        shadowColor: neonPurple.withOpacity(0.5),
        elevation: 4,
      ),
    ),

    // Icon theme
    iconTheme: const IconThemeData(
      color: neonPink,
    ),

    // Floating action button theme
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: neonPurple,
      foregroundColor: Colors.white,
      elevation: 4,
      focusElevation: 8,
    ),

    // Divider theme for lists
    dividerTheme: const DividerThemeData(
      color: neonCyan,
      thickness: 1,
    ),
  );
}
