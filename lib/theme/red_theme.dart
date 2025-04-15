import 'package:flutter/material.dart';


 ThemeData buildRedTheme() {
   return ThemeData(
     brightness: Brightness.light,
     primaryColor: Colors.red,
     scaffoldBackgroundColor: Colors.red[50]!,
     colorScheme: const ColorScheme.light(
       primary: Colors.red,
       secondary: Colors.redAccent,
       surface: Colors.red,
     ),
     textTheme: const TextTheme(
       bodyLarge: TextStyle(color: Colors.black),
       bodyMedium: TextStyle(color: Colors.black),
     ),
     elevatedButtonTheme: ElevatedButtonThemeData(
       style: ElevatedButton.styleFrom(
         backgroundColor: Colors.redAccent,
         foregroundColor: Colors.white,
       ),
     ),
     floatingActionButtonTheme: const FloatingActionButtonThemeData(
       backgroundColor: Colors.redAccent,
       foregroundColor: Colors.white,
     ),
   );
 }