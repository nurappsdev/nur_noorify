import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import 'package:first_project/features/dua/models/dua_item.dart';
import 'package:first_project/features/dua/models/dua_meta.dart';
import 'package:first_project/features/dua/providers/dua_provider.dart';
import 'package:first_project/features/dua/screens/sub_screens/main_category_sub_screen.dart';
import 'package:first_project/features/dua/utils/dua_utils.dart';
import 'package:first_project/features/dua/widgets/dua_category_widgets.dart';
import 'package:first_project/shared/providers/language_provider.dart';
import 'package:first_project/shared/widgets/noorify_glass.dart';

class DuaScreen extends StatelessWidget {
  const DuaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<DuaProvider>(create: (_) => DuaProvider(), child: const _DuaView());
  }
}

class _DuaView extends StatefulWidget {
  const _DuaView();
  @override
  State<_DuaView> createState() => _DuaViewState();
}

class _DuaViewState extends State<_DuaView> {
  static final Map<String, MainCategoryMeta> _mainMetaByKey = {for (var m in DuaConstants.mainCategoryMetas) m.key: m};
  static final Map<String, SubCategoryMeta> _subMetaByKey = {for (var m in DuaConstants.subCategoryMetas) m.key: m};
  static final Map<String, int> _subCategoryOrder = {for (var i = 0; i < DuaConstants.subCategoryMetas.length; i++) DuaConstants.subCategoryMetas[i].key: i};

  List<MainCategoryTileData> _buildMainTiles(List<DuaItem> duas) {
    final group = <String, List<DuaItem>>{};
    for (final d in duas) {
      final key = d.mainCategory.trim().isEmpty ? 'general' : d.mainCategory;
      group.putIfAbsent(key, () => []).add(d);
    }
    return group.entries.map((e) => MainCategoryTileData(meta: _mainMetaByKey[e.key] ?? MainCategoryMeta.fallback(e.key), duaCount: e.value.length, subCategoryCount: e.value.map((d) => d.category).toSet().length)).toList()
      ..sort((a, b) {
        final ai = DuaConstants.mainCategoryOrder.indexOf(a.meta.key), bi = DuaConstants.mainCategoryOrder.indexOf(b.meta.key);
        final ar = ai == -1 ? 999 : ai, br = bi == -1 ? 999 : bi;
        return ar != br ? ar.compareTo(br) : a.meta.titleEn.compareTo(b.meta.titleEn);
      });
  }

  void _openMain(String key, List<DuaItem> duas) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => MainCategorySubScreen(mainCategoryKey: key, allDuas: duas, mainMeta: _mainMetaByKey[key] ?? MainCategoryMeta.fallback(key), subMetaByKey: _subMetaByKey, subCategoryOrder: _subCategoryOrder)));

  @override
  Widget build(BuildContext context) {
    final glass = NoorifyGlassTheme(context);
    return Consumer2<LanguageProvider, DuaProvider>(builder: (context, lang, dua, _) {
      final isBn = lang.isBangla;
      return Scaffold(
        backgroundColor: glass.bgBottom,
        body: NoorifyGlassBackground(
          child: SafeArea(
            child: Column(children: [
              Padding(
                padding: EdgeInsets.fromLTRB(14.w, 10.h, 14.w, 10.h),
                child: NoorifyGlassCard(
                  radius: BorderRadius.circular(20.r), padding: EdgeInsets.all(14.r),
                  child: Row(children: [
                    Material(
                      color: glass.isDark ? const Color(0x332EB8E6) : const Color(0x221EA8B8),
                      shape: const CircleBorder(),
                      child: IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18.sp, color: glass.textPrimary),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(isBn ? 'দুআ' : 'Dua', style: TextStyle(fontSize: 30.sp, fontWeight: FontWeight.w700, color: glass.textPrimary, height: 1)),
                      SizedBox(height: 6.h),
                      Text(isBn ? 'প্রধান ক্যাটাগরি থেকে দুআ বেছে নিন' : 'Choose a main category to continue', style: TextStyle(fontSize: 13.sp, color: glass.textSecondary)),
                    ])),
                    Icon(Icons.menu_book_rounded, color: glass.accent, size: 26.sp),
                  ]),
                ),
              ),
              Expanded(
                child: dua.isLoading ? Center(child: CircularProgressIndicator(color: glass.accent)) : dua.error != null ? ErrorView(error: dua.error!, onRetry: () => context.read<DuaProvider>().loadDuas(), retryText: isBn ? 'আবার চেষ্টা করুন' : 'Retry') : ListView(
                  padding: EdgeInsets.fromLTRB(14.w, 2.h, 14.w, 10.h),
                  children: [
                    if (dua.duas.isEmpty) NoorifyGlassCard(radius: BorderRadius.circular(16.r), padding: EdgeInsets.all(16.r), child: Text(isBn ? 'কোনো দুআ ডেটা পাওয়া যায়নি।' : 'No dua data found.', style: TextStyle(color: glass.textSecondary, fontWeight: FontWeight.w600)))
                    else MainCategoryGrid(items: _buildMainTiles(dua.duas), isBangla: isBn, onTap: (item) => _openMain(item.meta.key, dua.duas)),
                  ],
                ),
              ),
            ]),
          ),
        ),
      );
    });
  }
}
