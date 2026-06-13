import 'package:adhan_dart/adhan_dart.dart';
import 'package:first_project/shared/services/app_globals.dart';

class CalendarWaqtUtils {
  static const monthsEn = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
  static const monthsBn = ['জানুয়ারি', 'ফেব্রুয়ারি', 'মার্চ', 'এপ্রিল', 'মে', 'জুন', 'জুলাই', 'আগস্ট', 'সেপ্টেম্বর', 'অক্টোবর', 'নভেম্বর', 'ডিসেম্বর'];
  static const weekdaysEn = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  static const weekdaysBn = ['সোমবার', 'মঙ্গলবার', 'বুধবার', 'বৃহস্পতিবার', 'শুক্রবার', 'শনিবার', 'রবিবার'];
  static const hijriMonthsEn = {1: 'Muharram', 2: 'Safar', 3: 'Rabiul Awwal', 4: 'Rabius Sani', 5: 'Jamadial Awwal', 6: 'Jamadias Sani', 7: 'Rajab', 8: 'Shaban', 9: 'Ramadan', 10: 'Shawwal', 11: 'Zilkad', 12: 'Zilhajj'};
  static const hijriMonthsBn = {1: 'মুহাররম', 2: 'সফর', 3: 'রবিউল আউয়াল', 4: 'রবিউস সানি', 5: 'জমাদিউল আউয়াল', 6: 'জমাদিউস সানি', 7: 'রজব', 8: 'শাবান', 9: 'রমজান', 10: 'শাওয়াল', 11: 'জিলকদ', 12: 'জিলহজ্জ'};

  static String digits(String input, bool isBangla) {
    if (!isBangla) return input;
    const bangla = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
    var output = input;
    for (var i = 0; i < 10; i++) { output = output.replaceAll(i.toString(), bangla[i]); }
    return output;
  }

  static String monthName(int month, bool isBangla) => (isBangla ? monthsBn : monthsEn)[month - 1];
  static String weekdayName(int weekday, bool isBangla) => (isBangla ? weekdaysBn : weekdaysEn)[weekday - 1];
  static String hijriMonthName(int month, bool isBangla) => (isBangla ? hijriMonthsBn : hijriMonthsEn)[month] ?? '';

  static String clock(DateTime t, bool isBangla) {
    final h12 = t.hour % 12 == 0 ? 12 : t.hour % 12;
    return digits('${h12.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}', isBangla);
  }

  static PrayerTimes prayerTimes(DateTime date, double lat, double lng) {
    final params = CalculationMethodParameters.karachi()..madhab = Madhab.hanafi;
    return PrayerTimes(date: DateTime(date.year, date.month, date.day), coordinates: Coordinates(lat, lng), calculationParameters: params);
  }
}
