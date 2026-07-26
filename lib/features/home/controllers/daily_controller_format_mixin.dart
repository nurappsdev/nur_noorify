part of '../screens/daily_activity_screen.dart';

mixin DailyControllerFormatMixin on State<DailyActivityScreen>, DailyControllerUtilsMixin {
  static const Map<String, List<String>> _hijriMonths = {
    'bn': [
      'মুহাররম',
      'সফর',
      'রবিউল আউয়াল',
      'রবিউস সানি',
      'জমাদিউল আউয়াল',
      'জমাদিউস সানি',
      'রজব',
      'শাবান',
      'রমজান',
      'শাওয়াল',
      'জিলকদ',
      'জিলহজ্জ',
    ],
    'en': [
      'Muharram',
      'Safar',
      'Rabiul Awwal',
      'Rabius Sani',
      'Jamadial Awwal',
      'Jamadias Sani',
      'Rajab',
      'Shaban',
      'Ramadan',
      'Shawwal',
      'Zilkad',
      'Zilhajj',
    ],
    'ar': [
      'محرم',
      'صفر',
      'ربيع الأول',
      'ربيع الآخر',
      'جمادى الأولى',
      'جمادى الآخرة',
      'رجب',
      'شعبان',
      'رمضان',
      'شوال',
      'ذو القعدة',
      'ذو الحجة',
    ],
  };

  /// Localized Hijri month name for [month] (1-12) in the active language.
  String _localizedHijriMonth(int month) {
    final code = _isBangla ? 'bn' : 'en';
    final names = _hijriMonths[code] ?? _hijriMonths['en']!;
    if (month < 1 || month > names.length) return '';
    return names[month - 1];
  }

  String get _formattedTime {
    final hour12 = (_now.hour % 12 == 0) ? 12 : _now.hour % 12;
    final minute = _now.minute.toString().padLeft(2, '0');
    final meridiem = _localizedMeridiem(_now.hour < 12);
    final value = '$hour12:$minute';
    return _isBangla
        ? '${_toBanglaDigits(value)} $meridiem'
        : '$value $meridiem';
  }

  /// Same as [_formattedTime] but with a live, ticking seconds component. The
  /// clock timer rebuilds every second, so the seconds advance in real time.
  String get _formattedTimeWithSeconds {
    final hour12 = (_now.hour % 12 == 0) ? 12 : _now.hour % 12;
    final minute = _now.minute.toString().padLeft(2, '0');
    final second = _now.second.toString().padLeft(2, '0');
    final meridiem = _localizedMeridiem(_now.hour < 12);
    final value = '$hour12:$minute:$second';
    return _isBangla
        ? '${_toBanglaDigits(value)} $meridiem'
        : '$value $meridiem';
  }

  String get _formattedHijriDate {
    final hijri = HijriCalendar.fromDate(_now);
    final day = hijri.hDay.toString();
    final year = hijri.hYear.toString();
    final monthName = _localizedHijriMonth(hijri.hMonth);

    if (_isBangla) {
      return '${_toBanglaDigits(day)} $monthName ${_toBanglaDigits(year)} \u09b9\u09bf\u099c\u09b0\u09bf';
    }
    return '$day $monthName $year H';
  }

  String get _formattedBanglaDate {
    return Ponjika.format(date: _now, format: 'DD MM YY');
  }

  static const List<String> _gregorianMonthsEn = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  static const List<String> _gregorianMonthsBn = [
    'জানুয়ারি',
    'ফেব্রুয়ারি',
    'মার্চ',
    'এপ্রিল',
    'মে',
    'জুন',
    'জুলাই',
    'আগস্ট',
    'সেপ্টেম্বর',
    'অক্টোবর',
    'নভেম্বর',
    'ডিসেম্বর',
  ];

  String get _formattedBritishDate {
    final months = _isBangla ? _gregorianMonthsBn : _gregorianMonthsEn;
    final day = _now.day.toString().padLeft(2, '0');
    final monthName = months[_now.month - 1];
    if (_isBangla) {
      return '${_toBanglaDigits(day)} $monthName ${_toBanglaDigits(_now.year.toString())}';
    }
    return '$day $monthName ${_now.year}';
  }

  List<String> get _headerDateVariants {
    final banglaLabel = _isBangla ? '\u09ac\u09be\u0982\u09b2\u09be' : 'Bangla';
    final hijriLabel = _isBangla ? '\u0986\u09b0\u09ac\u09bf' : 'Hijri';
    final britishLabel = _isBangla
        ? '\u0987\u0982\u09b0\u09c7\u099c\u09bf'
        : 'English (UK)';
    return [
      '$banglaLabel: $_formattedBanglaDate',
      '$hijriLabel: $_formattedHijriDate',
      '$britishLabel: $_formattedBritishDate',
    ];
  }

  String get _activeHeaderDate {
    final variants = _headerDateVariants;
    final index = (_now.millisecondsSinceEpoch ~/ 5000) % variants.length;
    return variants[index];
  }

}
