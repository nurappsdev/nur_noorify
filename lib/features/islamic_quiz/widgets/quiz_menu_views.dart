import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:first_project/features/islamic_quiz/models/quiz_question.dart';
import 'package:first_project/features/islamic_quiz/widgets/quiz_components.dart';
import 'package:first_project/shared/widgets/noorify_glass.dart';

/// Landing menu: "Start" and "Settings".
class QuizHomeView extends StatelessWidget {
  const QuizHomeView({
    super.key,
    required this.isBangla,
    required this.onStart,
    required this.onSettings,
  });

  final bool isBangla;
  final VoidCallback onStart;
  final VoidCallback onSettings;

  String _t(String en, String bn) => isBangla ? bn : en;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        QuizHeader(
          title: _t('Elm Noor', 'ইলম নূর'),
          subtitle: _t(
            'Test your Islamic knowledge',
            'আপনার ইসলামিক জ্ঞান যাচাই করুন',
          ),
        ),
        SizedBox(height: 18.h),
        QuizMenuCard(
          icon: Icons.play_circle_fill_rounded,
          title: _t('Start', 'শুরু করুন'),
          subtitle: _t('Choose a topic and begin', 'একটি টপিক বেছে নিয়ে শুরু করুন'),
          onTap: onStart,
        ),
        SizedBox(height: 12.h),
        QuizMenuCard(
          icon: Icons.settings_rounded,
          title: _t('Settings', 'সেটিংস'),
          subtitle: _t('Quiz preferences', 'কুইজ পছন্দসমূহ'),
          onTap: onSettings,
        ),
      ],
    );
  }
}

/// Topic chooser shown after "Start": one segment card per [QuizTopic].
class QuizTopicsView extends StatelessWidget {
  const QuizTopicsView({
    super.key,
    required this.isBangla,
    required this.onBack,
    required this.onTopic,
  });

  final bool isBangla;
  final VoidCallback onBack;
  final ValueChanged<QuizTopic> onTopic;

  IconData _icon(QuizTopic topic) => switch (topic) {
    QuizTopic.quran => Icons.menu_book_rounded,
    QuizTopic.hadith => Icons.auto_stories_rounded,
    QuizTopic.elmNoor => Icons.lightbulb_rounded,
    QuizTopic.fiqh => Icons.balance_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        QuizHeader(
          title: isBangla ? 'একটি টপিক বেছে নিন' : 'Choose a Topic',
          onBack: onBack,
        ),
        SizedBox(height: 16.h),
        Expanded(
          child: GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12.w,
            mainAxisSpacing: 12.h,
            childAspectRatio: 1.0,
            children: [
              for (final topic in QuizTopic.values)
                QuizTopicCard(
                  icon: _icon(topic),
                  title: topic.label(isBangla),
                  subtitle: topic.subtitle(isBangla),
                  onTap: () => onTopic(topic),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Placeholder settings view reached from the home menu.
class QuizSettingsView extends StatelessWidget {
  const QuizSettingsView({
    super.key,
    required this.isBangla,
    required this.onBack,
  });

  final bool isBangla;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final glass = NoorifyGlassTheme(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        QuizHeader(
          title: isBangla ? 'সেটিংস' : 'Settings',
          onBack: onBack,
        ),
        SizedBox(height: 16.h),
        NoorifyGlassCard(
          radius: BorderRadius.circular(16.r),
          padding: EdgeInsets.all(16.w),
          child: Text(
            isBangla ? 'কুইজ সেটিংস শীঘ্রই আসছে।' : 'Quiz settings coming soon.',
            style: TextStyle(fontSize: 14.sp, color: glass.textSecondary),
          ),
        ),
      ],
    );
  }
}
