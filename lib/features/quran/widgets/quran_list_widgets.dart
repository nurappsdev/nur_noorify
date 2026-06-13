import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:first_project/features/quran/models/quran_models.dart';
import 'package:first_project/features/quran/utils/quran_utils.dart';
import 'package:first_project/shared/widgets/noorify_glass.dart';

class FilterChipButton extends StatelessWidget {
  const FilterChipButton({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.isSegment = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool isSegment;

  @override
  Widget build(BuildContext context) {
    final glass = NoorifyGlassTheme(context);
    final bgColor = selected ? glass.accent : (glass.isDark ? const Color(0x66162538) : const Color(0xFFFDFEFF));
    final borderColor = selected ? glass.accentSoft : (glass.isDark ? const Color(0x55B4D8EE) : const Color(0xFFC6DAE8));
    final textColor = selected ? (glass.isDark ? const Color(0xFF032F35) : Colors.white) : glass.textPrimary;

    return InkWell(
      borderRadius: BorderRadius.circular(isSegment ? 10 : 100),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: isSegment ? EdgeInsets.symmetric(horizontal: 4.w, vertical: 9.h) : EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(isSegment ? 10 : 100),
          border: Border.all(color: borderColor),
          boxShadow: selected ? [
            BoxShadow(
              color: glass.accent.withValues(alpha: glass.isDark ? 0.28 : 0.22),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ] : (glass.isDark ? null : const [
            BoxShadow(
              color: Color(0x0B0E3853),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ]),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          style: TextStyle(
            color: textColor,
            fontSize: isSegment ? 13 : null,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class QuranSurahTile extends StatelessWidget {
  const QuranSurahTile({
    super.key,
    required this.chapter,
    required this.hasBookmark,
    required this.onTap,
    required this.onBookmarkTap,
  });

  final QuranChapter chapter;
  final bool hasBookmark;
  final VoidCallback onTap;
  final VoidCallback onBookmarkTap;

  @override
  Widget build(BuildContext context) {
    final glass = NoorifyGlassTheme(context);
    final translation = chapter.surahNameTranslation.trim().isEmpty ? QuranUtils.t('Translation unavailable', 'অনুবাদ পাওয়া যায়নি') : chapter.surahNameTranslation.trim();
    final revLabel = QuranUtils.revelationLabel(chapter.revelationPlace);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(18.r),
        onTap: onTap,
        child: NoorifyGlassCard(
          radius: BorderRadius.circular(18.r),
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 11.h),
          boxShadow: [
            BoxShadow(
              color: glass.isDark ? const Color(0x32000000) : const Color(0x140E3853),
              blurRadius: 14,
              offset: const Offset(0, 7),
            ),
          ],
          child: Row(
            children: [
              Container(
                width: 48.r,
                height: 48.r,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: glass.isDark ? const Color(0xFF122A35) : const Color(0xFFE9F8FC),
                  shape: BoxShape.circle,
                  border: Border.all(color: glass.accentSoft, width: 1.4.w),
                  boxShadow: [
                    BoxShadow(color: glass.accent.withValues(alpha: 0.26), blurRadius: 14, spreadRadius: 1),
                  ],
                ),
                child: Text(
                  chapter.surahNo.toString(),
                  style: TextStyle(color: glass.accentSoft, fontSize: 24.sp, fontWeight: FontWeight.w700, height: 1),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(chapter.surahName, style: TextStyle(color: glass.textPrimary, fontSize: 16.sp, fontWeight: FontWeight.w700, height: 1.1)),
                    SizedBox(height: 1.h),
                    Text(chapter.surahName, style: TextStyle(color: glass.isDark ? const Color(0xFFE4F1FA) : const Color(0xFF21465F), fontSize: 12.5.sp, fontWeight: FontWeight.w500)),
                    SizedBox(height: 1.h),
                    Text(
                      '$revLabel \u2022 ${chapter.totalAyah} ${QuranUtils.t('ayah', 'আয়াত')} \u2022 $translation',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: glass.isDark ? const Color(0xFFC6DBEB) : const Color(0xFF3F627B), fontSize: 11.5.sp, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 110.w),
                child: Text(
                  chapter.surahNameArabic,
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: glass.isDark ? const Color(0xFFDDEBA8) : const Color(0xFF2F5A60), fontSize: 40.sp, fontWeight: FontWeight.w500, height: 0.9),
                ),
              ),
              SizedBox(width: 4.w),
              IconButton.filledTonal(
                onPressed: onBookmarkTap,
                style: IconButton.styleFrom(
                  backgroundColor: hasBookmark ? (glass.isDark ? const Color(0x332EB8E6) : const Color(0x1F1EA8B8)) : (glass.isDark ? const Color(0x3316383E) : const Color(0x121EA8B8)),
                  foregroundColor: hasBookmark ? glass.accent : glass.textSecondary,
                ),
                icon: Icon(hasBookmark ? Icons.bookmark_rounded : Icons.bookmark_border_rounded),
                tooltip: QuranUtils.t('Open bookmarks', 'বুকমার্ক খুলুন'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
