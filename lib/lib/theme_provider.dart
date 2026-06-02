import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  static const _darkModeKey = 'settings_dark_mode';
  bool _isDarkMode = false;
  bool _loaded = false;

  bool get isDarkMode => _isDarkMode;
  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  ThemeProvider() {
    loadTheme();
  }

  Future<void> loadTheme() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_darkModeKey) ?? false;
    _loaded = true;
    notifyListeners();
  }

  Future<void> toggleTheme(bool isOn) async {
    _isDarkMode = isOn;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkModeKey, isOn);
  }
}
