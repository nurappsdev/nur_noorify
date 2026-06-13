import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import 'package:first_project/features/dua/models/dua_item.dart';
import 'package:first_project/features/dua/models/dua_meta.dart';
import 'package:first_project/features/dua/screens/sub_screens/dua_category_screen.dart';
import 'package:first_project/features/dua/widgets/dua_category_widgets.dart';
import 'package:first_project/shared/providers/language_provider.dart';
import 'package:first_project/shared/widgets/noorify_glass.dart';

class MainCategorySubScreen extends StatelessWidget {
  const MainCategorySubScreen({
    super.key,
    required this.mainCategoryKey,
    required this.mainMeta,
    required this.allDuas,
    required this.subMetaByKey,
    required this.subCategoryOrder,
  });

  final String mainCategoryKey;
  final MainCategoryMeta mainMeta;
  final List<DuaItem> allDuas;
  final Map<String, SubCategoryMeta> subMetaByKey;
  final Map<String, int> subCategoryOrder;

  List<SubCategoryTileData> _subTiles() {
    final grouped = <String, List<DuaItem>>{};
    for (final dua in allDuas) {
      if (dua.mainCategory != mainCategoryKey) continue;
      grouped.putIfAbsent(dua.category, () => <DuaItem>[]).add(dua);
    }
    final output = <SubCategoryTileData>[];
    grouped.forEach((subKey, items) {
      final meta = subMetaByKey[subKey] ?? SubCategoryMeta.fallback(key: subKey, mainKey: mainCategoryKey);
      output.add(SubCategoryTileData(meta: meta, duaCount: items.length));
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
                            tooltip: isBangla ? 'ফিরে যান' : 'Back',
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isBangla ? mainMeta.titleBn : mainMeta.titleEn,
                                  style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700, color: glass.textPrimary),
                                ),
                                SizedBox(height: 2.h),
                                Text(
                                  isBangla ? mainMeta.subtitleBn : mainMeta.subtitleEn,
                                  style: TextStyle(fontSize: 12.sp, color: glass.textSecondary),
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
                              isBangla ? 'এই ক্যাটাগরিতে কোনো আইটেম নেই।' : 'No sub-category found here.',
                              style: TextStyle(color: glass.textSecondary),
                            ),
                          )
                        else
                          SubCategoryGrid(
                            items: tiles,
                            isBangla: isBangla,
                            onTap: (tile) {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => DuaCategoryScreen(
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
