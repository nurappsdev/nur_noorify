import 'package:flutter/foundation.dart';

import 'package:first_project/shared/services/app_globals.dart';

class LanguageProvider extends ChangeNotifier {
  LanguageProvider() {
    _current = appLanguageNotifier.value;
    appLanguageNotifier.addListener(_syncFromGlobal);
  }

  late AppLanguage _current;

  AppLanguage get current => _current;
  bool get isBangla => _current == AppLanguage.bangla;

  String t(String english, String bangla) => isBangla ? bangla : english;

  Future<void> setLanguage(AppLanguage language) async {
    if (_current == language) return;
    appLanguageNotifier.value = language;
    await saveAppPreferences();
  }

  void _syncFromGlobal() {
    final value = appLanguageNotifier.value;
    if (value == _current) return;
    _current = value;
    notifyListeners();
  }

  @override
  void dispose() {
    appLanguageNotifier.removeListener(_syncFromGlobal);
    super.dispose();
  }
}
