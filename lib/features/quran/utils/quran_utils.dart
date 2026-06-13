import 'package:first_project/shared/services/app_globals.dart';

class QuranUtils {
  static bool get isBangla => appLanguageNotifier.value == AppLanguage.bangla;

  static String t(String en, String bn) => isBangla ? bn : en;

  static String toBanglaDigits(String input) {
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const bangla = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
    var output = input;
    for (var i = 0; i < english.length; i++) {
      output = output.replaceAll(english[i], bangla[i]);
    }
    return output;
  }

  static String digits(String input) => isBangla ? toBanglaDigits(input) : input;

  static String revelationLabel(String place) {
    final lower = place.toLowerCase();
    if (lower.contains('mecca')) return t('Makkah', 'মক্কা');
    if (lower.contains('medina')) return t('Madinah', 'মদিনা');
    return place;
  }
}
