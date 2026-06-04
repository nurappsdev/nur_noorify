import 'package:flutter/material.dart';

/// A single trackable daily deed (amol) — e.g. a fardh prayer or a dhikr.
/// [id] is the stable key persisted to storage; the English/Bangla titles are
/// resolved at render time based on the active language.
class AmolItem {
  const AmolItem({
    required this.id,
    required this.titleEn,
    required this.titleBn,
    required this.icon,
  });

  final String id;
  final String titleEn;
  final String titleBn;
  final IconData icon;
}

/// A named group of [AmolItem]s shown as a collapsible section on the tracker.
class AmolSection {
  const AmolSection({
    required this.id,
    required this.titleEn,
    required this.titleBn,
    required this.icon,
    required this.items,
  });

  final String id;
  final String titleEn;
  final String titleBn;
  final IconData icon;
  final List<AmolItem> items;
}

/// The fixed catalogue of deeds the tracker follows. The total count across all
/// sections (currently 14) drives the overall "today" progress badge.
const List<AmolSection> kAmolSections = [
  AmolSection(
    id: 'fardh',
    titleEn: 'Fardh Prayers',
    titleBn: 'ফরজ নামাজ সমুহ',
    icon: Icons.mosque_rounded,
    items: [
      AmolItem(
        id: 'fajr',
        titleEn: 'Fajr',
        titleBn: 'ফজর',
        icon: Icons.wb_twilight_rounded,
      ),
      AmolItem(
        id: 'zuhr',
        titleEn: 'Zuhr',
        titleBn: 'যুহর',
        icon: Icons.wb_sunny_rounded,
      ),
      AmolItem(
        id: 'asr',
        titleEn: 'Asr',
        titleBn: 'আসর',
        icon: Icons.brightness_5_rounded,
      ),
      AmolItem(
        id: 'maghrib',
        titleEn: 'Maghrib',
        titleBn: 'মাগরিব',
        icon: Icons.bedtime_rounded,
      ),
      AmolItem(
        id: 'isha',
        titleEn: 'Isha',
        titleBn: 'ইশা',
        icon: Icons.nights_stay_rounded,
      ),
    ],
  ),
  AmolSection(
    id: 'sunnah',
    titleEn: 'Sunnah & Nafl',
    titleBn: 'সুন্নত ও নফল',
    icon: Icons.star_rounded,
    items: [
      AmolItem(
        id: 'tahajjud',
        titleEn: 'Tahajjud',
        titleBn: 'তাহাজ্জুদ',
        icon: Icons.nightlight_round,
      ),
      AmolItem(
        id: 'ishraq',
        titleEn: 'Ishraq',
        titleBn: 'ইশরাক',
        icon: Icons.wb_sunny_outlined,
      ),
      AmolItem(
        id: 'chasht',
        titleEn: 'Chasht',
        titleBn: 'চাশত',
        icon: Icons.light_mode_outlined,
      ),
      AmolItem(
        id: 'witr',
        titleEn: 'Witr',
        titleBn: 'বিতর',
        icon: Icons.brightness_3_rounded,
      ),
    ],
  ),
  AmolSection(
    id: 'quran_dhikr',
    titleEn: 'Quran & Dhikr',
    titleBn: 'কুরআন ও যিকির',
    icon: Icons.menu_book_rounded,
    items: [
      AmolItem(
        id: 'quran',
        titleEn: 'Quran Tilawat',
        titleBn: 'কুরআন তিলাওয়াত',
        icon: Icons.auto_stories_rounded,
      ),
      AmolItem(
        id: 'morning_adhkar',
        titleEn: 'Morning Adhkar',
        titleBn: 'সকালের যিকির',
        icon: Icons.wb_twilight_outlined,
      ),
      AmolItem(
        id: 'evening_adhkar',
        titleEn: 'Evening Adhkar',
        titleBn: 'সন্ধ্যার যিকির',
        icon: Icons.nights_stay_outlined,
      ),
    ],
  ),
  AmolSection(
    id: 'charity',
    titleEn: 'Charity & More',
    titleBn: 'দান ও অন্যান্য',
    icon: Icons.volunteer_activism_rounded,
    items: [
      AmolItem(
        id: 'sadaqah',
        titleEn: 'Sadaqah',
        titleBn: 'সদকা',
        icon: Icons.favorite_rounded,
      ),
      AmolItem(
        id: 'durood',
        titleEn: 'Durood',
        titleBn: 'দরুদ',
        icon: Icons.spa_rounded,
      ),
    ],
  ),
];

/// Total number of trackable deeds across every section.
int get kAmolTotalCount =>
    kAmolSections.fold(0, (sum, section) => sum + section.items.length);
