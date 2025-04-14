import 'package:flutter/material.dart';

ThemeData buildDarkTheme() {
  return ThemeData(
    colorScheme: ColorScheme.dark(
      primary: Colors.amber,
      secondary: Colors.amber[800]!,
      surface: Colors.black,
    ),
    cardColor: Colors.black26,
    useMaterial3: true,

  );
}