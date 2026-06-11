import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import 'package:first_project/features/islamic_quiz/models/quiz_banks.dart';
import 'package:first_project/features/islamic_quiz/models/quiz_question.dart';
import 'package:first_project/features/islamic_quiz/widgets/quiz_components.dart';
import 'package:first_project/features/islamic_quiz/widgets/quiz_menu_views.dart';
import 'package:first_project/features/islamic_quiz/widgets/quiz_question_view.dart';
import 'package:first_project/features/islamic_quiz/widgets/quiz_widgets.dart';
import 'package:first_project/shared/providers/language_provider.dart';
import 'package:first_project/shared/services/app_globals.dart';
import 'package:first_project/shared/widgets/noorify_glass.dart';

enum _Stage { home, topics, settings, quiz }

/// Seconds allowed per question; remaining seconds become points on a correct
/// answer (a faster answer scores more).
const int _kSecondsPerQuestion = 30;

/// Sentinel for "time ran out": reveals the answer, credits no option.
const int _kTimedOut = -1;

/// "Elm Noor" — an Islamic knowledge quiz: a home menu (Start / Settings),
/// a topic chooser, and a timed question flow with points.
class IslamicQuizScreen extends StatefulWidget {
  const IslamicQuizScreen({super.key});

  @override
  State<IslamicQuizScreen> createState() => _IslamicQuizScreenState();
}

class _IslamicQuizScreenState extends State<IslamicQuizScreen> {
  _Stage _stage = _Stage.home;
  List<QuizQuestion> _questions = const [];
  int _index = 0;
  int _points = 0;
  int _correct = 0;
  int? _selected;
  int _remaining = _kSecondsPerQuestion;
  bool _finished = false;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _remaining = _kSecondsPerQuestion;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_remaining <= 1) {
          _remaining = 0;
          timer.cancel();
          _selected = _kTimedOut; // reveal the correct answer, award nothing
        } else {
          _remaining--;
        }
      });
    });
  }

  void _startTopic(QuizTopic topic) {
    setState(() {
      _questions = questionsForTopic(topic);
      _index = 0;
      _points = 0;
      _correct = 0;
      _selected = null;
      _finished = false;
      _stage = _Stage.quiz;
    });
    _startTimer();
  }

  void _select(int option) {
    if (_selected != null) return;
    _timer?.cancel();
    setState(() {
      _selected = option;
      if (option == _questions[_index].correctIndex) {
        _correct++;
        _points += _remaining;
      }
    });
  }

  void _next() {
    if (_index + 1 >= _questions.length) {
      _timer?.cancel();
      setState(() => _finished = true);
      return;
    }
    setState(() {
      _index++;
      _selected = null;
    });
    _startTimer();
  }

  void _restart() {
    setState(() {
      _index = 0;
      _points = 0;
      _correct = 0;
      _selected = null;
      _finished = false;
    });
    _startTimer();
  }

  void _leaveQuiz(_Stage to) {
    _timer?.cancel();
    setState(() => _stage = to);
  }

  @override
  Widget build(BuildContext context) {
    final isBangla =
        context.watch<LanguageProvider>().current == AppLanguage.bangla;
    final glass = NoorifyGlassTheme(context);

    final Widget body = switch (_stage) {
      _Stage.home => QuizHomeView(
        isBangla: isBangla,
        onStart: () => setState(() => _stage = _Stage.topics),
        onSettings: () => setState(() => _stage = _Stage.settings),
      ),
      _Stage.topics => QuizTopicsView(
        isBangla: isBangla,
        onBack: () => setState(() => _stage = _Stage.home),
        onTopic: _startTopic,
      ),
      _Stage.settings => QuizSettingsView(
        isBangla: isBangla,
        onBack: () => setState(() => _stage = _Stage.home),
      ),
      _Stage.quiz => _buildQuiz(isBangla),
    };

    return Scaffold(
      backgroundColor: glass.bgBottom,
      body: NoorifyGlassBackground(
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(18.w, 14.h, 18.w, 14.h),
            child: body,
          ),
        ),
      ),
    );
  }

  Widget _buildQuiz(bool isBangla) {
    String t(String en, String bn) => isBangla ? bn : en;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        QuizHeader(
          title: t('Elm Noor', 'ইলম নূর'),
          subtitle: _finished
              ? ''
              : t(
                  'Question ${_index + 1} of ${_questions.length}',
                  'প্রশ্ন ${_index + 1}/${_questions.length}',
                ),
          onBack: () => _leaveQuiz(_Stage.topics),
        ),
        SizedBox(height: 14.h),
        Expanded(
          child: _finished
              ? QuizResultView(
                  points: _points,
                  correct: _correct,
                  total: _questions.length,
                  isBangla: isBangla,
                  onRestart: _restart,
                )
              : QuizQuestionView(
                  question: _questions[_index],
                  isBangla: isBangla,
                  selectedIndex: _selected,
                  remaining: _remaining,
                  totalSeconds: _kSecondsPerQuestion,
                  isLast: _index + 1 >= _questions.length,
                  onSelect: _select,
                  onNext: _next,
                ),
        ),
      ],
    );
  }
}
