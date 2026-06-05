import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:first_project/shared/services/app_globals.dart';

/// A single Dua o Jikir category shown as a tappable card on the hub screen.
class _DuaJikirCategory {
  const _DuaJikirCategory({
    required this.id,
    required this.titleEn,
    required this.titleBn,
    required this.subtitleEn,
    required this.subtitleBn,
    required this.icon,
  });

  final String id;
  final String titleEn;
  final String titleBn;
  final String subtitleEn;
  final String subtitleBn;
  final IconData icon;
}

/// "Dua o Jikir" hub — a simple grid of category cards (Jikir after Fard Salah,
/// Morning & Evening Jikir, Daily Life Duas, Others). Tapping a card opens its
/// detail screen. Theming mirrors the Boyos Zacai / Calendar & Waqt screens.
class DuaJikirScreen extends StatefulWidget {
  const DuaJikirScreen({super.key});

  @override
  State<DuaJikirScreen> createState() => _DuaJikirScreenState();
}

class _DuaJikirScreenState extends State<DuaJikirScreen> {
  static const _categories = <_DuaJikirCategory>[
    _DuaJikirCategory(
      id: 'fard_salah',
      titleEn: 'Jikir after Fard Salah',
      titleBn: 'ফরজ নামাজের পর জিকির',
      subtitleEn: 'Tasbih and adhkar after each prayer',
      subtitleBn: 'প্রতি নামাজ শেষে তাসবিহ ও জিকির',
      icon: Icons.mosque_rounded,
    ),
    _DuaJikirCategory(
      id: 'morning_evening',
      titleEn: 'Morning and Evening Jikir',
      titleBn: 'সকাল-সন্ধ্যার জিকির',
      subtitleEn: 'Daily morning and evening remembrance',
      subtitleBn: 'প্রতিদিনের সকাল ও সন্ধ্যার জিকির',
      icon: Icons.wb_twilight_rounded,
    ),
    _DuaJikirCategory(
      id: 'daily_life',
      titleEn: 'Daily Life Duas',
      titleBn: 'দৈনন্দিন জীবনের দোয়া',
      subtitleEn: 'Duas for everyday occasions',
      subtitleBn: 'প্রতিদিনের নানা মুহূর্তের দোয়া',
      icon: Icons.volunteer_activism_rounded,
    ),
    _DuaJikirCategory(
      id: 'others',
      titleEn: 'Others',
      titleBn: 'অন্যান্য',
      subtitleEn: 'More duas and dhikr',
      subtitleBn: 'আরও দোয়া ও জিকির',
      icon: Icons.more_horiz_rounded,
    ),
  ];

  bool get _isBangla => appLanguageNotifier.value == AppLanguage.bangla;
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  @override
  void initState() {
    super.initState();
    appLanguageNotifier.addListener(_onLanguageChanged);
  }

  @override
  void dispose() {
    appLanguageNotifier.removeListener(_onLanguageChanged);
    super.dispose();
  }

  void _onLanguageChanged() {
    if (mounted) setState(() {});
  }

  String _text(String en, String bn) => _isBangla ? bn : en;

  // Theme palette (mirrors the Boyos Zacai screen).
  Color get _bg => _isDark ? const Color(0xFF060C17) : const Color(0xFFF0F7FC);
  Color get _cardBg =>
      _isDark ? const Color(0xFF101C2A) : const Color(0xFFFFFFFF);
  Color get _cellBg =>
      _isDark ? const Color(0xFF16283A) : const Color(0xFFEEF5FA);
  Color get _cardBorder =>
      _isDark ? const Color(0x22D2F4FF) : const Color(0xFFDCE8F1);
  Color get _textPrimary => _isDark ? Colors.white : const Color(0xFF143349);
  Color get _textSecondary =>
      _isDark ? const Color(0xFF9BC1D8) : const Color(0xFF5F7E94);
  Color get _accent =>
      _isDark ? const Color(0xFF1FD5C0) : const Color(0xFF1EA8B8);

