import 'package:flutter/material.dart';

ThemeData buildLightTheme() {
  return ThemeData(
    colorScheme: ColorScheme.light(
      primary: Colors.amber,
      secondary: Colors.amber[200]!,
      surface: Colors.white,
    ),

  );
}