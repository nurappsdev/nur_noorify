/// A single Islamic-quiz question with English/Bangla text and answer options.
class QuizQuestion {
  const QuizQuestion({
    required this.questionEn,
    required this.questionBn,
    required this.optionsEn,
    required this.optionsBn,
    required this.correctIndex,
  });

  final String questionEn;
  final String questionBn;
  final List<String> optionsEn;
  final List<String> optionsBn;
  final int correctIndex;
}

/// Quiz segments shown after the user taps "Start".
enum QuizTopic { quran, hadith, elmNoor, fiqh }

extension QuizTopicLabels on QuizTopic {
  String label(bool isBangla) {
    switch (this) {
      case QuizTopic.quran:
        return isBangla ? 'কুরআন টপিক' : 'Quran Topic';
      case QuizTopic.hadith:
        return isBangla ? 'হাদিস টপিক' : 'Hadith Topic';
      case QuizTopic.elmNoor:
        return isBangla ? 'ইলম নূর' : 'Elm Noor';
      case QuizTopic.fiqh:
        return isBangla ? 'ফিকহ ও মাসআলা' : 'Fiqh and Masala';
    }
  }

  String subtitle(bool isBangla) {
    switch (this) {
      case QuizTopic.quran:
        return isBangla
            ? 'কুরআন সম্পর্কিত প্রশ্ন'
            : 'Questions about the Quran';
      case QuizTopic.hadith:
        return isBangla
            ? 'হাদিস সম্পর্কিত প্রশ্ন'
            : 'Questions about the Hadith';
      case QuizTopic.elmNoor:
        return isBangla
            ? 'সাধারণ ইসলামিক জ্ঞান'
            : 'General Islamic knowledge';
      case QuizTopic.fiqh:
        return isBangla
            ? 'ফিকহ ও মাসআলা সম্পর্কিত প্রশ্ন'
            : 'Questions on fiqh and rulings';
    }
  }
}
