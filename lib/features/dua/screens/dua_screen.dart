import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:first_project/features/dua/models/dua_item.dart';
import 'package:first_project/features/dua/providers/dua_category_provider.dart';
import 'package:first_project/features/dua/providers/dua_provider.dart';
import 'package:first_project/shared/providers/language_provider.dart';
import 'package:first_project/shared/widgets/bottom_nav.dart';
import 'package:first_project/shared/widgets/noorify_glass.dart';

class DuaScreen extends StatelessWidget {
  const DuaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<DuaProvider>(
      create: (_) => DuaProvider(),
      child: const _DuaView(),
    );
  }
}

class _DuaView extends StatefulWidget {
  const _DuaView();

  @override
  State<_DuaView> createState() => _DuaViewState();
}

class _DuaViewState extends State<_DuaView> {
  DuaProvider get _dua => context.read<DuaProvider>();

  List<DuaItem> get _duas => _dua.duas;

  static const List<String> _mainCategoryOrder = [
    'namaj',
    'morning_evening',
    'daily_life',
    'saom',
    'quranic',
    'general',
  ];

  static const List<_MainCategoryMeta> _mainCategoryMetas = [
    _MainCategoryMeta(
      key: 'namaj',
      titleEn: 'Prayer Dua',
      titleBn:
          '\u09a8\u09be\u09ae\u09be\u099c\u09c7\u09b0 \u09aa\u09b0\u09c7\u09b0 \u0986\u09ae\u09b2',
      subtitleEn: 'Post-prayer daily adhkar',
      subtitleBn:
          '\u09ab\u099c\u09b0, \u09af\u09cb\u09b9\u09b0, \u0986\u09b8\u09b0, \u09ae\u09be\u0997\u09b0\u09bf\u09ac, \u098f\u09b6\u09be',
      icon: Icons.mosque_outlined,
    ),
    _MainCategoryMeta(
      key: 'morning_evening',
      titleEn: 'Morning & Evening',
      titleBn:
          '\u09b8\u0995\u09be\u09b2-\u09b8\u09a8\u09cd\u09a7\u09cd\u09af\u09be\u09b0 \u09af\u09bf\u0995\u09bf\u09b0',
      subtitleEn: 'Daily protection adhkar',
      subtitleBn:
          '\u09a6\u09c8\u09a8\u09bf\u0995 \u09af\u09bf\u0995\u09bf\u09b0 \u0993 \u09a6\u09c1\u0986',
      icon: Icons.wb_sunny_outlined,
    ),
    _MainCategoryMeta(
      key: 'daily_life',
      titleEn: 'Daily Life',
      titleBn:
          '\u09a6\u09c8\u09a8\u09a8\u09cd\u09a6\u09bf\u09a8 \u09a6\u09c1\u0986',
      subtitleEn: 'Travel, food, home, family',
      subtitleBn:
          '\u0996\u09be\u0993\u09af\u09bc\u09be, \u09ad\u09cd\u09b0\u09ae\u09a3, \u09aa\u09b0\u09bf\u09ac\u09be\u09b0, \u0998\u09b0',
      icon: Icons.home_outlined,
    ),
    _MainCategoryMeta(
      key: 'saom',
      titleEn: 'Fasting',
      titleBn: '\u09b8\u09bf\u09af\u09bc\u09be\u09ae',
      subtitleEn: 'Sehri, iftar and fasting duas',
      subtitleBn:
          '\u09b8\u09c7\u09b9\u09b0\u09bf, \u0987\u09ab\u09a4\u09be\u09b0 \u0993 \u09b0\u09cb\u099c\u09be\u09b0 \u09a6\u09c1\u0986',
      icon: Icons.nights_stay_outlined,
    ),
    _MainCategoryMeta(
      key: 'quranic',
      titleEn: 'Quranic Dua',
      titleBn: '\u0995\u09c1\u09b0\u0986\u09a8\u09bf\u0995 \u09a6\u09c1\u0986',
      subtitleEn: 'Duas from Quran',
      subtitleBn:
          '\u0995\u09c1\u09b0\u0986\u09a8 \u09a5\u09c7\u0995\u09c7 \u09a8\u09c7\u0993\u09df\u09be \u09a6\u09c1\u0986',
      icon: Icons.menu_book_outlined,
    ),
    _MainCategoryMeta(
      key: 'general',
      titleEn: 'General',
      titleBn: '\u09b8\u09be\u09a7\u09be\u09b0\u09a3',
      subtitleEn: 'Other useful duas',
      subtitleBn:
          '\u0985\u09a8\u09cd\u09af\u09be\u09a8\u09cd\u09af \u09a6\u09c1\u0986',
      icon: Icons.grid_view_rounded,
    ),
  ];

