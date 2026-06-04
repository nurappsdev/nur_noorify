import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:first_project/features/quran/services/quran_bookmarks_service.dart';
import 'package:first_project/shared/services/app_globals.dart';
import 'package:first_project/shared/widgets/noorify_glass.dart';

class QuranBookmarksScreen extends StatelessWidget {
  const QuranBookmarksScreen({super.key, required this.bookmarks});

  final List<QuranAyahBookmark> bookmarks;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLanguage>(
      valueListenable: appLanguageNotifier,
      builder: (context, language, _) {
        final isBangla = language == AppLanguage.bangla;
        final glass = NoorifyGlassTheme(context);

        String t(String en, String bn) => isBangla ? bn : en;
        String digits(String input) {
          if (!isBangla) return input;
          const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
          const bangla = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
          var out = input;
          for (var i = 0; i < english.length; i++) {
            out = out.replaceAll(english[i], bangla[i]);
          }
          return out;
        }

        return Scaffold(
          backgroundColor: glass.bgBottom,
          body: NoorifyGlassBackground(
            child: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 10.h),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.arrow_back_rounded),
                        ),
                        SizedBox(width: 6.w),
                        Expanded(
                          child: Text(
                            t('Saved Bookmarks', 'সেভ করা বুকমার্ক'),
                            style: TextStyle(
                              color: glass.textPrimary,
                              fontSize: 21.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          digits(bookmarks.length.toString()),
                          style: TextStyle(
                            color: glass.textSecondary,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 14.h),
                      itemCount: bookmarks.length,
                      separatorBuilder: (_, _) => SizedBox(height: 10.h),
                      itemBuilder: (context, index) {
                        final item = bookmarks[index];
                        final note = item.note.trim();
                        final subtitle = note.isEmpty
                            ? '${t('Surah', 'সূরা')} ${digits(item.surahNo.toString())}, ${t('Ayah', 'আয়াত')} ${digits(item.ayahNo.toString())}'
                            : note;
                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16.r),
                            onTap: () => Navigator.of(context).pop(item),
                            child: NoorifyGlassCard(
                              radius: BorderRadius.circular(16.r),
                              padding: EdgeInsets.fromLTRB(
                                12.w,
                                12.h,
                                12.w,
                                10.h,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40.r,
                                    height: 40.r,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: glass.accent.withValues(
                                        alpha: 0.17,
                                      ),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: glass.accentSoft,
                                        width: 1.2,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.bookmark_rounded,
                                      size: 20.sp,
                                      color: glass.accent,
                                    ),
                                  ),
                                  SizedBox(width: 12.w),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${item.surahName} \u2022 ${t('Ayah', 'আয়াত')} ${digits(item.ayahNo.toString())}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: glass.textPrimary,
                                            fontSize: 15.sp,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        SizedBox(height: 2.h),
                                        Text(
                                          subtitle,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: glass.textSecondary,
                                            fontSize: 12.5.sp,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(width: 6.w),
                                  Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 16.sp,
                                    color: glass.textSecondary,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
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
