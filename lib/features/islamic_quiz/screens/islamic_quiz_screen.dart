import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import 'package:first_project/features/islamic_quiz/models/quiz_question.dart';
import 'package:first_project/features/islamic_quiz/widgets/quiz_widgets.dart';
import 'package:first_project/shared/providers/language_provider.dart';
import 'package:first_project/shared/services/app_globals.dart';
import 'package:first_project/shared/widgets/noorify_glass.dart';

/// "Elm Noor" — a simple Islamic knowledge quiz with scoring.
class IslamicQuizScreen extends StatefulWidget {
  const IslamicQuizScreen({super.key});

  @override
  State<IslamicQuizScreen> createState() => _IslamicQuizScreenState();
}

class _IslamicQuizScreenState extends State<IslamicQuizScreen> {
  int _index = 0;
  int _score = 0;
  int? _selected;
  bool _finished = false;

  void _select(int option) {
    if (_selected != null) return;
    setState(() {
      _selected = option;
      if (option == kIslamicQuizQuestions[_index].correctIndex) _score++;
    });
  }

  void _next() {
    setState(() {
      if (_index + 1 >= kIslamicQuizQuestions.length) {
        _finished = true;
      } else {
        _index++;
        _selected = null;
      }
    });
  }

  void _restart() {
    setState(() {
      _index = 0;
      _score = 0;
      _selected = null;
      _finished = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isBangla =
        context.watch<LanguageProvider>().current == AppLanguage.bangla;
    final glass = NoorifyGlassTheme(context);

    return Scaffold(
      backgroundColor: glass.bgBottom,
      body: NoorifyGlassBackground(
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(18.w, 14.h, 18.w, 14.h),
            child: _finished
                ? QuizResultView(
                    score: _score,
                    total: kIslamicQuizQuestions.length,
                    isBangla: isBangla,
                    onRestart: _restart,
                  )
                : _buildQuestion(glass, isBangla),
          ),
        ),
      ),
    );
  }

  Widget _buildQuestion(NoorifyGlassTheme glass, bool isBangla) {
    String t(String en, String bn) => isBangla ? bn : en;
    final q = kIslamicQuizQuestions[_index];
    final options = isBangla ? q.optionsBn : q.optionsEn;
    final isLast = _index + 1 >= kIslamicQuizQuestions.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t('Elm Noor', 'ইলম নূর'),
          style: TextStyle(
            fontSize: 22.sp,
            fontWeight: FontWeight.w700,
            color: glass.textPrimary,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          t(
            'Question ${_index + 1} of ${kIslamicQuizQuestions.length}',
            'প্রশ্ন ${_index + 1}/${kIslamicQuizQuestions.length}',
          ),
          style: TextStyle(fontSize: 12.5.sp, color: glass.textSecondary),
        ),
        SizedBox(height: 14.h),
        NoorifyGlassCard(
          radius: BorderRadius.circular(16.r),
          padding: EdgeInsets.all(16.w),
          child: Text(
            isBangla ? q.questionBn : q.questionEn,
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
              correctIndex: q.correctIndex,
              selectedIndex: _selected,
              onTap: () => _select(i),
            ),
          ),
        ),
        if (_selected != null)
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
              onPressed: _next,
              child: Text(
                isLast ? t('See Result', 'ফলাফল দেখুন') : t('Next', 'পরবর্তী'),
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700),
              ),
            ),
          ),
      ],
    );
  }
}