  static const List<_SubCategoryMeta> _subCategoryMetas = [
    _SubCategoryMeta(
      key: 'after_fajr',
      mainKey: 'namaj',
      titleEn: 'After Fajr Prayer',
      titleBn:
          '\u09ab\u099c\u09b0\u09c7\u09b0 \u09a8\u09be\u09ae\u09be\u099c\u09c7\u09b0 \u09aa\u09b0\u09c7',
      icon: Icons.wb_sunny_outlined,
    ),
    _SubCategoryMeta(
      key: 'after_zuhr',
      mainKey: 'namaj',
      titleEn: 'After Zuhr Prayer',
      titleBn:
          '\u09af\u09cb\u09b9\u09b0\u09c7\u09b0 \u09a8\u09be\u09ae\u09be\u099c\u09c7\u09b0 \u09aa\u09b0\u09c7',
      icon: Icons.light_mode_outlined,
    ),
    _SubCategoryMeta(
      key: 'after_asr',
      mainKey: 'namaj',
      titleEn: 'After Asr Prayer',
      titleBn:
          '\u0986\u09b8\u09b0\u09c7\u09b0 \u09a8\u09be\u09ae\u09be\u099c\u09c7\u09b0 \u09aa\u09b0\u09c7',
      icon: Icons.schedule_rounded,
    ),
    _SubCategoryMeta(
      key: 'after_maghrib',
      mainKey: 'namaj',
      titleEn: 'After Maghrib Prayer',
      titleBn:
          '\u09ae\u09be\u0997\u09b0\u09bf\u09ac\u09c7\u09b0 \u09a8\u09be\u09ae\u09be\u099c\u09c7\u09b0 \u09aa\u09b0\u09c7',
      icon: Icons.bedtime_outlined,
    ),
    _SubCategoryMeta(
      key: 'after_isha',
      mainKey: 'namaj',
      titleEn: 'After Isha Prayer',
      titleBn:
          '\u098f\u09b6\u09be\u09b0 \u09a8\u09be\u09ae\u09be\u099c\u09c7\u09b0 \u09aa\u09b0\u09c7',
      icon: Icons.dark_mode_outlined,
    ),
    _SubCategoryMeta(
      key: 'morning_adhkar',
      mainKey: 'morning_evening',
      titleEn: 'Morning Adhkar',
      titleBn:
          '\u09b8\u0995\u09be\u09b2\u09c7\u09b0 \u09af\u09bf\u0995\u09bf\u09b0',
      icon: Icons.wb_sunny_rounded,
    ),
    _SubCategoryMeta(
      key: 'evening_adhkar',
      mainKey: 'morning_evening',
      titleEn: 'Evening Adhkar',
      titleBn:
          '\u09b8\u09a8\u09cd\u09a7\u09cd\u09af\u09be\u09b0 \u09af\u09bf\u0995\u09bf\u09b0',
      icon: Icons.nightlight_round,
    ),
    _SubCategoryMeta(
      key: 'home_dua',
      mainKey: 'daily_life',
      titleEn: 'Home Dua',
      titleBn: '\u0998\u09b0\u09c7\u09b0 \u09a6\u09c1\u0986',
      icon: Icons.home_rounded,
    ),
    _SubCategoryMeta(
      key: 'food_dua',
      mainKey: 'daily_life',
      titleEn: 'Food Dua',
      titleBn: '\u0996\u09be\u0993\u09df\u09be\u09b0 \u09a6\u09c1\u0986',
      icon: Icons.restaurant_menu_rounded,
    ),
    _SubCategoryMeta(
      key: 'fasting_dua',
      mainKey: 'saom',
      titleEn: 'Fasting Dua',
      titleBn:
          '\u09b8\u09bf\u09af\u09bc\u09be\u09ae\u09c7\u09b0 \u09a6\u09c1\u0986',
      icon: Icons.emoji_food_beverage_rounded,
    ),
    _SubCategoryMeta(
      key: 'quranic_dua',
      mainKey: 'quranic',
      titleEn: 'Quranic Dua',
      titleBn: '\u0995\u09c1\u09b0\u0986\u09a8\u09bf\u0995 \u09a6\u09c1\u0986',
      icon: Icons.menu_book_rounded,
    ),
  ];

