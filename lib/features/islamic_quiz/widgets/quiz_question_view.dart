import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:first_project/features/islamic_quiz/models/quiz_question.dart';
import 'package:first_project/features/islamic_quiz/widgets/quiz_widgets.dart';
import 'package:first_project/shared/widgets/noorify_glass.dart';

/// Renders the active question: a countdown bar, the question card, the answer
/// options, and the "Next / See Result" button once an answer is locked in.
class QuizQuestionView extends StatelessWidget {
  const QuizQuestionView({
    super.key,
    required this.question,
    required this.isBangla,
    required this.selectedIndex,
    required this.remaining,
    required this.totalSeconds,
    required this.isLast,
    required this.onSelect,
    required this.onNext,
  });

  final QuizQuestion question;
  final bool isBangla;
  final int? selectedIndex;
  final int remaining;
  final int totalSeconds;
  final bool isLast;
  final ValueChanged<int> onSelect;
  final VoidCallback onNext;

  String _t(String en, String bn) => isBangla ? bn : en;

  @override
  Widget build(BuildContext context) {
    final glass = NoorifyGlassTheme(context);
    final options = isBangla ? question.optionsBn : question.optionsEn;
    final isLow = remaining <= 5;
    final timeColor = isLow ? const Color(0xFFE53935) : glass.accent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.timer_outlined, size: 18.r, color: timeColor),
            SizedBox(width: 8.w),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.r),
                child: LinearProgressIndicator(
                  value: totalSeconds == 0 ? 0 : remaining / totalSeconds,
                  minHeight: 8.h,
                  backgroundColor: glass.glassBorder,
                  valueColor: AlwaysStoppedAnimation<Color>(timeColor),
                ),
              ),
            ),
            SizedBox(width: 8.w),
            Text(
              '${remaining}s',
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
                color: isLow ? const Color(0xFFE53935) : glass.textPrimary,
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        NoorifyGlassCard(
          radius: BorderRadius.circular(16.r),
          padding: EdgeInsets.all(16.w),
          child: Text(
            isBangla ? question.questionBn : question.questionEn,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: glass.textPrimary,
              height: 1.35,
            ),
          ),
        ),
        SizedBox(height: 14.h),
        Expanded(
          child: ListView.separated(
            itemCount: options.length,
            separatorBuilder: (_, _) => SizedBox(height: 10.h),
            itemBuilder: (context, i) => QuizOptionTile(
              label: options[i],
              optionIndex: i,
              correctIndex: question.correctIndex,
              selectedIndex: selectedIndex,
              onTap: () => onSelect(i),
            ),
          ),
        ),
        if (selectedIndex != null)
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: glass.accent,
                padding: EdgeInsets.symmetric(vertical: 14.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.r),
                ),
              ),
              onPressed: onNext,
              child: Text(
                isLast ? _t('See Result', 'ফলাফল দেখুন') : _t('Next', 'পরবর্তী'),
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700),
              ),
            ),
          ),
      ],
    );
  }
}
