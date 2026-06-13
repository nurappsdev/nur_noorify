import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:first_project/features/dua/models/dua_item.dart';
import 'package:first_project/features/dua/providers/dua_category_provider.dart';
import 'package:first_project/features/dua/utils/dua_utils.dart';
import 'package:first_project/shared/providers/language_provider.dart';
import 'package:first_project/shared/widgets/noorify_glass.dart';

class DuaCategoryScreen extends StatelessWidget {
  const DuaCategoryScreen({
    super.key,
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

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      context.read<DuaCategoryProvider>().setQuery(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<DuaItem> _filtered(String query) {
    final byCategory = widget.allDuas.where((item) => item.category == widget.categoryKey).toList(growable: false);
    if (query.isEmpty) return byCategory;
    return byCategory.where((item) {
      final q = query.toLowerCase();
      return item.id.toString().contains(q) ||
          item.titleEn.toLowerCase().contains(q) ||
          item.titleBn.toLowerCase().contains(q) ||
          item.arabic.contains(q) ||
          item.english.toLowerCase().contains(q) ||
          item.bangla.toLowerCase().contains(q) ||
          item.reference.toLowerCase().contains(q);
    }).toList(growable: false);
  }

  String _titleFor(DuaItem item, bool isBangla) {
    final bn = DuaUtils.sanitizeTitle(item.titleBn.trim());
    final en = DuaUtils.sanitizeTitle(item.titleEn.trim());
    return isBangla ? (bn.isNotEmpty ? bn : en) : (en.isNotEmpty ? en : bn);
  }

  void _openDuaDetails(DuaItem item, bool isBangla) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) {
        final glass = NoorifyGlassTheme(sheetContext);
        return Padding(
          padding: EdgeInsets.fromLTRB(16.w, 6.h, 16.w, 18.h),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_titleFor(item, isBangla), style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700, color: glass.textPrimary)),
                SizedBox(height: 8.h),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(14.r),
                  decoration: BoxDecoration(
                    color: glass.isDark ? const Color(0x33162833) : const Color(0xFFF2F8FB),
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(color: glass.glassBorder),
                  ),
                  child: Text(
                    item.arabic,
                    textDirection: TextDirection.rtl,
                    style: GoogleFonts.getFont(DuaConstants.indoPakArabicFont, textStyle: TextStyle(fontSize: 38.sp, height: 1.55, fontWeight: FontWeight.w500, color: glass.textPrimary)),
                  ),
                ),
                SizedBox(height: 14.h),
                Text(isBangla ? item.bangla : item.english, style: TextStyle(fontSize: 16.sp, height: 1.7, color: glass.textPrimary)),
                if (item.reference.trim().isNotEmpty) ...[
                  SizedBox(height: 14.h),
                  Text(isBangla ? 'রেফারেন্স' : 'Reference', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700, color: glass.textMuted)),
                  SizedBox(height: 4.h),
                  Text(item.reference, style: TextStyle(fontSize: 13.sp, height: 1.5, color: glass.textSecondary)),
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
        final filtered = _filtered(category.query);
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
                              IconButton(onPressed: () => Navigator.of(context).maybePop(), icon: const Icon(Icons.arrow_back_rounded), tooltip: isBangla ? 'ফিরে যান' : 'Back'),
                              Expanded(child: Text(isBangla ? widget.categoryTitleBn : widget.categoryTitleEn, style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700, color: glass.textPrimary))),
                              IconButton(
                                onPressed: () {
                                  context.read<DuaCategoryProvider>().toggleSearch();
                                  if (!context.read<DuaCategoryProvider>().showSearch) _searchController.clear();
                                },
                                icon: Icon(category.showSearch ? Icons.close_rounded : Icons.search_rounded),
                                tooltip: isBangla ? 'সার্চ' : 'Search',
                              ),
                            ],
                          ),
                          if (category.showSearch) ...[
                            SizedBox(height: 8.h),
                            TextField(
                              controller: _searchController,
                              style: TextStyle(color: glass.textPrimary),
                              decoration: InputDecoration(
                                hintText: isBangla ? 'শিরোনাম বা অর্থ দিয়ে খুঁজুন' : 'Search by title or meaning',
                                hintStyle: TextStyle(color: glass.textMuted),
                                prefixIcon: Icon(Icons.search_rounded, color: glass.textMuted),
                                filled: true,
                                fillColor: glass.isDark ? const Color(0x33152933) : const Color(0xF2FFFFFF),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide(color: glass.glassBorder)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide(color: glass.glassBorder)),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
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
                          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                          child: Row(
                            children: [
                              Icon(Icons.menu_book_rounded, size: 18.sp, color: glass.accent),
                              SizedBox(width: 8.w),
                              Expanded(child: Text(isBangla ? widget.categoryTitleBn : widget.categoryTitleEn, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700, color: glass.textPrimary))),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 4.h),
                                decoration: BoxDecoration(color: glass.isDark ? const Color(0x2A2EB8E6) : const Color(0x221EA8B8), borderRadius: BorderRadius.circular(999.r)),
                                child: Text('${filtered.length}', style: TextStyle(color: glass.accent, fontSize: 12.sp, fontWeight: FontWeight.w700)),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 10.h),
                        if (filtered.isEmpty)
                          NoorifyGlassCard(
                            radius: BorderRadius.circular(16.r),
                            padding: EdgeInsets.all(16.r),
                            child: Text(isBangla ? 'এই ফিল্টারে কোনো দুআ নেই।' : 'No dua found for this filter.', style: TextStyle(color: glass.textSecondary, fontWeight: FontWeight.w600)),
                          )
                        else
                          ...filtered.map((item) => Padding(
                            padding: EdgeInsets.only(bottom: 8.h),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14.r),
                              onTap: () => _openDuaDetails(item, isBangla),
                              child: NoorifyGlassCard(
                                radius: BorderRadius.circular(14.r),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(_titleFor(item, isBangla), maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14.5.sp, fontWeight: FontWeight.w700, color: glass.textPrimary)),
                                          SizedBox(height: 2.h),
                                          Text(isBangla ? item.titleEn : item.titleBn, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.sp, color: glass.textSecondary)),
                                        ],
                                      ),
                                    ),
                                    SizedBox(width: 8.w),
                                    Icon(Icons.bookmark_add_outlined, size: 21.sp, color: glass.textMuted),
                                  ],
                                ),
                              ),
                            ),
                          )),
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