  void _openCategory(_DuaJikirCategory category) {
    final title = _text(category.titleEn, category.titleBn);
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => switch (category.id) {
          'fard_salah' => FardSalahJikirScreen(title: title),
          _ => _DuaJikirCategoryScreen(title: title),
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: _textPrimary,
        title: Text(
          _text('Dua o Jikir', 'দোয়া ও জিকির'),
          style: TextStyle(
            color: _textPrimary,
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView.separated(
          padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
          itemCount: _categories.length,
          separatorBuilder: (_, _) => SizedBox(height: 12.h),
          itemBuilder: (context, index) =>
              _buildCategoryCard(_categories[index]),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(_DuaJikirCategory category) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14.r),
        onTap: () => _openCategory(category),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: _cardBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 44.r,
                height: 44.r,
                decoration: BoxDecoration(
                  color: _cellBg,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(category.icon, color: _accent, size: 22.sp),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _text(category.titleEn, category.titleBn),
                      style: TextStyle(
                        color: _textPrimary,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      _text(category.subtitleEn, category.subtitleBn),
                      style: TextStyle(
                        color: _textSecondary,
                        fontSize: 11.5.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14.sp,
                color: _textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Placeholder detail screen for a Dua o Jikir category. The list of duas/dhikr
/// for each category can be wired in here once the content is available.
class _DuaJikirCategoryScreen extends StatelessWidget {
  const _DuaJikirCategoryScreen({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF060C17) : const Color(0xFFF0F7FC);
    final textPrimary = isDark ? Colors.white : const Color(0xFF143349);
    final textSecondary =
        isDark ? const Color(0xFF9BC1D8) : const Color(0xFF5F7E94);
    final isBangla = appLanguageNotifier.value == AppLanguage.bangla;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: textPrimary,
        title: Text(
          title,
          style: TextStyle(
            color: textPrimary,
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 32.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.auto_stories_rounded,
                  size: 48.sp,
                  color: textSecondary,
                ),
                SizedBox(height: 14.h),
                Text(
                  isBangla
                      ? 'শীঘ্রই যুক্ত হবে'
                      : 'Coming soon',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  isBangla
                      ? 'এই বিভাগের দোয়া ও জিকির শীঘ্রই যোগ করা হবে।'
                      : 'Duas and dhikr for this section will be added soon.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The "Jikir after Fard Salah" content: the adhkar recited after every
/// obligatory prayer, the alternative tasbih, and the extra dhikr recommended
/// after Fajr and Maghrib. Content is presented as transliteration plus an
/// English meaning, so it reads the same in either app language.
class FardSalahJikirScreen extends StatelessWidget {
  const FardSalahJikirScreen({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF060C17) : const Color(0xFFF0F7FC);
    final textPrimary = isDark ? Colors.white : const Color(0xFF143349);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: textPrimary,
        title: Text(
          title,
          style: TextStyle(
            color: textPrimary,
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 28.h),
          children: [
            const _JikirSectionHeader('After Every Fard (Obligatory) Prayer'),
            SizedBox(height: 12.h),
            const _JikirTile(
              number: '1',
              arabic: 'أَسْتَغْفِرُ اللَّهَ',
              title: 'Astaghfirullah',
              count: '3 times',
              meaning: 'I seek forgiveness from Allah.',
            ),
            SizedBox(height: 10.h),
            const _JikirTile(
              number: '2',
              arabic:
                  'اللَّهُمَّ أَنْتَ السَّلَامُ وَمِنْكَ السَّلَامُ، '
                  'تَبَارَكْتَ يَا ذَا الْجَلَالِ وَالْإِكْرَامِ',
              title:
                  'Allahumma Antas-Salam wa Minkas-Salam, Tabarakta Ya '
                  'Dhal-Jalali wal-Ikram',
              count: '1 time',
              meaning:
                  'O Allah, You are the Source of Peace, and from You comes '
                  'peace. Blessed are You, O Possessor of Majesty and Honor.',
            ),
            SizedBox(height: 10.h),
            const _JikirTile(
              number: '3',
              arabic: 'سُبْحَانَ اللَّهِ',
              title: 'SubhanAllah',
              count: '33 times',
              meaning: 'Glory be to Allah.',
            ),
            SizedBox(height: 10.h),
            const _JikirTile(
              number: '4',
              arabic: 'الْحَمْدُ لِلَّهِ',
              title: 'Alhamdulillah',
              count: '33 times',
              meaning: 'All praise is for Allah.',
            ),
            SizedBox(height: 10.h),
            const _JikirTile(
              number: '5',
              arabic: 'اللَّهُ أَكْبَرُ',
              title: 'Allahu Akbar',
              count: '34 times',
              meaning: 'Allah is the Greatest.',
            ),
            SizedBox(height: 10.h),
            const _JikirAltTile(
              intro:
                  'Or you can do SubhanAllah 33, Alhamdulillah 33, Allahu '
                  'Akbar 33, then recite:',
              arabic:
                  'لَا إِلَٰهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، '
                  'لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ، وَهُوَ عَلَىٰ كُلِّ '
                  'شَيْءٍ قَدِيرٌ',
              title:
                  'La ilaha illallahu wahdahu la sharika lahu, lahul-mulku wa '
                  'lahul-hamdu, wa huwa ‘ala kulli shay’in qadir.',
              meaning:
                  'There is no deity except Allah alone; He has no partner. '
                  'His is the dominion, His is the praise, and He is Able to '
                  'do all things.',
            ),
            SizedBox(height: 10.h),
            const _JikirTile(
              number: '6',
              arabic: 'آيَةُ الْكُرْسِيِّ',
              title: 'Ayat al-Kursi',
              count: '1 time',
              meaning: '',
              note: 'Very recommended after each obligatory prayer.',
            ),
            SizedBox(height: 10.h),
            const _JikirTile(
              number: '7',
              arabic:
                  'سُورَةُ الْإِخْلَاصِ، سُورَةُ الْفَلَقِ، سُورَةُ النَّاسِ',
              title: 'Surah Al-Ikhlas, Surah Al-Falaq, Surah An-Nas',
              count: '1 time each',
              meaning: '',
              note: 'Fajr and Maghrib: Recite each 3 times.',
            ),
            SizedBox(height: 22.h),
            const _JikirSectionHeader(
              'Extra Recommended Dhikr (Fajr & Maghrib)',
            ),
            SizedBox(height: 12.h),
            const _JikirTile(
              arabic:
                  'لَا إِلَٰهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، '
                  'لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ، يُحْيِي وَيُمِيتُ، '
                  'وَهُوَ عَلَىٰ كُلِّ شَيْءٍ قَدِيرٌ',
              title:
                  'La ilaha illallahu wahdahu la sharika lahu, lahul-mulku wa '
                  'lahul-hamdu, yuhyi wa yumit, wa huwa ‘ala kulli shay’in '
                  'qadir',
              count: '10 times',
              meaning:
                  'There is no deity except Allah, alone, with no partner. '
                  'His is the dominion, His is the praise, He gives life and '
                  'causes death, and He is capable of everything.',
            ),
          ],
        ),
      ),
    );
  }
}

class _JikirSectionHeader extends StatelessWidget {
  const _JikirSectionHeader(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? const Color(0xFF1FD5C0) : const Color(0xFF1EA8B8);
    final textPrimary = isDark ? Colors.white : const Color(0xFF143349);

    return Row(
      children: [
        Container(
          width: 4.w,
          height: 18.h,
          decoration: BoxDecoration(
            color: accent,
            borderRadius: BorderRadius.circular(2.r),
          ),
        ),
        SizedBox(width: 9.w),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: textPrimary,
              fontSize: 15.5.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _JikirTile extends StatelessWidget {
  const _JikirTile({
    this.number,
    this.arabic,
    required this.title,
    this.count,
    required this.meaning,
    this.note,
  });

  final String? number;
  final String? arabic;
  final String title;
  final String? count;
  final String meaning;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF101C2A) : const Color(0xFFFFFFFF);
    final cardBorder =
        isDark ? const Color(0x22D2F4FF) : const Color(0xFFDCE8F1);
    final cellBg = isDark ? const Color(0xFF16283A) : const Color(0xFFEEF5FA);
    final textPrimary = isDark ? Colors.white : const Color(0xFF143349);
    final textSecondary =
        isDark ? const Color(0xFF9BC1D8) : const Color(0xFF5F7E94);
    final accent = isDark ? const Color(0xFF1FD5C0) : const Color(0xFF1EA8B8);
    final gold = isDark ? const Color(0xFFE6C77A) : const Color(0xFFB78A2E);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 13.h),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (number != null) ...[
            Container(
              width: 26.r,
              height: 26.r,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: cellBg,
                shape: BoxShape.circle,
              ),
              child: Text(
                number!,
                style: TextStyle(
                  color: accent,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            SizedBox(width: 11.w),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (arabic != null) ...[
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      arabic!,
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w600,
                        height: 1.9,
                      ),
                    ),
                  ),
                  SizedBox(height: 8.h),
                ],
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 14.5.sp,
                          fontWeight: FontWeight.w800,
                          height: 1.3,
                        ),
                      ),
                    ),
                    if (count != null) ...[
                      SizedBox(width: 8.w),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 9.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(999.r),
                          border: Border.all(
                            color: accent.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          count!,
                          style: TextStyle(
                            color: accent,
                            fontSize: 10.5.sp,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (meaning.isNotEmpty) ...[
                  SizedBox(height: 6.h),
                  Text(
                    meaning,
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 12.5.sp,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                ],
                if (note != null) ...[
                  SizedBox(height: 7.h),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.star_rounded,
                        size: 14.sp,
                        color: gold,
                      ),
                      SizedBox(width: 5.w),
                      Expanded(
                        child: Text(
                          note!,
                          style: TextStyle(
                            color: gold,
                            fontSize: 11.5.sp,
                            fontWeight: FontWeight.w700,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The "Or you can do …" alternative tasbih block, styled distinctly from the
/// numbered tiles with a leading intro line.
class _JikirAltTile extends StatelessWidget {
  const _JikirAltTile({
    required this.intro,
    this.arabic,
    required this.title,
    required this.meaning,
  });

  final String intro;
  final String? arabic;
  final String title;
  final String meaning;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBorder =
        isDark ? const Color(0x22D2F4FF) : const Color(0xFFDCE8F1);
    final textPrimary = isDark ? Colors.white : const Color(0xFF143349);
    final textSecondary =
        isDark ? const Color(0xFF9BC1D8) : const Color(0xFF5F7E94);
    final accent = isDark ? const Color(0xFF1FD5C0) : const Color(0xFF1EA8B8);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 13.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? const [Color(0xFF13404B), Color(0xFF0F2F3A)]
              : const [Color(0xFFE3F4F7), Color(0xFFD3ECF1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.swap_horiz_rounded, size: 16.sp, color: accent),
              SizedBox(width: 6.w),
              Text(
                'Alternative',
                style: TextStyle(
                  color: accent,
                  fontSize: 11.5.sp,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          SizedBox(height: 7.h),
          Text(
            intro,
            style: TextStyle(
              color: textSecondary,
              fontSize: 12.5.sp,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          SizedBox(height: 9.h),
          if (arabic != null) ...[
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                arabic!,
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w600,
                  height: 1.9,
                ),
              ),
            ),
            SizedBox(height: 8.h),
          ],
          Text(
            title,
            style: TextStyle(
              color: textPrimary,
              fontSize: 14.5.sp,
              fontWeight: FontWeight.w800,
              height: 1.35,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            meaning,
            style: TextStyle(
              color: textSecondary,
              fontSize: 12.5.sp,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
