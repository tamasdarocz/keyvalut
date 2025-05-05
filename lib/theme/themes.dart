import 'package:flutter/material.dart';

enum ThemeType {
  solarizedLight,
  green,
  nightOwl,
  greenDark,
  skyBlue,
  light,
  solarizedDark,
  deepOcean,
  space,
  dark,
}

class ThemeBuilder {
  static ThemeData buildTheme({required ThemeType themeType}) {
    const baseTextStyle = TextStyle(fontSize: 16);
    const baseColorSchemeLight = ColorScheme.light(
      surface: Colors.white,
      onSurface: Colors.black87,
    );
    const baseColorSchemeDark = ColorScheme.dark(
      surface: Color(0xFF1E1E1E),
      onSurface: Colors.white70,
    );

    // Base theme configuration
    Map<ThemeType, Map<String, dynamic>> themeConfigs = {
      ThemeType.solarizedLight: {
        'brightness': Brightness.light,
        'scaffoldBackgroundColor': const Color(0xFFfdf6e3),
        'primary': const Color(0xFFb58900),
        'secondary': const Color(0xFF2aa198),
        'surface': const Color(0xFFeee8d5),
        'textColor': const Color(0xFF657b83),
      },
      ThemeType.green: {
        'brightness': Brightness.light,
        'scaffoldBackgroundColor': Colors.green[50]!,
        'primary': Colors.green,
        'secondary': Colors.greenAccent,
        'surface': Colors.green[50]!,
        'textColor': Colors.black,
      },
      ThemeType.nightOwl: {
        'brightness': Brightness.dark,
        'scaffoldBackgroundColor': const Color(0xFF011627),
        'primary': const Color(0xFFc792ea),
        'secondary': const Color(0xFF7fdbca),
        'surface': const Color(0xFF1d3b53),
        'textColor': const Color(0xFFd6deeb),
      },
      ThemeType.greenDark: {
        'brightness': Brightness.dark,
        'scaffoldBackgroundColor': Colors.green[900]!,
        'primary': Colors.green,
        'secondary': Colors.greenAccent,
        'surface': Colors.green[900]!,
        'textColor': Colors.white,
      },
      ThemeType.skyBlue: {
        'brightness': Brightness.light,
        'scaffoldBackgroundColor': const Color(0xFFe6f0fa),
        'primary': const Color(0xFF4fc1e9),
        'secondary': const Color(0xFFa0d468),
        'surface': const Color(0xFFf5faff),
        'textColor': const Color(0xFF2e4057),
      },
      ThemeType.light: {
        'brightness': Brightness.light,
        'scaffoldBackgroundColor': Colors.white,
        'primary': Colors.amber,
        'secondary': Colors.amber[200]!,
        'surface': Colors.white,
        'textColor': Colors.black87,
      },
      ThemeType.solarizedDark: {
        'brightness': Brightness.dark,
        'scaffoldBackgroundColor': const Color(0xFF002b36),
        'primary': const Color(0xFFb58900),
        'secondary': const Color(0xFF2aa198),
        'surface': const Color(0xFF073642),
        'textColor': const Color(0xFF839496),
      },
      ThemeType.deepOcean: {
        'brightness': Brightness.dark,
        'scaffoldBackgroundColor': const Color(0xFF0d1b2a),
        'primary': const Color(0xFF468faf),
        'secondary': const Color(0xFF778da9),
        'surface': const Color(0xFF1b263b),
        'textColor': const Color(0xFFe0e1dd),
      },
      ThemeType.space: {
        'brightness': Brightness.dark,
        'scaffoldBackgroundColor': const Color(0xFF1a2b4f),
        'primary': const Color(0xFF6b5b95),
        'secondary': const Color(0xFF88bdbc),
        'surface': const Color(0xFF2e4372),
        'textColor': const Color(0xFFd8e2ff),
      },
      ThemeType.dark: {
        'brightness': Brightness.dark,
        'scaffoldBackgroundColor': Colors.black,
        'primary': Colors.amber,
        'secondary': Colors.amber[800]!,
        'surface': Colors.black26,
        'textColor': Colors.white,
      },
    };

    final config = themeConfigs[themeType]!;
    final brightness = config['brightness'] as Brightness;
    final scaffoldBackgroundColor = config['scaffoldBackgroundColor'] as Color;
    final primary = config['primary'] as Color;
    final secondary = config['secondary'] as Color;
    final surface = config['surface'] as Color;
    final textColor = config['textColor'] as Color;

    final colorScheme = (brightness == Brightness.light
        ? baseColorSchemeLight
        : baseColorSchemeDark).copyWith(
      primary: primary,
      secondary: secondary,
      surface: surface,
      onSurface: textColor,
    );

    return ThemeData(
      brightness: brightness,
      scaffoldBackgroundColor: scaffoldBackgroundColor,
      colorScheme: colorScheme,
      cardColor: surface,
      textTheme: TextTheme(
        bodyLarge: baseTextStyle.copyWith(color: textColor, fontSize: 18),
        bodyMedium: baseTextStyle.copyWith(color: textColor, fontSize: 16),
        titleLarge: baseTextStyle.copyWith(color: textColor, fontSize: 24, fontWeight: FontWeight.bold),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: brightness == Brightness.light ? primary : surface,
        foregroundColor: brightness == Brightness.light ? Colors.black87 : textColor,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: secondary,
          foregroundColor: brightness == Brightness.light ? Colors.black : Colors.white,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: brightness == Brightness.light ? Colors.black87 : Colors.white,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        selectedItemColor: secondary,
        unselectedItemColor: textColor.withOpacity(0.6),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderSide: BorderSide(color: primary),
        ),
        labelStyle: TextStyle(color: textColor),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: secondary, width: 2),
        ),
      ),
      useMaterial3: true,
    );
  }
}