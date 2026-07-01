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
    required this.weight,
  });

  final String id;
  final String titleEn;
  final String titleBn;
  final IconData icon;

  /// Points this deed contributes to the day's total score when completed.
  /// All weights across every section sum to [kAmolMaxScore] (30).
  final int weight;
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

  /// The maximum score achievable in this section (sum of its item weights).
  int get maxScore => items.fold(0, (sum, item) => sum + item.weight);
}

/// The fixed catalogue of deeds the tracker follows. The total count across all
/// sections (currently 20) drives the overall "today" progress badge.
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
        weight: 2,
      ),
      AmolItem(
        id: 'zuhr',
        titleEn: 'Zuhr',
        titleBn: 'যুহর',
        icon: Icons.wb_sunny_rounded,
        weight: 1,
      ),
      AmolItem(
        id: 'asr',
        titleEn: 'Asr',
        titleBn: 'আসর',
        icon: Icons.brightness_5_rounded,
        weight: 1,
      ),
      AmolItem(
        id: 'maghrib',
        titleEn: 'Maghrib',
        titleBn: 'মাগরিব',
        icon: Icons.bedtime_rounded,
        weight: 1,
      ),
      AmolItem(
        id: 'isha',
        titleEn: 'Isha',
        titleBn: 'ইশা',
        icon: Icons.nights_stay_rounded,
        weight: 2,
      ),
    ],
  ),
  AmolSection(
    id: 'sunnah_witr',
    titleEn: 'Sunnah & Witr',
    titleBn: 'সুন্নত ও বিতর',
    icon: Icons.auto_awesome_rounded,
    items: [
      AmolItem(
        id: 'witr',
        titleEn: 'Witr',
        titleBn: 'বিতর',
        icon: Icons.brightness_3_rounded,
        weight: 1,
      ),
      AmolItem(
        id: 'fajr_sunnah',
        titleEn: 'Fajr Sunnah',
        titleBn: 'ফজর সুন্নত',
        icon: Icons.wb_twilight_rounded,
        weight: 1,
      ),
      AmolItem(
        id: 'zuhr_sunnah',
        titleEn: 'Zuhr Sunnah',
        titleBn: 'যুহর সুন্নত',
        icon: Icons.wb_sunny_rounded,
        weight: 1,
      ),
      AmolItem(
        id: 'maghrib_sunnah',
        titleEn: 'Maghrib Sunnah',
        titleBn: 'মাগরিব সুন্নত',
        icon: Icons.bedtime_rounded,
        weight: 1,
      ),
      AmolItem(
        id: 'isha_sunnah',
        titleEn: 'Isha Sunnah',
        titleBn: 'ইশা সুন্নত',
        icon: Icons.nights_stay_rounded,
        weight: 1,
      ),
    ],
  ),
  AmolSection(
    id: 'sunnah',
    titleEn: 'Nafl Salat',
    titleBn: 'নফল সালাত',
    icon: Icons.star_rounded,
    items: [
      AmolItem(
        id: 'tahajjud',
        titleEn: 'Tahajjud',
        titleBn: 'তাহাজ্জুদ',
        icon: Icons.nightlight_round,
        weight: 3,
      ),
      AmolItem(
        id: 'ishraq_chasht_awwabin',
        titleEn: 'Ishraq/Chasht/Awwabin',
        titleBn: 'ইশরাক/চাশত/আওয়াবিন',
        icon: Icons.wb_sunny_outlined,
        weight: 1,
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
        weight: 3,
      ),
      AmolItem(
        id: 'hadith',
        titleEn: 'Hadith Reading',
        titleBn: 'হাদিস পড়া',
        icon: Icons.history_edu_rounded,
        weight: 1,
      ),
      AmolItem(
        id: 'skill_develop',
        titleEn: 'Skill Development',
        titleBn: 'স্কিল ডেভেলপ',
        icon: Icons.psychology_rounded,
        weight: 1,
      ),
      AmolItem(
        id: 'morning_dhikr',
        titleEn: 'Morning Dhikr',
        titleBn: 'সকালের যিকির',
        icon: Icons.light_mode_rounded,
        weight: 2,
      ),
      AmolItem(
        id: 'evening_dhikr',
        titleEn: 'Evening Dhikr',
        titleBn: 'সন্ধ্যার যিকির',
        icon: Icons.dark_mode_rounded,
        weight: 1,
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
        weight: 2,
      ),
      AmolItem(
        id: 'durood',
        titleEn: 'Durood',
        titleBn: 'দরুদ',
        icon: Icons.spa_rounded,
        weight: 1,
      ),
      AmolItem(
        id: 'nafl_siam',
        titleEn: 'Nafl Fasting',
        titleBn: 'নফল সিয়াম',
        icon: Icons.no_food_rounded,
        weight: 1,
      ),
      AmolItem(
        id: 'physical_exercise',
        titleEn: 'Physical Exercise',
        titleBn: 'শরীর চর্চা',
        icon: Icons.fitness_center_rounded,
        weight: 1,
      ),
      AmolItem(
        id: 'good_advice',
        titleEn: 'Giving Good Advice',
        titleBn: 'সৎ উপদেশ দেওয়া',
        icon: Icons.record_voice_over_rounded,
        weight: 1,
      ),
      AmolItem(
        id: 'sin_free',
        titleEn: 'Staying Sin-Free',
        titleBn: 'পাপ মুক্ত থাকা',
        icon: Icons.shield_rounded,
        weight: 2,
      ),
    ],
  ),
];

/// Total number of trackable deeds across every section.
int get kAmolTotalCount =>
    kAmolSections.fold(0, (sum, section) => sum + section.items.length);

/// The maximum achievable daily score — the sum of every deed's weight (30).
/// This is the denominator for the "today" progress badge and all trend views.
int get kAmolMaxScore => kAmolSections.fold(
      0,
      (sum, section) => sum + section.maxScore,
    );

/// Fast `itemId -> weight` lookup, used to score a stored set of completed
/// deed ids without walking the section tree each time.
final Map<String, int> kAmolWeightById = {
  for (final section in kAmolSections)
    for (final item in section.items) item.id: item.weight,
};

/// Sums the weights of the completed [ids], ignoring any unknown ids.
int amolScoreForIds(Iterable<String> ids) =>
    ids.fold(0, (sum, id) => sum + (kAmolWeightById[id] ?? 0));
