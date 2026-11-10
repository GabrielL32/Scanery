import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_theme.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _keyThemeMode = 'theme_mode';
  static const String _keyDynamicColor = 'use_dynamic_color';
  static const String _keySeedColor = 'seed_color';

  ThemeMode _themeMode = ThemeMode.system;
  bool _useDynamicColor = true;
  Color _seedColor = AppTheme.defaultPrimaryColor;

  ThemeMode get themeMode => _themeMode;
  bool get useDynamicColor => _useDynamicColor;
  Color get seedColor => _seedColor;

  ThemeProvider() {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    final themeModeIndex = prefs.getInt(_keyThemeMode);
    if (themeModeIndex != null &&
        themeModeIndex >= 0 &&
        themeModeIndex < ThemeMode.values.length) {
      _themeMode = ThemeMode.values[themeModeIndex];
    }

    _useDynamicColor = prefs.getBool(_keyDynamicColor) ?? true;

    final colorValue = prefs.getInt(_keySeedColor);
    if (colorValue != null) {
      _seedColor = Color(colorValue);
    }

    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyThemeMode, mode.index);
  }

  Future<void> setUseDynamicColor(bool value) async {
    _useDynamicColor = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDynamicColor, value);
  }

  Future<void> setSeedColor(Color color) async {
    _seedColor = color;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keySeedColor, color.toARGB32());
  }
}
