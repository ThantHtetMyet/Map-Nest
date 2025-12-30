import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider with ChangeNotifier {
  String _currentLanguage = 'en'; // 'en' for English, 'my' for Myanmar
  static const String _languageKey = 'app_language';

  LanguageProvider() {
    _loadLanguage();
  }

  String get currentLanguage => _currentLanguage;
  String get displayLanguage => _currentLanguage == 'my' ? 'Myanmar' : 'English';

  Future<void> _loadLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentLanguage = prefs.getString(_languageKey) ?? 'en';
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading language: $e');
    }
  }

  Future<void> toggleLanguage() async {
    _currentLanguage = _currentLanguage == 'en' ? 'my' : 'en';
    notifyListeners();
    await _saveLanguage();
  }

  Future<void> setLanguage(String language) async {
    if (language == 'en' || language == 'my') {
      _currentLanguage = language;
      notifyListeners();
      await _saveLanguage();
    }
  }

  Future<void> _saveLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, _currentLanguage);
    } catch (e) {
      debugPrint('Error saving language: $e');
    }
  }
}

