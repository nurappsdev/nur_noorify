import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:first_project/shared/widgets/noorify_glass.dart';

/// A single tappable answer option that colours itself once an answer is picked.
class QuizOptionTile extends StatelessWidget {
  const QuizOptionTile({
    super.key,
    required this.label,
    required this.optionIndex,
    required this.correctIndex,
    required this.selectedIndex,
    this.onTap,
  });

  final String label;
  final int optionIndex;
  final int correctIndex;
  final int? selectedIndex;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final glass = NoorifyGlassTheme(context);
    final answered = selectedIndex != null;
    final isCorrect = optionIndex == correctIndex;
    final isPicked = optionIndex == selectedIndex;

    Color border = glass.glassBorder;
    Color? bg;
    if (answered && isCorrect) {
      border = const Color(0xFF34A853);
      bg = const Color(0x2234A853);
    } else if (answered && isPicked) {
      border = const Color(0xFFE53935);
      bg = const Color(0x22E53935);
    }

    return InkWell(
      borderRadius: BorderRadius.circular(14.r),
      onTap: answered ? null : onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: border, width: 1.4),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14.5.sp,
                  fontWeight: FontWeight.w600,
                  color: glass.textPrimary,
                ),
              ),
            ),
            if (answered && isCorrect)
              Icon(Icons.check_circle,
                  color: const Color(0xFF34A853), size: 20.r)
            else if (answered && isPicked)
              Icon(Icons.cancel, color: const Color(0xFFE53935), size: 20.r),
          ],
        ),
      ),
    );
  }
}

/// Final score screen shown after the last question, with a restart button.
class QuizResultView extends StatelessWidget {
  const QuizResultView({
    super.key,
    required this.score,
    required this.total,
    required this.isBangla,
    required this.onRestart,
  });

  final int score;
  final int total;
  final bool isBangla;
  final VoidCallback onRestart;

  String _t(String en, String bn) => isBangla ? bn : en;

  @override
  Widget build(BuildContext context) {
    final glass = NoorifyGlassTheme(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.workspace_premium_rounded, size: 64.r, color: glass.accent),
          SizedBox(height: 14.h),
          Text(
            _t('Quiz Complete!', 'কুইজ সম্পন্ন!'),
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w700,
              color: glass.textPrimary,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            _t('You scored $score / $total', 'আপনার স্কোর $score / $total'),
            style: TextStyle(fontSize: 15.sp, color: glass.textSecondary),
          ),
          SizedBox(height: 22.h),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: glass.accent,
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14.r),
              ),
            ),
            onPressed: onRestart,
            icon: Icon(Icons.refresh_rounded, size: 18.r),
            label: Text(
              _t('Try Again', 'আবার চেষ্টা করুন'),
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
