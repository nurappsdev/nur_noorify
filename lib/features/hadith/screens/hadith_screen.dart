import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import 'package:first_project/features/hadith/models/hadith_item.dart';
import 'package:first_project/features/hadith/providers/hadith_provider.dart';
import 'package:first_project/shared/providers/language_provider.dart';
import 'package:first_project/shared/widgets/bottom_nav.dart';
import 'package:first_project/shared/widgets/noorify_glass.dart';

class HadithScreen extends StatelessWidget {
  const HadithScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<HadithProvider>(
      create: (_) => HadithProvider(),
      child: const _HadithView(),
    );
  }
}

class _HadithView extends StatefulWidget {
  const _HadithView();

  @override
  State<_HadithView> createState() => _HadithViewState();
}

class _HadithViewState extends State<_HadithView> {
  final TextEditingController _searchController = TextEditingController();

  bool get _isBangla => context.read<LanguageProvider>().isBangla;

  bool _looksMojibake(String value) {
    for (final unit in value.codeUnits) {
      if (unit == 0x00C3 ||
          unit == 0x00C2 ||
          unit == 0x00E0 ||
          unit == 0x00D8 ||
          unit == 0x00D9 ||
          unit == 0x00D0 ||
          unit == 0x00E2) {
        return true;
      }
    }
    return false;
  }

  String _repairMojibake(String value) {
    var output = value;
    for (var i = 0; i < 4; i++) {
      if (!_looksMojibake(output)) break;
      try {
        output = utf8.decode(latin1.encode(output));
      } catch (_) {
        break;
      }
    }
    return output;
  }

  bool _containsBangla(String value) {
    return RegExp(r'[\u0980-\u09FF]').hasMatch(value);
  }

