import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider with ChangeNotifier {
  static const _key = 'settings_language';

  Locale _locale = const Locale('en');
  Locale get locale => _locale;
  bool get isArabic => _locale.languageCode == 'ar';

  LocaleProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final lang = prefs.getString(_key) ?? 'English';
    _locale = lang == 'Arabic' ? const Locale('ar') : const Locale('en');
    notifyListeners();
  }

  Future<void> setLanguage(String langName) async {
    _locale = langName == 'Arabic' ? const Locale('ar') : const Locale('en');
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, langName);
  }
}
