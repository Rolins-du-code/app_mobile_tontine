// fichier pour le changement de theme

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.light;

  ThemeMode get mode => _mode;
  bool get estSombre => _mode == ThemeMode.dark;

  ThemeProvider() {
    _charger();
  }

  Future<void> _charger() async {
    final prefs = await SharedPreferences.getInstance();
    final sombre = prefs.getBool('theme_sombre') ?? false;
    _mode = sombre ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  Future<void> basculer() async {
    _mode = _mode == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(
        'theme_sombre', _mode == ThemeMode.dark);
    notifyListeners();
  }
}