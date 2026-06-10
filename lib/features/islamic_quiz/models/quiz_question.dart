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

/// Built-in question bank for the "Elm Noor" Islamic quiz.
const List<QuizQuestion> kIslamicQuizQuestions = <QuizQuestion>[
  QuizQuestion(
    questionEn: 'How many times do Muslims pray each day?',
    questionBn: 'মুসলিমরা প্রতিদিন কতবার নামাজ পড়ে?',
    optionsEn: ['Three', 'Five', 'Seven', 'Two'],
    optionsBn: ['তিনবার', 'পাঁচবার', 'সাতবার', 'দুইবার'],
    correctIndex: 1,
  ),
  QuizQuestion(
    questionEn: 'In which month do Muslims fast?',
    questionBn: 'মুসলিমরা কোন মাসে রোজা রাখে?',
    optionsEn: ['Shawwal', 'Ramadan', 'Rajab', 'Muharram'],
    optionsBn: ['শাওয়াল', 'রমজান', 'রজব', 'মুহার্রম'],
    correctIndex: 1,
  ),
  QuizQuestion(
    questionEn: 'How many pillars of Islam are there?',
    questionBn: 'ইসলামের স্তম্ভ কয়টি?',
    optionsEn: ['Four', 'Five', 'Six', 'Three'],
    optionsBn: ['চার', 'পাঁচ', 'ছয়', 'তিন'],
    correctIndex: 1,
  ),
  QuizQuestion(
    questionEn: 'What is the holy book of Islam?',
    questionBn: 'ইসলামের পবিত্র গ্রন্থ কোনটি?',
    optionsEn: ['Torah', 'Injil', 'Quran', 'Zabur'],
    optionsBn: ['তাওরাত', 'ইঞ্জিল', 'কুরআন', 'যাবূর'],
    correctIndex: 2,
  ),
  QuizQuestion(
    questionEn: 'Which direction do Muslims face during prayer?',
    questionBn: 'নামাজে মুসলিমরা কোন দিকে মুখ করে?',
    optionsEn: ['North', 'Kaaba (Qibla)', 'East', 'Jerusalem'],
    optionsBn: ['উত্তর', 'কাবা (কিবলা)', 'পূর্ব', 'জেরুজালেম'],
    correctIndex: 1,
  ),
  QuizQuestion(
    questionEn: 'What is the first month of the Islamic calendar?',
    questionBn: 'ইসলামি বর্ষপঞ্জিকার প্রথম মাস কোনটি?',
    optionsEn: ['Ramadan', 'Muharram', 'Safar', 'Rajab'],
    optionsBn: ['রমজান', 'মুহার্রম', 'সফর', 'রজব'],
    correctIndex: 1,
  ),
  QuizQuestion(
    questionEn: 'How many rakats are in the Fajr fard prayer?',
    questionBn: 'ফজরের ফরজ নামাজ কয় রাকাত?',
    optionsEn: ['Two', 'Three', 'Four', 'Five'],
    optionsBn: ['দুই', 'তিন', 'চার', 'পাঁচ'],
    correctIndex: 0,
  ),
  QuizQuestion(
    questionEn: 'Who is the last Prophet in Islam?',
    questionBn: 'ইসলামের শেষ নবী কে?',
    optionsEn: ['Isa (AS)', 'Musa (AS)', 'Muhammad (SAW)', 'Ibrahim (AS)'],
    optionsBn: ['ঈসা (আঃ)', 'মূসা (আঃ)', 'মুহাম্মদ (সাঃ)', 'ইব্রাহিম (আঃ)'],
    correctIndex: 2,
  ),
];
