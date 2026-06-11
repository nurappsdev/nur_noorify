import 'package:first_project/features/islamic_quiz/models/elm_noor_bank.dart';
import 'package:first_project/features/islamic_quiz/models/fiqh_bank.dart';
import 'package:first_project/features/islamic_quiz/models/hadith_bank.dart';
import 'package:first_project/features/islamic_quiz/models/quiz_question.dart';
import 'package:first_project/features/islamic_quiz/models/quran_bank.dart';

/// Returns the 10-question bank for a given quiz topic.
List<QuizQuestion> questionsForTopic(QuizTopic topic) {
  switch (topic) {
    case QuizTopic.quran:
      return quranBank;
    case QuizTopic.hadith:
      return hadithBank;
    case QuizTopic.elmNoor:
      return elmNoorBank;
    case QuizTopic.fiqh:
      return fiqhBank;
  }
}
