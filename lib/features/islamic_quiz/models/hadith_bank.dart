import 'package:first_project/features/islamic_quiz/models/quiz_question.dart';

/// Hadith-themed questions for the "Hadith Topic".
const List<QuizQuestion> hadithBank = <QuizQuestion>[
  QuizQuestion(
    questionEn: 'Which book is the most authentic hadith collection?',
    questionBn: 'কোন গ্রন্থটি সবচেয়ে বিশুদ্ধ হাদিস সংকলন?',
    optionsEn: ['Sahih al-Bukhari', 'Sunan Abu Dawud', 'Muwatta', 'Ibn Majah'],
    optionsBn: ['সহিহ বুখারি', 'সুনান আবু দাউদ', 'মুয়াত্তা', 'ইবনে মাজাহ'],
    correctIndex: 0,
  ),
  QuizQuestion(
    questionEn: 'A hadith records the sayings and actions of whom?',
    questionBn: 'হাদিস কার কথা ও কাজের বর্ণনা?',
    optionsEn: [
      'The Prophet (SAW)',
      'The Caliphs',
      'The Imams',
      'The Companions',
    ],
    optionsBn: ['নবী (সাঃ)', 'খলিফাগণ', 'ইমামগণ', 'সাহাবিগণ'],
    correctIndex: 0,
  ),
  QuizQuestion(
    questionEn: 'Who compiled Sahih Muslim?',
    questionBn: 'সহিহ মুসলিম কে সংকলন করেন?',
    optionsEn: ['Imam Muslim', 'Imam Bukhari', 'Imam Tirmidhi', 'Imam Nasai'],
    optionsBn: ['ইমাম মুসলিম', 'ইমাম বুখারি', 'ইমাম তিরমিজি', 'ইমাম নাসাই'],
    correctIndex: 0,
  ),
  QuizQuestion(
    questionEn: 'The six major hadith books are collectively called?',
    questionBn: 'ছয়টি প্রধান হাদিস গ্রন্থকে একত্রে কী বলা হয়?',
    optionsEn: ['Kutub al-Sittah', 'Sahihayn', 'Musnad', 'Sunan'],
    optionsBn: ['কুতুবুস সিত্তাহ', 'সহিহাইন', 'মুসনাদ', 'সুনান'],
    correctIndex: 0,
  ),
  QuizQuestion(
    questionEn: 'Who compiled Sahih al-Bukhari?',
    questionBn: 'সহিহ বুখারি কে সংকলন করেন?',
    optionsEn: ['Imam Bukhari', 'Imam Muslim', 'Imam Malik', 'Imam Ahmad'],
    optionsBn: ['ইমাম বুখারি', 'ইমাম মুসলিম', 'ইমাম মালিক', 'ইমাম আহমদ'],
    correctIndex: 0,
  ),
  QuizQuestion(
    questionEn: 'A hadith with a sound, unbroken chain is classified as?',
    questionBn: 'নির্ভরযোগ্য ও অবিচ্ছিন্ন সনদের হাদিসকে কী বলা হয়?',
    optionsEn: ['Sahih', "Da'if", 'Mawdu', 'Hasan'],
    optionsBn: ['সহিহ', 'দুর্বল', 'জাল', 'হাসান'],
    correctIndex: 0,
  ),
  QuizQuestion(
    questionEn: 'The chain of narrators of a hadith is called?',
    questionBn: 'হাদিসের বর্ণনাকারীদের ধারাকে কী বলা হয়?',
    optionsEn: ['Isnad (Sanad)', 'Matn', 'Surah', 'Ayah'],
    optionsBn: ['সনদ', 'মতন', 'সূরা', 'আয়াত'],
    correctIndex: 0,
  ),
  QuizQuestion(
    questionEn: 'The text or content of a hadith is called?',
    questionBn: 'হাদিসের মূল পাঠ বা বিষয়বস্তুকে কী বলা হয়?',
    optionsEn: ['Matn', 'Sanad', 'Isnad', 'Rawi'],
    optionsBn: ['মতন', 'সনদ', 'ইসনাদ', 'রাবি'],
    correctIndex: 0,
  ),
  QuizQuestion(
    questionEn: 'A fabricated or false hadith is called?',
    questionBn: 'বানোয়াট বা জাল হাদিসকে কী বলা হয়?',
    optionsEn: ['Mawdu', 'Sahih', 'Hasan', 'Mutawatir'],
    optionsBn: ['মাওদু (জাল)', 'সহিহ', 'হাসান', 'মুতাওয়াতির'],
    correctIndex: 0,
  ),
  QuizQuestion(
    questionEn: 'Which companion narrated the most hadith?',
    questionBn: 'সর্বাধিক হাদিস বর্ণনা করেছেন কোন সাহাবি?',
    optionsEn: [
      'Abu Hurairah (RA)',
      'Abu Bakr (RA)',
      'Umar (RA)',
      'Ali (RA)',
    ],
    optionsBn: ['আবু হুরায়রা (রাঃ)', 'আবু বকর (রাঃ)', 'উমর (রাঃ)', 'আলি (রাঃ)'],
    correctIndex: 0,
  ),
];
