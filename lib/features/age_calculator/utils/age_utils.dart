import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:first_project/features/age_calculator/providers/boyos_zacai_provider.dart';

class AgeUtils {
  static const monthsEn = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
  static const monthsBn = ['জানুয়ারি', 'ফেব্রুয়ারি', 'মার্চ', 'এপ্রিল', 'মে', 'জুন', 'জুলাই', 'আগস্ট', 'সেপ্টেম্বর', 'অক্টোবর', 'নভেম্বর', 'ডিসেম্বর'];
  static const hijriMonthsEn = ['Muharram', 'Safar', 'Rabi al-Awwal', 'Rabi al-Thani', 'Jumada al-Awwal', 'Jumada al-Thani', 'Rajab', "Sha'ban", 'Ramadan', 'Shawwal', "Dhu al-Qi'dah", "Dhu al-Hijjah"];
  static const hijriMonthsBn = ['মহররম', 'সফর', 'রবিউল আউয়াল', 'রবিউস সানি', 'জমাদিউল আউয়াল', 'জমাদিউস সানি', 'রজব', 'শাবান', 'রমজান', 'শাওয়াল', 'জিলকদ', 'জিলহজ'];
  static const banglaMonthsEn = ['Boishakh', 'Joishtho', 'Asharh', 'Srabon', 'Bhadro', 'Ashwin', 'Kartik', 'Ogrohayon', 'Poush', 'Magh', 'Falgun', 'Choitro'];
  static const banglaMonthsBn = ['বৈশাখ', 'জ্যৈষ্ঠ', 'আষাঢ়', 'শ্রাবণ', 'ভাদ্র', 'আশ্বিন', 'কার্তিক', 'অগ্রহায়ণ', 'পৌষ', 'মাঘ', 'ফালগুন', 'চৈত্র'];

  static String digits(String input, bool isBangla) {
    if (!isBangla) return input;
    const bangla = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
    var output = input;
    for (var i = 0; i < 10; i++) {
      output = output.replaceAll(i.toString(), bangla[i]);
    }
    return output;
  }

  static String gregorianMonthName(int month, bool isBangla) => (isBangla ? monthsBn : monthsEn)[month - 1];
  static String hijriMonthName(int month, bool isBangla) => (isBangla ? hijriMonthsBn : hijriMonthsEn)[month - 1];
  static String banglaMonthName(int month, bool isBangla) => (isBangla ? banglaMonthsBn : banglaMonthsEn)[month - 1];

  static List<int> banglaMonthDays(int startGregYear) {
    final days = [31, 31, 31, 31, 31, 30, 30, 30, 30, 30, 30, 30];
    final span = DateTime(startGregYear + 1, 4, 14).difference(DateTime(startGregYear, 4, 14)).inDays;
    if (span == 366) days[10] = 31;
    return days;
  }

  static ({int year, int month, int day}) toBangla(DateTime date) {
    final g = DateTime(date.year, date.month, date.day);
    final startGregYear = (g.month < 4 || (g.month == 4 && g.day < 14)) ? g.year - 1 : g.year;
    final mDays = banglaMonthDays(startGregYear);
    var offset = g.difference(DateTime(startGregYear, 4, 14)).inDays;
    var mIdx = 0;
    while (mIdx < 11 && offset >= mDays[mIdx]) { offset -= mDays[mIdx]; mIdx++; }
    return (year: startGregYear - 593, month: mIdx + 1, day: offset + 1);
  }

  static DateTime fromBangla(int year, int month, int day) {
    final startGregYear = year + 593;
    final mDays = banglaMonthDays(startGregYear);
    var offset = day - 1;
    for (var i = 0; i < month - 1; i++) { offset += mDays[i]; }
    return DateTime(startGregYear, 4, 14).add(Duration(days: offset));
  }

  static String formatDate(DateTime date, CalendarType calendar, bool isBangla) {
    final t = (String en, String bn) => isBangla ? bn : en;
    if (calendar == CalendarType.hijri) {
      final h = HijriCalendar.fromDate(date);
      return '${digits(h.hDay.toString(), isBangla)} ${hijriMonthName(h.hMonth, isBangla)} ${digits(h.hYear.toString(), isBangla)} ${t('AH', 'হিজরি')}';
    }
    if (calendar == CalendarType.bengali) {
      final b = toBangla(date);
      return '${digits(b.day.toString(), isBangla)} ${banglaMonthName(b.month, isBangla)} ${digits(b.year.toString(), isBangla)} ${t('BS', 'বঙ্গাব্দ')}';
    }
    return '${digits(date.day.toString(), isBangla)} ${gregorianMonthName(date.month, isBangla)} ${digits(date.year.toString(), isBangla)}';
  }

  static ({int years, int months, int days, int totalMinutes})? calculateAge(DateTime? birth, DateTime present) {
    if (birth == null || !present.isAfter(birth)) return null;
    var y = present.year - birth.year;
    var m = present.month - birth.month;
    var d = present.day - birth.day;
    if (d < 0) { m -= 1; d += DateTime(present.year, present.month, 0).day; }
    if (m < 0) { y -= 1; m += 12; }
    return (years: y, months: m, days: d, totalMinutes: present.difference(birth).inMinutes);
  }
}