  static final Map<String, _MainCategoryMeta> _mainMetaByKey =
      _mainCategoryMetas.asMap().map((_, meta) => MapEntry(meta.key, meta));

  static final Map<String, _SubCategoryMeta> _subMetaByKey = _subCategoryMetas
      .asMap()
      .map((_, meta) => MapEntry(meta.key, meta));

  static final Map<String, int> _subCategoryOrder = {
    for (var i = 0; i < _subCategoryMetas.length; i++)
      _subCategoryMetas[i].key: i,
  };

  List<_MainCategoryTileData> _buildMainTiles() {
    final group = <String, List<DuaItem>>{};
    for (final dua in _duas) {
      final key = dua.mainCategory.trim().isEmpty
          ? 'general'
          : dua.mainCategory;
      group.putIfAbsent(key, () => <DuaItem>[]).add(dua);
    }

    final output = <_MainCategoryTileData>[];
    group.forEach((key, items) {
      final meta = _mainMetaByKey[key] ?? _MainCategoryMeta.fallback(key);
      final subCount = items.map((d) => d.category).toSet().length;
      output.add(
        _MainCategoryTileData(
          meta: meta,
          duaCount: items.length,
          subCategoryCount: subCount,
        ),
      );
    });

    output.sort((a, b) {
      final ai = _mainCategoryOrder.indexOf(a.meta.key);
      final bi = _mainCategoryOrder.indexOf(b.meta.key);
      final aRank = ai == -1 ? 999 : ai;
      final bRank = bi == -1 ? 999 : bi;
      if (aRank != bRank) return aRank.compareTo(bRank);
      return a.meta.titleEn.compareTo(b.meta.titleEn);
    });

    return output;
  }

