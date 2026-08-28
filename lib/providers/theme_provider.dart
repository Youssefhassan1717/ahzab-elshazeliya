import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _key = 'theme_mode';
  ThemeMode _themeMode = ThemeMode.light;
  bool _userToggled = false;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  ThemeProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    // A toggle may have landed before the stored value arrived — don't undo it.
    if (_userToggled) return;
    final index = prefs.getInt(_key) ?? 0;
    _themeMode = ThemeMode.values[index];
    notifyListeners();
  }

  void toggleTheme() {
    _userToggled = true;
    _themeMode = isDarkMode ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
    _persist();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, _themeMode.index);
  }
}