  String _text(String english, String bangla) {
    if (!_isBangla) return english;
    final repaired = _repairMojibake(bangla);
    if (_containsBangla(repaired) && !_looksMojibake(repaired)) {
      return repaired;
    }
    return english;
  }

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
    context.read<HadithProvider>().setQuery(_searchController.text);
  }

  String _categoryLabel(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) return _text('General', 'সাধারণ');

    if (_isBangla) {
      switch (normalized) {
        case 'revelation':
          return 'ওহী';
        case 'belief':
          return 'ঈমান';
        case 'knowledge':
          return 'জ্ঞান';
        case 'prayers_salat':
          return 'সালাত';
        case 'good_manners_and_form_al_adab':
          return 'আদব';
        default:
          return 'সাধারণ';
      }
    }

    return normalized
        .split('_')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  void _openHadithDetails(HadithItem item) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (sheetContext) {
        final glass = NoorifyGlassTheme(sheetContext);
        return Padding(
          padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.titleBn.isNotEmpty ? item.titleBn : item.titleEn,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: glass.textPrimary,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  item.reference,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: glass.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 10.h),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12.r),
                  decoration: BoxDecoration(
                    color: glass.isDark
                        ? const Color(0x44112635)
                        : const Color(0xFFEAF3FA),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: glass.glassBorder),
                  ),
                  child: Text(
                    item.arabic,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.w700,
                      color: glass.textPrimary,
                      height: 1.45,
                    ),
                  ),
                ),
                SizedBox(height: 12.h),
                Text(
                  _text('English', 'ইংরেজি'),
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: glass.textMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  item.english,
                  style: TextStyle(fontSize: 14.sp, color: glass.textPrimary),
                ),
                if (item.bangla.trim().isNotEmpty) ...[
                  SizedBox(height: 10.h),
                  Text(
                    _text('Bangla', 'বাংলা'),
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: glass.textMuted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    item.bangla,
                    style: TextStyle(fontSize: 14.sp, color: glass.textPrimary),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _onTapPlay(HadithItem item) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _text(
            'Hadith audio will be added in a future update.',
            'হাদিস অডিও ভবিষ্যৎ আপডেটে যোগ করা হবে।',
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LanguageProvider>();
    final provider = context.watch<HadithProvider>();
    final filtered = provider.filteredHadiths;
    final glass = NoorifyGlassTheme(context);

    return Scaffold(
      backgroundColor: glass.bgBottom,
      body: NoorifyGlassBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 0.h),
                child: NoorifyGlassCard(
                  padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 14.h),
                  radius: BorderRadius.circular(20.r),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _text('Sahih Bukhari (50)', 'সহিহ বুখারী (৫০)'),
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    color: glass.textPrimary,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10.w,
                              vertical: 5.h,
                            ),
                            decoration: BoxDecoration(
                              color: glass.isDark
                                  ? const Color(0x332EB8E6)
                                  : const Color(0x1F1EA8B8),
                              borderRadius: BorderRadius.circular(999.r),
                              border: Border.all(color: glass.glassBorder),
                            ),
                            child: Text(
                              '${filtered.length}/${provider.hadiths.length}',
                              style: TextStyle(
                                color: glass.textPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 12.sp,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        _text(
                          'Lightweight offline hadith collection for initial release',
                          'প্রাথমিক রিলিজের জন্য হালকা অফলাইন হাদিস সংগ্রহ',
                        ),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: glass.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 12.h),
                      TextField(
                        controller: _searchController,
                        style: TextStyle(color: glass.textPrimary),
                        decoration: InputDecoration(
                          hintText: _text(
                            'Search hadith, category, or reference',
                            'হাদিস, ক্যাটাগরি বা রেফারেন্স খুঁজুন',
                          ),
                          hintStyle: TextStyle(color: glass.textMuted),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: glass.textMuted,
                          ),
                          filled: true,
                          fillColor: glass.isDark
                              ? const Color(0x4412272E)
                              : const Color(0xECFFFFFF),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                            borderSide: BorderSide(color: glass.glassBorder),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                            borderSide: BorderSide(color: glass.glassBorder),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 10.w,
                            vertical: 10.h,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: provider.isLoading
                    ? Center(
                        child: CircularProgressIndicator(color: glass.accent),
                      )
                    : provider.error != null
                    ? Center(
                        child: Padding(
                          padding: EdgeInsets.all(20.r),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                provider.error!,
                                textAlign: TextAlign.center,
                                style: TextStyle(color: glass.textSecondary),
                              ),
                              SizedBox(height: 10.h),
                              FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor: glass.accent,
                                  foregroundColor: glass.isDark
                                      ? const Color(0xFF032F35)
                                      : Colors.white,
                                ),
                                onPressed: () =>
                                    context.read<HadithProvider>().loadHadiths(),
                                child: Text(_text('Retry', 'পুনরায় চেষ্টা')),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: EdgeInsets.fromLTRB(14.w, 8.h, 14.w, 10.h),
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => SizedBox(height: 10.h),
                        itemBuilder: (context, index) {
                          final item = filtered[index];
                          final hasAudio = (item.audio ?? '').trim().isNotEmpty;
                          return InkWell(
                            borderRadius: BorderRadius.circular(16.r),
                            onTap: () => _openHadithDetails(item),
                            child: NoorifyGlassCard(
                              radius: BorderRadius.circular(16.r),
                              padding: const EdgeInsets.fromLTRB(
                                12,
                                10,
                                12,
                                12,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 9.w,
                                          vertical: 5.h,
                                        ),
                                        decoration: BoxDecoration(
                                          color: glass.isDark
                                              ? const Color(0x332EB8E6)
                                              : const Color(0x221EA8B8),
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                        ),
                                        child: Text(
                                          '#${item.id}',
                                          style: TextStyle(
                                            color: glass.accent,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 11.sp,
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 8.w),
                                      Expanded(
                                        child: Text(
                                          _categoryLabel(item.category),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: glass.textSecondary,
                                            fontSize: 12.sp,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      IconButton.filledTonal(
                                        tooltip: hasAudio
                                            ? _text('Play audio', 'অডিও চালান')
                                            : _text('No audio yet', 'অডিও নেই'),
                                        onPressed: hasAudio
                                            ? () => _onTapPlay(item)
                                            : null,
                                        style: IconButton.styleFrom(
                                          backgroundColor: glass.isDark
                                              ? const Color(0x3316383E)
                                              : const Color(0x221EA8B8),
                                          foregroundColor: glass.accent,
                                        ),
                                        icon: const Icon(
                                          Icons.play_arrow_rounded,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 4.h),
                                  Text(
                                    item.titleBn.isNotEmpty
                                        ? item.titleBn
                                        : item.titleEn,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 15.sp,
                                      fontWeight: FontWeight.w700,
                                      color: glass.textPrimary,
                                    ),
                                  ),
                                  SizedBox(height: 6.h),
                                  Text(
                                    item.english,
                                    maxLines: 4,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13.sp,
                                      color: glass.textSecondary,
                                    ),
                                  ),
                                  SizedBox(height: 6.h),
                                  Text(
                                    item.reference,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      color: glass.accentSoft,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              bottomNav(context, 1),
            ],
          ),
        ),
      ),
    );
  }
}
