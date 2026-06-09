import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:first_project/features/quran/models/quran_models.dart';
import 'package:first_project/features/quran/utils/quran_utils.dart';

class QuranHeader extends StatelessWidget {
  const QuranHeader({
    super.key,
    required this.lastReadChapter,
    required this.lastReadProgress,
    required this.onContinueTap,
  });

  final QuranChapter lastReadChapter;
  final ({int ayahNo, double progress}) lastReadProgress;
  final VoidCallback onContinueTap;

  @override
  Widget build(BuildContext context) {
    final completionPercent = (lastReadProgress.progress * 100).round();
    final progressLabel = lastReadProgress.ayahNo <= 0
        ? QuranUtils.t('Start reading to track progress', 'প্রগ্রেস দেখতে পড়া শুরু করুন')
        : QuranUtils.t(
            '${QuranUtils.digits(completionPercent.toString())}% Complete \u2022 Ayat ${QuranUtils.digits(lastReadProgress.ayahNo.toString())}/${QuranUtils.digits(lastReadChapter.totalAyah.toString())}',
            '${QuranUtils.digits(completionPercent.toString())}% সম্পন্ন \u2022 আয়াত ${QuranUtils.digits(lastReadProgress.ayahNo.toString())}/${QuranUtils.digits(lastReadChapter.totalAyah.toString())}',
          );

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF091A2A), Color(0xFF0E2B3D), Color(0xFF144B64)]),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(28.r), bottomRight: Radius.circular(46.r)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(28.r), bottomRight: Radius.circular(46.r)),
        child: Stack(
          children: [
            Positioned(right: -36, top: -36, child: Container(width: 144.r, height: 144.r, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0x1FFFFFFF)))),
            Positioned(left: -52, bottom: -72, child: Container(width: 190.r, height: 190.r, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0x18FFFFFF)))),
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 12.h),
              child: Column(
                children: [
                  Text('\u0627\u0644\u0642\u0631\u0622\u0646 \u0627\u0644\u0643\u0631\u064a\u0645', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 26.sp, fontWeight: FontWeight.w700, height: 1)),
                  SizedBox(height: 2.h),
                  Text(QuranUtils.t('Quran', 'কুরআন'), textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 44.sp, fontWeight: FontWeight.w300, height: 0.92)),
                  SizedBox(height: 2.h),
                  Text(QuranUtils.t('Read | Listen | Offline', 'পড়ুন | শুনুন | অফলাইন'), textAlign: TextAlign.center, style: TextStyle(color: const Color(0xD7FFFFFF), fontSize: 13.sp, fontWeight: FontWeight.w500)),
                  SizedBox(height: 12.h),
                  Container(
                    padding: EdgeInsets.fromLTRB(12.w, 11.h, 12.w, 10.h),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0x2AFFFFFF), Color(0x12000000)]),
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.26)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 34.r, height: 34.r,
                              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(10.r), border: Border.all(color: Colors.white.withValues(alpha: 0.24))),
                              child: Icon(Icons.menu_book_rounded, size: 18.sp, color: Colors.white),
                            ),
                            SizedBox(width: 10.w),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(QuranUtils.t('Last Read:', 'সর্বশেষ তিলাওয়াত:'), style: TextStyle(color: Colors.white.withValues(alpha: 0.86), fontSize: 11.sp, fontWeight: FontWeight.w600)),
                              SizedBox(height: 2.h),
                              Text(lastReadChapter.surahName, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white, fontSize: 17.sp, fontWeight: FontWeight.w700, height: 1.05)),
                              Text('(${QuranUtils.t('Surah', 'সূরা')} ${QuranUtils.digits(lastReadChapter.surahNo.toString())})', style: TextStyle(color: Colors.white.withValues(alpha: 0.84), fontSize: 13.sp, fontWeight: FontWeight.w500)),
                            ])),
                            SizedBox(width: 8.w),
                            FilledButton(
                              onPressed: onContinueTap,
                              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF43E6B0), foregroundColor: const Color(0xFF04353A), padding: EdgeInsets.symmetric(horizontal: 18.w), minimumSize: Size(0.w, 40.h), shape: const StadiumBorder()),
                              child: Text(QuranUtils.t('Continue', 'চালিয়ে যান'), style: const TextStyle(fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ),
                        SizedBox(height: 8.h),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999.r),
                          child: LinearProgressIndicator(minHeight: 5.h, value: lastReadProgress.progress, backgroundColor: Colors.white.withValues(alpha: 0.24), valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF43E6B0))),
                        ),
                        SizedBox(height: 5.h),
                        Align(alignment: Alignment.centerLeft, child: Text(progressLabel, style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 11.5.sp, fontWeight: FontWeight.w600))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
