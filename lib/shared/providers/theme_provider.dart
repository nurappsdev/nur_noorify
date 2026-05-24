import 'package:flutter/material.dart';

import 'package:first_project/shared/services/app_globals.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeProvider() {
    _isDarkMode = darkThemeEnabledNotifier.value;
    _fontSize = appFontSizeNotifier.value;
  }

  bool _isDarkMode = false;
  AppFontSize _fontSize = AppFontSize.medium;

  bool get isDarkMode => _isDarkMode;
  AppFontSize get fontSize => _fontSize;
  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  void toggleDarkMode() {
    setDarkMode(!_isDarkMode);
  }

  void setDarkMode(bool value) {
    if (_isDarkMode == value) return;
    _isDarkMode = value;
    darkThemeEnabledNotifier.value = value;
    notifyListeners();
  }

  void setFontSize(AppFontSize size) {
    if (_fontSize == size) return;
    _fontSize = size;
    appFontSizeNotifier.value = size;
    notifyListeners();
  }
}
