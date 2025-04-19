import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'light_theme.dart';
import 'dark_theme.dart';
import 'night_owl_theme.dart';
import 'space_theme.dart';
import 'deep_ocean_theme.dart';
import 'solarized_dark_theme.dart';
import 'skyblue_theme.dart';
import 'solarized_light_theme.dart';
import 'red_theme.dart';
import 'green_theme.dart';
import 'green_dark_theme.dart';
import 'cyberpunk.dart';

enum AppTheme {
  light,
  dark,
  nightOwl,
  space,
  deepOcean,
  solarizedDark,
  skyBlue,
  solarizedLight,
  red,
  green,
  greenDark,
  Cyberpunk,
}

class ThemeProvider with ChangeNotifier {
  AppTheme _currentTheme = AppTheme.light;
  bool _isInitialized = false;
  static const String _prefsKey = 'selectedTheme';

  ThemeProvider() {
    _initializeTheme();
  }

  AppTheme get currentTheme => _currentTheme;
  ThemeMode get themeMode {
    switch (_currentTheme) {
      case AppTheme.light:
      case AppTheme.skyBlue:
      case AppTheme.solarizedLight:
        return ThemeMode.light;
      case AppTheme.dark:
      case AppTheme.nightOwl:
      case AppTheme.space:
      case AppTheme.deepOcean:
      case AppTheme.solarizedDark:
        return ThemeMode.dark;
      case AppTheme.red:
        return ThemeMode.light;
      case AppTheme.green:
        return ThemeMode.light;
      case AppTheme.greenDark:
        return ThemeMode.dark;
      case AppTheme.Cyberpunk:
        return ThemeMode.dark;
    }
  }
  bool get isInitialized => _isInitialized;

  Future<void> _initializeTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeString = prefs.getString(_prefsKey) ?? 'light';
    _currentTheme = AppTheme.values.firstWhere(
          (theme) => theme.toString().split('.').last == themeString,
      orElse: () => AppTheme.light,
    );
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> setTheme(AppTheme theme) async {
    _currentTheme = theme;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, theme.toString().split('.').last);
  }

  ThemeData get themeData {
    switch (_currentTheme) {
      case AppTheme.light:
        return buildLightTheme();
      case AppTheme.dark:
        return buildDarkTheme();
      case AppTheme.nightOwl:
        return buildNightOwlTheme();
      case AppTheme.space:
        return buildSpaceTheme();
      case AppTheme.deepOcean:
        return buildDeepOceanTheme();
      case AppTheme.solarizedDark:
        return buildSolarizedDarkTheme();
      case AppTheme.skyBlue:
        return buildSkyBlueTheme();
      case AppTheme.solarizedLight:
        return buildSolarizedLightTheme();
      case AppTheme.red:
        return buildRedTheme();
      case AppTheme.green:
        return buildGreenTheme();
      case AppTheme.greenDark:
        return buildGreenDarkTheme();
      case AppTheme.Cyberpunk:
        return buildCyberpunkTheme();
    }
  }
}