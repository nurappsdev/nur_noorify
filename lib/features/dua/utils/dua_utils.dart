import 'package:flutter/material.dart';
import 'package:first_project/features/dua/models/dua_meta.dart';

class DuaConstants {
  static const List<String> mainCategoryOrder = [
    'namaj', 'morning_evening', 'daily_life', 'saom', 'quranic', 'general',
  ];

  static const List<MainCategoryMeta> mainCategoryMetas = [
    MainCategoryMeta(
      key: 'namaj',
      titleEn: 'Prayer Dua',
      titleBn: 'নামাজের পরের আমল',
      subtitleEn: 'Post-prayer daily adhkar',
      subtitleBn: 'ফজর, যোহর, আসর, মাগরিব, এশা',
      icon: Icons.mosque_outlined,
    ),
    MainCategoryMeta(
      key: 'morning_evening',
      titleEn: 'Morning & Evening',
      titleBn: 'সকাল-সন্ধ্যার যিকির',
      subtitleEn: 'Daily protection adhkar',
      subtitleBn: 'দৈনিক যিকির ও দুআ',
      icon: Icons.wb_sunny_outlined,
    ),
    MainCategoryMeta(
      key: 'daily_life',
      titleEn: 'Daily Life',
      titleBn: 'দৈনন্দিন দুআ',
      subtitleEn: 'Travel, food, home, family',
      subtitleBn: 'খাওয়া, ভ্রমণ, পরিবার, ঘর',
      icon: Icons.home_outlined,
    ),
    MainCategoryMeta(
      key: 'saom',
      titleEn: 'Fasting',
      titleBn: 'সিয়াম',
      subtitleEn: 'Sehri, iftar and fasting duas',
      subtitleBn: 'সেহরি, ইফতার ও রোজার দুআ',
      icon: Icons.nights_stay_outlined,
    ),
    MainCategoryMeta(
      key: 'quranic',
      titleEn: 'Quranic Dua',
      titleBn: 'কুরআনিক দুআ',
      subtitleEn: 'Duas from Quran',
      subtitleBn: 'কুরআন থেকে নেওয়া দুআ',
      icon: Icons.menu_book_outlined,
    ),
    MainCategoryMeta(
      key: 'general',
      titleEn: 'General',
      titleBn: 'সাধারণ',
      subtitleEn: 'Other useful duas',
      subtitleBn: 'অন্যান্য দুআ',
      icon: Icons.grid_view_rounded,
    ),
  ];

  static const List<SubCategoryMeta> subCategoryMetas = [
    SubCategoryMeta(key: 'after_fajr', mainKey: 'namaj', titleEn: 'After Fajr Prayer', titleBn: 'ফজরের নামাজের পরে', icon: Icons.wb_sunny_outlined),
    SubCategoryMeta(key: 'after_zuhr', mainKey: 'namaj', titleEn: 'After Zuhr Prayer', titleBn: 'যোহরের নামাজের পরে', icon: Icons.light_mode_outlined),
    SubCategoryMeta(key: 'after_asr', mainKey: 'namaj', titleEn: 'After Asr Prayer', titleBn: 'আসরের নামাজের পরে', icon: Icons.schedule_rounded),
    SubCategoryMeta(key: 'after_maghrib', mainKey: 'namaj', titleEn: 'After Maghrib Prayer', titleBn: 'মাগরিবের নামাজের পরে', icon: Icons.bedtime_outlined),
    SubCategoryMeta(key: 'after_isha', mainKey: 'namaj', titleEn: 'After Isha Prayer', titleBn: 'এশার নামাজের পরে', icon: Icons.dark_mode_outlined),
    SubCategoryMeta(key: 'morning_adhkar', mainKey: 'morning_evening', titleEn: 'Morning Adhkar', titleBn: 'সকালের যিকির', icon: Icons.wb_sunny_rounded),
    SubCategoryMeta(key: 'evening_adhkar', mainKey: 'morning_evening', titleEn: 'Evening Adhkar', titleBn: 'সন্ধ্যার যিকির', icon: Icons.nightlight_round),
    SubCategoryMeta(key: 'home_dua', mainKey: 'daily_life', titleEn: 'Home Dua', titleBn: 'ঘরের দুআ', icon: Icons.home_rounded),
    SubCategoryMeta(key: 'food_dua', mainKey: 'daily_life', titleEn: 'Food Dua', titleBn: 'খাওয়ার দুআ', icon: Icons.restaurant_menu_rounded),
    SubCategoryMeta(key: 'fasting_dua', mainKey: 'saom', titleEn: 'Fasting Dua', titleBn: 'সিয়ামের দুআ', icon: Icons.emoji_food_beverage_rounded),
    SubCategoryMeta(key: 'quranic_dua', mainKey: 'quranic', titleEn: 'Quranic Dua', titleBn: 'কুরআনিক দুআ', icon: Icons.menu_book_rounded),
  ];

  static const String indoPakArabicFont = 'Lateef';
}

class DuaUtils {
  static String sanitizeTitle(String value) {
    return value.replaceAll(' ? ', ' - ').replaceAll(' ?', '').replaceAll('? ', '').replaceAll('?', '').replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}