  void _openMainCategory(String mainCategoryKey) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _MainCategoryScreen(
          mainCategoryKey: mainCategoryKey,
          allDuas: _duas,
          mainMeta:
              _mainMetaByKey[mainCategoryKey] ??
              _MainCategoryMeta.fallback(mainCategoryKey),
          subMetaByKey: _subMetaByKey,
          subCategoryOrder: _subCategoryOrder,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final glass = NoorifyGlassTheme(context);

    return Consumer2<LanguageProvider, DuaProvider>(
      builder: (context, lang, dua, _) {
        final isBangla = lang.isBangla;
        final mainTiles = _buildMainTiles();

        return Scaffold(
          backgroundColor: glass.bgBottom,
          body: NoorifyGlassBackground(
            child: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(14.w, 10.h, 14.w, 10.h),
                    child: NoorifyGlassCard(
                      radius: BorderRadius.circular(20.r),
                      padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 14.h),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isBangla ? '\u09a6\u09c1\u0986' : 'Dua',
                                  style: TextStyle(
                                    fontSize: 30.sp,
                                    fontWeight: FontWeight.w700,
                                    color: glass.textPrimary,
                                    height: 1,
                                  ),
                                ),
                                SizedBox(height: 6.h),
                                Text(
                                  isBangla
                                      ? '\u09aa\u09cd\u09b0\u09a7\u09be\u09a8 \u0995\u09cd\u09af\u09be\u099f\u09be\u0997\u09b0\u09bf \u09a5\u09c7\u0995\u09c7 \u09a6\u09c1\u0986 \u09ac\u09c7\u099b\u09c7 \u09a8\u09bf\u09a8'
                                      : 'Choose a main category to continue',
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    color: glass.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.menu_book_rounded,
                            color: glass.accent,
                            size: 26.sp,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: dua.isLoading
                        ? Center(
                            child: CircularProgressIndicator(
                              color: glass.accent,
                            ),
                          )
                        : dua.error != null
                        ? _ErrorView(
                            glass: glass,
                            error: dua.error!,
                            onRetry: () =>
                                context.read<DuaProvider>().loadDuas(),
                            retryText: isBangla
                                ? '\u0986\u09ac\u09be\u09b0 \u099a\u09c7\u09b7\u09cd\u099f\u09be \u0995\u09b0\u09c1\u09a8'
                                : 'Retry',
                          )
                        : ListView(
                            padding: EdgeInsets.fromLTRB(14.w, 2.h, 14.w, 10.h),
                            children: [
                              if (mainTiles.isEmpty)
                                NoorifyGlassCard(
                                  radius: BorderRadius.circular(16.r),
                                  padding: EdgeInsets.all(16.r),
                                  child: Text(
                                    isBangla
                                        ? '\u0995\u09cb\u09a8\u09cb \u09a6\u09c1\u0986 \u09a1\u09c7\u099f\u09be \u09aa\u09be\u0993\u09df\u09be \u09af\u09be\u09df\u09a8\u09bf\u0964'
                                        : 'No dua data found.',
                                    style: TextStyle(
                                      color: glass.textSecondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                )
                              else
                                _MainCategoryGrid(
                                  items: mainTiles,
                                  isBangla: isBangla,
                                  onTap: (item) =>
                                      _openMainCategory(item.meta.key),
                                ),
                            ],
                          ),
                  ),
                  bottomNav(context, 1),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MainCategoryScreen extends StatelessWidget {
  const _MainCategoryScreen({
    required this.mainCategoryKey,
    required this.mainMeta,
    required this.allDuas,
    required this.subMetaByKey,
    required this.subCategoryOrder,
  });

  final String mainCategoryKey;
  final _MainCategoryMeta mainMeta;
  final List<DuaItem> allDuas;
  final Map<String, _SubCategoryMeta> subMetaByKey;
  final Map<String, int> subCategoryOrder;

  List<_SubCategoryTileData> _subTiles() {
    final grouped = <String, List<DuaItem>>{};

    for (final dua in allDuas) {
      if (dua.mainCategory != mainCategoryKey) continue;
      grouped.putIfAbsent(dua.category, () => <DuaItem>[]).add(dua);
    }

    final output = <_SubCategoryTileData>[];
    grouped.forEach((subKey, items) {
      final meta =
          subMetaByKey[subKey] ??
          _SubCategoryMeta.fallback(key: subKey, mainKey: mainCategoryKey);
      output.add(_SubCategoryTileData(meta: meta, duaCount: items.length));
    });

    output.sort((a, b) {
      final aOrder = subCategoryOrder[a.meta.key] ?? 999;
      final bOrder = subCategoryOrder[b.meta.key] ?? 999;
      if (aOrder != bOrder) return aOrder.compareTo(bOrder);
      return a.meta.titleEn.compareTo(b.meta.titleEn);
    });

    return output;
  }

  @override
  Widget build(BuildContext context) {
    final glass = NoorifyGlassTheme(context);

    return Consumer<LanguageProvider>(
      builder: (context, lang, _) {
        final isBangla = lang.isBangla;
        final tiles = _subTiles();

        return Scaffold(
          backgroundColor: glass.bgBottom,
          body: NoorifyGlassBackground(
            child: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(14.w, 10.h, 14.w, 8.h),
                    child: NoorifyGlassCard(
                      radius: BorderRadius.circular(18.r),
                      padding: EdgeInsets.fromLTRB(12.w, 10.h, 8.w, 10.h),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.of(context).maybePop(),
                            icon: const Icon(Icons.arrow_back_rounded),
                            tooltip: isBangla
                                ? '\u09ab\u09bf\u09b0\u09c7 \u09af\u09be\u09a8'
                                : 'Back',
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isBangla
                                      ? mainMeta.titleBn
                                      : mainMeta.titleEn,
                                  style: TextStyle(
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.w700,
                                    color: glass.textPrimary,
                                  ),
                                ),
                                SizedBox(height: 2.h),
                                Text(
                                  isBangla
                                      ? mainMeta.subtitleBn
                                      : mainMeta.subtitleEn,
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: glass.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(mainMeta.icon, color: glass.accent),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.fromLTRB(14.w, 2.h, 14.w, 10.h),
                      children: [
                        if (tiles.isEmpty)
                          NoorifyGlassCard(
                            radius: BorderRadius.circular(16.r),
                            padding: EdgeInsets.all(16.r),
                            child: Text(
                              isBangla
                                  ? '\u098f\u0987 \u0995\u09cd\u09af\u09be\u099f\u09be\u0997\u09b0\u09bf\u09a4\u09c7 \u0995\u09cb\u09a8\u09cb \u0986\u0987\u099f\u09c7\u09ae \u09a8\u09c7\u0987\u0964'
                                  : 'No sub-category found here.',
                              style: TextStyle(color: glass.textSecondary),
                            ),
                          )
                        else
                          _SubCategoryGrid(
                            items: tiles,
                            isBangla: isBangla,
                            onTap: (tile) {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => _DuaCategoryScreen(
                                    categoryKey: tile.meta.key,
                                    categoryTitleEn: tile.meta.titleEn,
                                    categoryTitleBn: tile.meta.titleBn,
                                    allDuas: allDuas,
                                  ),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DuaCategoryScreen extends StatelessWidget {
  const _DuaCategoryScreen({
    required this.categoryKey,
    required this.categoryTitleEn,
    required this.categoryTitleBn,
    required this.allDuas,
  });

  final String categoryKey;
  final String categoryTitleEn;
  final String categoryTitleBn;
  final List<DuaItem> allDuas;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<DuaCategoryProvider>(
      create: (_) => DuaCategoryProvider(),
      child: _DuaCategoryView(
        categoryKey: categoryKey,
        categoryTitleEn: categoryTitleEn,
        categoryTitleBn: categoryTitleBn,
        allDuas: allDuas,
      ),
    );
  }
}

class _DuaCategoryView extends StatefulWidget {
  const _DuaCategoryView({
    required this.categoryKey,
    required this.categoryTitleEn,
    required this.categoryTitleBn,
    required this.allDuas,
  });

  final String categoryKey;
  final String categoryTitleEn;
  final String categoryTitleBn;
  final List<DuaItem> allDuas;

  @override
  State<_DuaCategoryView> createState() => _DuaCategoryViewState();
}

class _DuaCategoryViewState extends State<_DuaCategoryView> {
  final TextEditingController _searchController = TextEditingController();
  static const String _indoPakArabicFont = 'Lateef';

  String get _query => context.read<DuaCategoryProvider>().query;
  bool get _showSearch => context.read<DuaCategoryProvider>().showSearch;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    context.read<DuaCategoryProvider>().setQuery(_searchController.text);
  }

  static String _sanitizeTitle(String value) {
    return value
        .replaceAll(' ? ', ' - ')
        .replaceAll(' ?', '')
        .replaceAll('? ', '')
        .replaceAll('?', '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  List<DuaItem> _filtered() {
    final byCategory = widget.allDuas
        .where((item) => item.category == widget.categoryKey)
        .toList(growable: false);

    if (_query.isEmpty) return byCategory;

    return byCategory
        .where((item) {
          return item.id.toString().contains(_query) ||
              item.titleEn.toLowerCase().contains(_query) ||
              item.titleBn.toLowerCase().contains(_query) ||
              item.arabic.contains(_query) ||
              item.english.toLowerCase().contains(_query) ||
              item.bangla.toLowerCase().contains(_query) ||
              item.reference.toLowerCase().contains(_query);
        })
        .toList(growable: false);
  }

  String _titleFor(DuaItem item, bool isBangla) {
    final bn = _sanitizeTitle(item.titleBn.trim());
    final en = _sanitizeTitle(item.titleEn.trim());
    if (isBangla) return bn.isNotEmpty ? bn : en;
    return en.isNotEmpty ? en : bn;
  }

  String _subtitleFor(DuaItem item, bool isBangla) {
    final en = _sanitizeTitle(item.titleEn.trim());
    final bn = _sanitizeTitle(item.titleBn.trim());
    return isBangla ? en : bn;
  }

  void _openDuaDetails(DuaItem item, bool isBangla) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) {
        final glass = NoorifyGlassTheme(sheetContext);
        final title = _titleFor(item, isBangla);
        return Padding(
          padding: EdgeInsets.fromLTRB(16.w, 6.h, 16.w, 18.h),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                    color: glass.textPrimary,
                  ),
                ),
                SizedBox(height: 8.h),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(14.r),
                  decoration: BoxDecoration(
                    color: glass.isDark
                        ? const Color(0x33162833)
                        : const Color(0xFFF2F8FB),
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(color: glass.glassBorder),
                  ),
                  child: Text(
                    item.arabic,
                    textDirection: TextDirection.rtl,
                    style: GoogleFonts.getFont(
                      _indoPakArabicFont,
                      textStyle: TextStyle(
                        fontSize: 38.sp,
                        height: 1.55,
                        fontWeight: FontWeight.w500,
                        color: glass.textPrimary,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 14.h),
                Text(
                  isBangla ? item.bangla : item.english,
                  style: TextStyle(
                    fontSize: 16.sp,
                    height: 1.7,
                    color: glass.textPrimary,
                  ),
                ),
                if (item.reference.trim().isNotEmpty) ...[
                  SizedBox(height: 14.h),
                  Text(
                    isBangla
                        ? '\u09b0\u09c7\u09ab\u09be\u09b0\u09c7\u09a8\u09cd\u09b8'
                        : 'Reference',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                      color: glass.textMuted,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    item.reference,
                    style: TextStyle(
                      fontSize: 13.sp,
                      height: 1.5,
                      color: glass.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final glass = NoorifyGlassTheme(context);

    return Consumer2<LanguageProvider, DuaCategoryProvider>(
      builder: (context, lang, category, _) {
        final isBangla = lang.isBangla;
        final filtered = _filtered();

        return Scaffold(
          backgroundColor: glass.bgBottom,
          body: NoorifyGlassBackground(
            child: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(14.w, 10.h, 14.w, 8.h),
                    child: NoorifyGlassCard(
                      radius: BorderRadius.circular(18.r),
                      padding: EdgeInsets.fromLTRB(12.w, 10.h, 8.w, 10.h),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              IconButton(
                                onPressed: () =>
                                    Navigator.of(context).maybePop(),
                                icon: const Icon(Icons.arrow_back_rounded),
                                tooltip: isBangla
                                    ? '\u09ab\u09bf\u09b0\u09c7 \u09af\u09be\u09a8'
                                    : 'Back',
                              ),
                              Expanded(
                                child: Text(
                                  isBangla
                                      ? widget.categoryTitleBn
                                      : widget.categoryTitleEn,
                                  style: TextStyle(
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.w700,
                                    color: glass.textPrimary,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  final category =
                                      context.read<DuaCategoryProvider>();
                                  category.toggleSearch();
                                  if (!category.showSearch) {
                                    _searchController.clear();
                                  }
                                },
                                icon: Icon(
                                  _showSearch
                                      ? Icons.close_rounded
                                      : Icons.search_rounded,
                                ),
                                tooltip: isBangla
                                    ? '\u09b8\u09be\u09b0\u09cd\u099a'
                                    : 'Search',
                              ),
                            ],
                          ),
                          if (_showSearch) ...[
                            SizedBox(height: 8.h),
                            TextField(
                              controller: _searchController,
                              style: TextStyle(color: glass.textPrimary),
                              decoration: InputDecoration(
                                hintText: isBangla
                                    ? '\u09b6\u09bf\u09b0\u09cb\u09a8\u09be\u09ae \u09ac\u09be \u0985\u09b0\u09cd\u09a5 \u09a6\u09bf\u09df\u09c7 \u0996\u09c1\u0981\u099c\u09c1\u09a8'
                                    : 'Search by title or meaning',
                                hintStyle: TextStyle(color: glass.textMuted),
                                prefixIcon: Icon(
                                  Icons.search_rounded,
                                  color: glass.textMuted,
                                ),
                                filled: true,
                                fillColor: glass.isDark
                                    ? const Color(0x33152933)
                                    : const Color(0xF2FFFFFF),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                  borderSide: BorderSide(
                                    color: glass.glassBorder,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                  borderSide: BorderSide(
                                    color: glass.glassBorder,
                                  ),
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12.w,
                                  vertical: 10.h,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.fromLTRB(14.w, 2.h, 14.w, 10.h),
                      children: [
                        NoorifyGlassCard(
                          radius: BorderRadius.circular(16.r),
                          padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 10.h),
                          child: Row(
                            children: [
                              Icon(
                                Icons.menu_book_rounded,
                                size: 18.sp,
                                color: glass.accent,
                              ),
                              SizedBox(width: 8.w),
                              Expanded(
                                child: Text(
                                  isBangla
                                      ? widget.categoryTitleBn
                                      : widget.categoryTitleEn,
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w700,
                                    color: glass.textPrimary,
                                  ),
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 9.w,
                                  vertical: 4.h,
                                ),
                                decoration: BoxDecoration(
                                  color: glass.isDark
                                      ? const Color(0x2A2EB8E6)
                                      : const Color(0x221EA8B8),
                                  borderRadius: BorderRadius.circular(999.r),
                                ),
                                child: Text(
                                  '${filtered.length}',
                                  style: TextStyle(
                                    color: glass.accent,
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 10.h),
                        if (filtered.isEmpty)
                          NoorifyGlassCard(
                            radius: BorderRadius.circular(16.r),
                            padding: EdgeInsets.all(16.r),
                            child: Text(
                              isBangla
                                  ? '\u098f\u0987 \u09ab\u09bf\u09b2\u09cd\u099f\u09be\u09b0\u09c7 \u0995\u09cb\u09a8\u09cb \u09a6\u09c1\u0986 \u09a8\u09c7\u0987\u0964'
                                  : 'No dua found for this filter.',
                              style: TextStyle(
                                color: glass.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        else
                          ...filtered.map((item) {
                            return Padding(
                              padding: EdgeInsets.only(bottom: 8.h),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(14.r),
                                onTap: () => _openDuaDetails(item, isBangla),
                                child: NoorifyGlassCard(
                                  radius: BorderRadius.circular(14.r),
                                  padding: const EdgeInsets.fromLTRB(
                                    12,
                                    10,
                                    12,
                                    10,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _titleFor(item, isBangla),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 14.5.sp,
                                                fontWeight: FontWeight.w700,
                                                color: glass.textPrimary,
                                              ),
                                            ),
                                            SizedBox(height: 2.h),
                                            Text(
                                              _subtitleFor(item, isBangla),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 12.sp,
                                                color: glass.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      SizedBox(width: 8.w),
                                      Icon(
                                        Icons.bookmark_add_outlined,
                                        size: 21.sp,
                                        color: glass.textMuted,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MainCategoryGrid extends StatelessWidget {
  const _MainCategoryGrid({
    required this.items,
    required this.isBangla,
    required this.onTap,
  });

  final List<_MainCategoryTileData> items;
  final bool isBangla;
  final ValueChanged<_MainCategoryTileData> onTap;

  @override
  Widget build(BuildContext context) {
    final glass = NoorifyGlassTheme(context);
    final itemWidth = (MediaQuery.of(context).size.width - 38) / 2;

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: items
          .map((item) {
            return InkWell(
              borderRadius: BorderRadius.circular(16.r),
              onTap: () => onTap(item),
              child: SizedBox(
                width: itemWidth,
                child: NoorifyGlassCard(
                  radius: BorderRadius.circular(16.r),
                  padding: EdgeInsets.fromLTRB(10.w, 12.h, 10.w, 12.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 46.r,
                        height: 46.r,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12.r),
                          color: glass.isDark
                              ? const Color(0x33243C46)
                              : const Color(0xFFE5F5F6),
                        ),
                        child: Icon(item.meta.icon, color: glass.accent),
                      ),
                      SizedBox(height: 10.h),
                      Text(
                        isBangla ? item.meta.titleBn : item.meta.titleEn,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: glass.textPrimary,
                        ),
                      ),
                      SizedBox(height: 3.h),
                      Text(
                        isBangla ? item.meta.subtitleBn : item.meta.subtitleEn,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5.sp,
                          color: glass.textSecondary,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _CountPill(
                            text: isBangla
                                ? '${item.subCategoryCount} \u099f\u09be\u0987\u09b2'
                                : '${item.subCategoryCount} tiles',
                          ),
                          _CountPill(
                            text: isBangla
                                ? '${item.duaCount} \u09a6\u09c1\u0986'
                                : '${item.duaCount} duas',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          })
          .toList(growable: false),
    );
  }
}

class _SubCategoryGrid extends StatelessWidget {
  const _SubCategoryGrid({
    required this.items,
    required this.isBangla,
    required this.onTap,
  });

  final List<_SubCategoryTileData> items;
  final bool isBangla;
  final ValueChanged<_SubCategoryTileData> onTap;

  @override
  Widget build(BuildContext context) {
    final glass = NoorifyGlassTheme(context);
    final itemWidth = (MediaQuery.of(context).size.width - 38) / 2;

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: items
          .map((item) {
            return InkWell(
              borderRadius: BorderRadius.circular(16.r),
              onTap: () => onTap(item),
              child: SizedBox(
                width: itemWidth,
                child: NoorifyGlassCard(
                  radius: BorderRadius.circular(16.r),
                  padding: EdgeInsets.fromLTRB(10.w, 12.h, 10.w, 12.h),
                  child: Column(
                    children: [
                      Container(
                        width: 70.r,
                        height: 70.r,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: glass.isDark
                              ? const Color(0x33243C46)
                              : const Color(0xFFE5F5F6),
                        ),
                        child: Icon(
                          item.meta.icon,
                          size: 32.sp,
                          color: glass.textSecondary,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        isBangla ? item.meta.titleBn : item.meta.titleEn,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                          color: glass.textPrimary,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      _CountPill(
                        text: isBangla
                            ? '${item.duaCount} \u09a6\u09c1\u0986'
                            : '${item.duaCount} duas',
                      ),
                    ],
                  ),
                ),
              ),
            );
          })
          .toList(growable: false),
    );
  }
}

class _CountPill extends StatelessWidget {
  const _CountPill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final glass = NoorifyGlassTheme(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: glass.isDark ? const Color(0x2A2EB8E6) : const Color(0x221EA8B8),
        borderRadius: BorderRadius.circular(999.r),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: glass.accent,
          fontSize: 11.sp,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.glass,
    required this.error,
    required this.onRetry,
    required this.retryText,
  });

  final NoorifyGlassTheme glass;
  final String error;
  final VoidCallback onRetry;
  final String retryText;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(18.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: glass.textSecondary),
            ),
            SizedBox(height: 10.h),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: glass.accent,
                foregroundColor: glass.isDark
                    ? const Color(0xFF052830)
                    : Colors.white,
              ),
              child: Text(retryText),
            ),
          ],
        ),
      ),
    );
  }
}

class _MainCategoryMeta {
  const _MainCategoryMeta({
    required this.key,
    required this.titleEn,
    required this.titleBn,
    required this.subtitleEn,
    required this.subtitleBn,
    required this.icon,
  });

  final String key;
  final String titleEn;
  final String titleBn;
  final String subtitleEn;
  final String subtitleBn;
  final IconData icon;

  static _MainCategoryMeta fallback(String key) {
    final human = key.replaceAll('_', ' ').trim();
    final titled = human.isEmpty
        ? 'General'
        : '${human[0].toUpperCase()}${human.substring(1)}';
    return _MainCategoryMeta(
      key: key,
      titleEn: titled,
      titleBn: '\u09b8\u09be\u09a7\u09be\u09b0\u09a3',
      subtitleEn: 'Custom category',
      subtitleBn:
          '\u0995\u09be\u09b8\u09cd\u099f\u09ae \u0995\u09cd\u09af\u09be\u099f\u09be\u0997\u09b0\u09bf',
      icon: Icons.grid_view_rounded,
    );
  }
}

class _SubCategoryMeta {
  const _SubCategoryMeta({
    required this.key,
    required this.mainKey,
    required this.titleEn,
    required this.titleBn,
    required this.icon,
  });

  final String key;
  final String mainKey;
  final String titleEn;
  final String titleBn;
  final IconData icon;

  static _SubCategoryMeta fallback({
    required String key,
    required String mainKey,
  }) {
    final human = key.replaceAll('_', ' ').trim();
    final titled = human.isEmpty
        ? 'General Item'
        : '${human[0].toUpperCase()}${human.substring(1)}';
    return _SubCategoryMeta(
      key: key,
      mainKey: mainKey,
      titleEn: titled,
      titleBn: '\u0995\u09cd\u09af\u09be\u099f\u09be\u0997\u09b0\u09bf',
      icon: Icons.bookmark_outline_rounded,
    );
  }
}

class _MainCategoryTileData {
  const _MainCategoryTileData({
    required this.meta,
    required this.duaCount,
    required this.subCategoryCount,
  });

  final _MainCategoryMeta meta;
  final int duaCount;
  final int subCategoryCount;
}

class _SubCategoryTileData {
  const _SubCategoryTileData({required this.meta, required this.duaCount});

  final _SubCategoryMeta meta;
  final int duaCount;
}
