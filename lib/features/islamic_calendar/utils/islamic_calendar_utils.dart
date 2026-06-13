import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:ponjika/ponjika.dart';
import 'package:first_project/shared/services/app_globals.dart';

class IslamicCalendarUtils {
  static const dhakaLat = 23.8103;
  static const dhakaLng = 90.4125;

  static const monthsEn = <String>[
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  static const monthsBn = <String>[
    'জানুয়ারি', 'ফেব্রুয়ারি', 'মার্চ', 'এপ্রিল', 'মে', 'জুন',
    'জুলাই', 'আগস্ট', 'সেপ্টেম্বর', 'অক্টোবর', 'নভেম্বর', 'ডিসেম্বর',
  ];

  static const weekdaysEn = <String>['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  static const weekdaysBn = <String>['শনি', 'রবি', 'সোম', 'মঙ্গল', 'বুধ', 'বৃহঃ', 'শুক্র'];

  static bool get isBangla => appLanguageNotifier.value == AppLanguage.bangla;

  static bool looksMojibake(String value) {
    for (final unit in value.codeUnits) {
      if (unit == 0x00C3 || unit == 0x00C2 || unit == 0x00E0 ||
          unit == 0x00D8 || unit == 0x00D9 || unit == 0x00D0 || unit == 0x00E2) {
        return true;
      }
    }
    return false;
  }

  static String repairMojibake(String value) {
    var output = value;
    for (var i = 0; i < 4; i++) {
      if (!looksMojibake(output)) break;
      try {
        output = utf8.decode(latin1.encode(output));
      } catch (_) {
        break;
      }
    }
    return output;
  }

  static bool containsBangla(String value) {
    return RegExp(r'[\u0980-\u09FF]').hasMatch(value);
  }

  static String bn(String value, {required String fallback}) {
    final repaired = repairMojibake(value);
    if (containsBangla(repaired) && !looksMojibake(repaired)) {
      return repaired;
    }
    return fallback;
  }

  static String text(String en, String bnStr) => isBangla ? bn(bnStr, fallback: en) : en;

  static String toBanglaDigits(String input) {
    const latin = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const bangla = ['\u09e6', '\u09e7', '\u09e8', '\u09e9', '\u09ea', '\u09eb', '\u09ec', '\u09ed', '\u09ee', '\u09ef'];
    var output = input;
    for (var i = 0; i < latin.length; i++) {
      output = output.replaceAll(latin[i], bangla[i]);
    }
    return output;
  }

  static String digits(String input) => isBangla ? toBanglaDigits(input) : input;

  static String gregorianMonth(int month) =>
      isBangla ? bn(monthsBn[month - 1], fallback: monthsEn[month - 1]) : monthsEn[month - 1];

  static String weekday(int index) =>
      isBangla ? bn(weekdaysBn[index], fallback: weekdaysEn[index]) : weekdaysEn[index];

  static String hijriMonth(String english) {
    if (!isBangla) return english;
    const map = <String, String>{
      'Muharram': 'মুহাররম',
      'Safar': 'সফর',
      "Rabi' al-awwal": 'রবিউল আউয়াল',
      "Rabi' al-thani": 'রবিউস সানি',
      'Jumada al-awwal': 'জুমাদিউল আউয়াল',
      'Jumada al-thani': 'জুমাদিউস সানি',
      'Rajab': 'রজব',
      "Sha'ban": 'শাবান',
      'Ramadan': 'রমজান',
      'Shawwal': 'শাওয়াল',
      "Dhu al-Qi'dah": 'জিলকদ',
      'Dhu al-Hijjah': 'জিলহজ',
    };
    final banglaStr = map[english];
    if (banglaStr == null) return english;
    return bn(banglaStr, fallback: english);
  }

  static String formatGregorian(DateTime date) {
    final raw = '${date.day} ${gregorianMonth(date.month)} ${date.year}';
    return digits(raw);
  }

  static String formatBanglaDate(DateTime date) {
    final raw = Ponjika.format(date: date, format: 'DD MM YY');
    return digits(raw);
  }

  static String formatHijri(DateTime date) {
    final h = HijriCalendar.fromDate(date);
    final raw = '${h.hDay} ${hijriMonth(h.longMonthName)} ${h.hYear}';
    return isBangla ? '${digits(raw)} হিজরি' : '${digits(raw)} AH';
  }

  static List<DateTime> visibleDays(DateTime displayedMonth) {
    final first = DateTime(displayedMonth.year, displayedMonth.month, 1);
    final total = DateUtils.getDaysInMonth(displayedMonth.year, displayedMonth.month);
    final leading = first.weekday % 7;
    final start = first.subtract(Duration(days: leading));
    final length = leading + total + (((leading + total) % 7 == 0) ? 0 : (7 - (leading + total) % 7));
    return List.generate(length, (index) => start.add(Duration(days: index)));
  }

  static List<String> getEventsForDate(DateTime date, DateTime displayedMonth, Map<int, List<String>> googleEvents, Map<int, List<String>> apiEvents) {
    if (date.year == displayedMonth.year && date.month == displayedMonth.month) {
      final google = googleEvents[date.day] ?? [];
      final api = apiEvents[date.day] ?? [];
      if (google.isNotEmpty || api.isNotEmpty) return <String>{...google, ...api}.toList();
    }
    final h = HijriCalendar.fromDate(date);
    final map = {
      '1-1': ['Islamic New Year'], '1-10': ['Ashura'], '7-27': ['Isra and Miraj'],
      '8-15': ['Mid-Shaban'], '9-1': ['Start of Ramadan'], '9-27': ['Laylat al-Qadr'],
      '10-1': ['Eid al-Fitr'], '12-9': ['Day of Arafah'], '12-10': ['Eid al-Adha']
    };
    return (map['${h.hMonth}-${h.hDay}'] ?? []).map((e) => text(e, e)).toList();
  }
}
