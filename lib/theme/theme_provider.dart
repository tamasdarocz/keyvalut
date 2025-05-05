import 'package:flutter/material.dart';
import 'package:keyvalut/theme/themes.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppTheme {
  light,
  dark,
  nightOwl,
  space,
  deepOcean,
  solarizedDark,
  skyBlue,
  solarizedLight,
  green,
  greenDark,
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
      case AppTheme.green:
        return ThemeMode.light;
      case AppTheme.dark:
      case AppTheme.nightOwl:
      case AppTheme.space:
      case AppTheme.deepOcean:
      case AppTheme.solarizedDark:
      case AppTheme.greenDark:
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
    // Map AppTheme to ThemeType since they have the same values
    final themeType = ThemeType.values.firstWhere(
          (type) => type.toString().split('.').last == _currentTheme.toString().split('.').last,
      orElse: () => ThemeType.light,
    );
    return ThemeBuilder.buildTheme(themeType: themeType);
  }
}