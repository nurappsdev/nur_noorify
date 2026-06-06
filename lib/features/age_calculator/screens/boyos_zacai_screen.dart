import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:provider/provider.dart';

import 'package:first_project/features/age_calculator/providers/boyos_zacai_provider.dart';
import 'package:first_project/shared/providers/language_provider.dart';

/// "Boyos Zacai" — an age calculator. The user picks a present date and a date
/// of birth, each in either the English (Gregorian) or Arabic (Hijri) calendar,
/// and the screen reports the elapsed age broken down into years, months, days
/// and total minutes. Both dates resolve to an absolute Gregorian [DateTime], so
/// the age is identical regardless of which calendar each was entered in.
/// Everything is computed locally with no network access.
class BoyosZacaiScreen extends StatelessWidget {
  const BoyosZacaiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<BoyosZacaiProvider>(
      create: (_) => BoyosZacaiProvider(),
      child: const _BoyosZacaiView(),
    );
  }
}

class _BoyosZacaiView extends StatefulWidget {
  const _BoyosZacaiView();

  @override
  State<_BoyosZacaiView> createState() => _BoyosZacaiViewState();
}

class _BoyosZacaiViewState extends State<_BoyosZacaiView> {
  static const _monthsEn = <String>[
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

  static const _monthsBn = <String>[
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

  static const _hijriMonthsEn = <String>[
    'Muharram',
    'Safar',
    'Rabi al-Awwal',
    'Rabi al-Thani',
    'Jumada al-Awwal',
    'Jumada al-Thani',
    'Rajab',
    "Sha'ban",
    'Ramadan',
    'Shawwal',
    "Dhu al-Qi'dah",
    'Dhu al-Hijjah',
  ];

  static const _hijriMonthsBn = <String>[
    'মহররম',
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
    'জিলহজ',
  ];

  // Bangla (Bengali) calendar month names — Latin transliteration for the
  // English UI, native script for the Bangla UI.
  static const _banglaMonthsEn = <String>[
    'Boishakh',
    'Joishtho',
    'Asharh',
    'Srabon',
    'Bhadro',
    'Ashwin',
    'Kartik',
    'Ogrohayon',
    'Poush',
    'Magh',
    'Falgun',
    'Choitro',
  ];

  static const _banglaMonthsBn = <String>[
    'বৈশাখ',
    'জ্যৈষ্ঠ',
    'আষাঢ়',
    'শ্রাবণ',
    'ভাদ্র',
    'আশ্বিন',
    'কার্তিক',
    'অগ্রহায়ণ',
    'পৌষ',
    'মাঘ',
    'ফাল্গুন',
    'চৈত্র',
  ];

  BoyosZacaiProvider get _calc => context.read<BoyosZacaiProvider>();

  DateTime get _presentDate => _calc.presentDate;
  DateTime? get _birthDate => _calc.birthDate;
  CalendarType get _presentCalendar => _calc.presentCalendar;
  CalendarType get _birthCalendar => _calc.birthCalendar;

  bool get _isBangla => context.read<LanguageProvider>().isBangla;
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  String _text(String en, String bn) => _isBangla ? bn : en;

  String _digits(String input) {
    if (!_isBangla) return input;
    const bangla = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
    var output = input;
    for (var i = 0; i < 10; i++) {
      output = output.replaceAll(i.toString(), bangla[i]);
    }
    return output;
  }

  String _gregorianMonthName(int month) =>
      (_isBangla ? _monthsBn : _monthsEn)[month - 1];

  String _hijriMonthName(int month) =>
      (_isBangla ? _hijriMonthsBn : _hijriMonthsEn)[month - 1];

  String _banglaMonthName(int month) =>
      (_isBangla ? _banglaMonthsBn : _banglaMonthsEn)[month - 1];

  // ---------------------------------------------------------------------------
  // Bangla (Bengali) calendar conversion
  //
  // The Bangla year begins on Pohela Boishakh = 14 April. The months are sized
  // so they tile the underlying Gregorian span [14 Apr, 14 Apr next year)
  // exactly; in a 366-day span the extra day lands in Falgun. This keeps the
  // conversion a precise day-for-day bijection so [_toBangla] and [_fromBangla]
  // are exact inverses.
  // ---------------------------------------------------------------------------

  List<int> _banglaMonthDays(int startGregYear) {
    final days = <int>[31, 31, 31, 31, 31, 30, 30, 30, 30, 30, 30, 30];
    final spanDays = DateTime(startGregYear + 1, 4, 14)
        .difference(DateTime(startGregYear, 4, 14))
        .inDays;
    if (spanDays == 366) days[10] = 31; // extra day → Falgun
    return days;
  }

  /// Converts an absolute Gregorian [date] to its Bangla calendar parts.
  ({int year, int month, int day}) _toBangla(DateTime date) {
    final g = DateTime(date.year, date.month, date.day);
    final beforeNewYear = g.month < 4 || (g.month == 4 && g.day < 14);
    final startGregYear = beforeNewYear ? g.year - 1 : g.year;
    final monthDays = _banglaMonthDays(startGregYear);
    var offset = g.difference(DateTime(startGregYear, 4, 14)).inDays;
    var monthIndex = 0;
    while (monthIndex < 11 && offset >= monthDays[monthIndex]) {
      offset -= monthDays[monthIndex];
      monthIndex++;
    }
    return (year: startGregYear - 593, month: monthIndex + 1, day: offset + 1);
  }

  /// Inverse of [_toBangla]: the absolute Gregorian date for a Bangla
  /// year/month/day.
  DateTime _fromBangla(int year, int month, int day) {
    final startGregYear = year + 593;
    final monthDays = _banglaMonthDays(startGregYear);
    var offset = day - 1;
    for (var i = 0; i < month - 1; i++) {
      offset += monthDays[i];
    }
    return DateTime(startGregYear, 4, 14).add(Duration(days: offset));
  }

  /// Formats [date] in the requested [calendar]. Hijri dates are derived from
  /// the absolute Gregorian value and suffixed with "AH".
  String _formatDate(DateTime date, CalendarType calendar) {
    if (calendar == CalendarType.hijri) {
      final h = HijriCalendar.fromDate(date);
      return '${_digits(h.hDay.toString())} ${_hijriMonthName(h.hMonth)} '
          '${_digits(h.hYear.toString())} ${_text('AH', 'হিজরি')}';
    }
    if (calendar == CalendarType.bengali) {
      final b = _toBangla(date);
      return '${_digits(b.day.toString())} ${_banglaMonthName(b.month)} '
          '${_digits(b.year.toString())} ${_text('BS', 'বঙ্গাব্দ')}';
    }
    return '${_digits(date.day.toString())} ${_gregorianMonthName(date.month)} '
        '${_digits(date.year.toString())}';
  }

  // ---------------------------------------------------------------------------
  // Theme palette (mirrors the Calendar & Waqt screen)
  // ---------------------------------------------------------------------------

  Color get _bg => _isDark ? const Color(0xFF060C17) : const Color(0xFFF0F7FC);
  Color get _cardBg =>
      _isDark ? const Color(0xFF101C2A) : const Color(0xFFFFFFFF);
  Color get _cellBg =>
      _isDark ? const Color(0xFF16283A) : const Color(0xFFEEF5FA);
  Color get _cardBorder =>
      _isDark ? const Color(0x22D2F4FF) : const Color(0xFFDCE8F1);
  Color get _textPrimary => _isDark ? Colors.white : const Color(0xFF143349);
  Color get _textSecondary =>
      _isDark ? const Color(0xFF9BC1D8) : const Color(0xFF5F7E94);
  Color get _accent => _isDark ? const Color(0xFF1FD5C0) : const Color(0xFF1EA8B8);

  // ---------------------------------------------------------------------------
  // Age computation
  // ---------------------------------------------------------------------------

  /// Returns the calendar difference between [_birthDate] and [_presentDate]
  /// expressed as whole years, months and days, plus the total elapsed minutes.
  ({int years, int months, int days, int totalMinutes})? get _age {
    final birth = _birthDate;
    if (birth == null) return null;
    if (!_presentDate.isAfter(birth)) return null;

    var years = _presentDate.year - birth.year;
    var months = _presentDate.month - birth.month;
    var days = _presentDate.day - birth.day;

    if (days < 0) {
      months -= 1;
      // Days in the month preceding the present date.
      final previousMonth = DateTime(_presentDate.year, _presentDate.month, 0);
      days += previousMonth.day;
    }
    if (months < 0) {
      years -= 1;
      months += 12;
    }

    final totalMinutes = _presentDate.difference(birth).inMinutes;

    return (years: years, months: months, days: days, totalMinutes: totalMinutes);
  }

  // ---------------------------------------------------------------------------
  // Date pickers
  // ---------------------------------------------------------------------------

  Future<void> _pickDate({required bool isBirth}) async {
    final calendar = isBirth ? _birthCalendar : _presentCalendar;
    final initial = isBirth ? (_birthDate ?? DateTime(2000, 1, 1)) : _presentDate;

    final DateTime? picked;
    if (calendar == CalendarType.hijri) {
      picked = await _pickHijriDate(isBirth: isBirth, initial: initial);
    } else if (calendar == CalendarType.bengali) {
      picked = await _pickBanglaDate(isBirth: isBirth, initial: initial);
    } else {
      picked = await showDatePicker(
        context: context,
        initialDate: initial,
        firstDate: DateTime(1900),
        lastDate: DateTime(2100, 12, 31),
        helpText: isBirth
            ? _text('Select date of birth', 'জন্ম তারিখ নির্বাচন করুন')
            : _text('Select present date', 'বর্তমান তারিখ নির্বাচন করুন'),
      );
    }

    if (picked == null) return;
    final result = picked;
    if (isBirth) {
      _calc.setBirthDate(result);
    } else {
      _calc.setPresentDate(result);
    }
  }

  /// A simple Hijri date picker built from three dropdowns. Returns the chosen
  /// date converted to an absolute Gregorian [DateTime].
  Future<DateTime?> _pickHijriDate({
    required bool isBirth,
    required DateTime initial,
  }) {
    final cal = HijriCalendar();
    final start = HijriCalendar.fromDate(initial);
    var year = start.hYear;
    var month = start.hMonth;
    var day = start.hDay;

    // Generous Hijri year span covering the Gregorian 1900–2100 window.
    const minYear = 1318;
    const maxYear = 1525;
    year = year.clamp(minYear, maxYear);

    return showDialog<DateTime>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final daysInMonth = cal.getDaysInMonth(year, month);
            if (day > daysInMonth) day = daysInMonth;

            return AlertDialog(
              backgroundColor: _cardBg,
              title: Text(
                isBirth
                    ? _text('Date of birth (Hijri)', 'জন্ম তারিখ (হিজরি)')
                    : _text('Present date (Hijri)', 'বর্তমান তারিখ (হিজরি)'),
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              content: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: _hijriDropdown<int>(
                      label: _text('Day', 'দিন'),
                      value: day,
                      items: [
                        for (var d = 1; d <= daysInMonth; d++)
                          DropdownMenuItem(
                            value: d,
                            child: Text(
                              _digits(d.toString()),
                              style: TextStyle(color: _textPrimary),
                            ),
                          ),
                      ],
                      onChanged: (v) => setDialogState(() => day = v!),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    flex: 5,
                    child: _hijriDropdown<int>(
                      label: _text('Month', 'মাস'),
                      value: month,
                      items: [
                        for (var m = 1; m <= 12; m++)
                          DropdownMenuItem(
                            value: m,
                            child: Text(
                              _hijriMonthName(m),
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: _textPrimary),
                            ),
                          ),
                      ],
                      onChanged: (v) => setDialogState(() => month = v!),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    flex: 4,
                    child: _hijriDropdown<int>(
                      label: _text('Year', 'বছর'),
                      value: year,
                      items: [
                        for (var y = maxYear; y >= minYear; y--)
                          DropdownMenuItem(
                            value: y,
                            child: Text(
                              _digits(y.toString()),
                              style: TextStyle(color: _textPrimary),
                            ),
                          ),
                      ],
                      onChanged: (v) => setDialogState(() => year = v!),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(
                    _text('Cancel', 'বাতিল'),
                    style: TextStyle(color: _textSecondary),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    final gregorian = cal.hijriToGregorian(year, month, day);
                    Navigator.of(dialogContext).pop(
                      DateTime(gregorian.year, gregorian.month, gregorian.day),
                    );
                  },
                  child: Text(
                    _text('OK', 'ঠিক আছে'),
                    style: TextStyle(
                      color: _accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// A Bangla date picker built from three dropdowns, mirroring
  /// [_pickHijriDate]. Returns the chosen date converted to an absolute
  /// Gregorian [DateTime].
  Future<DateTime?> _pickBanglaDate({
    required bool isBirth,
    required DateTime initial,
  }) {
    final start = _toBangla(initial);
    var year = start.year;
    var month = start.month;
    var day = start.day;

    // Bangla years spanning the Gregorian 1900–2100 window.
    const minYear = 1306;
    const maxYear = 1507;
    year = year.clamp(minYear, maxYear);

    return showDialog<DateTime>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final daysInMonth = _banglaMonthDays(year + 593)[month - 1];
            if (day > daysInMonth) day = daysInMonth;

            return AlertDialog(
              backgroundColor: _cardBg,
              title: Text(
                isBirth
                    ? _text('Date of birth (Bengali)', 'জন্ম তারিখ (বাংলা)')
                    : _text('Present date (Bengali)', 'বর্তমান তারিখ (বাংলা)'),
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              content: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: _hijriDropdown<int>(
                      label: _text('Day', 'দিন'),
                      value: day,
                      items: [
                        for (var d = 1; d <= daysInMonth; d++)
                          DropdownMenuItem(
                            value: d,
                            child: Text(
                              _digits(d.toString()),
                              style: TextStyle(color: _textPrimary),
                            ),
                          ),
                      ],
                      onChanged: (v) => setDialogState(() => day = v!),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    flex: 5,
                    child: _hijriDropdown<int>(
                      label: _text('Month', 'মাস'),
                      value: month,
                      items: [
                        for (var m = 1; m <= 12; m++)
                          DropdownMenuItem(
                            value: m,
                            child: Text(
                              _banglaMonthName(m),
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: _textPrimary),
                            ),
                          ),
                      ],
                      onChanged: (v) => setDialogState(() => month = v!),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    flex: 4,
                    child: _hijriDropdown<int>(
                      label: _text('Year', 'বছর'),
                      value: year,
                      items: [
                        for (var y = maxYear; y >= minYear; y--)
                          DropdownMenuItem(
                            value: y,
                            child: Text(
                              _digits(y.toString()),
                              style: TextStyle(color: _textPrimary),
                            ),
                          ),
                      ],
                      onChanged: (v) => setDialogState(() => year = v!),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(
                    _text('Cancel', 'বাতিল'),
                    style: TextStyle(color: _textSecondary),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(
                      dialogContext,
                    ).pop(_fromBangla(year, month, day));
                  },
                  child: Text(
                    _text('OK', 'ঠিক আছে'),
                    style: TextStyle(
                      color: _accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _hijriDropdown<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: _textSecondary,
            fontSize: 11.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 4.h),
        DropdownButton<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          isExpanded: true,
          underline: Container(height: 1, color: _cardBorder),
          dropdownColor: _cardBg,
          style: TextStyle(color: _textPrimary, fontSize: 14.sp),
          iconEnabledColor: _accent,
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    context.watch<LanguageProvider>();
    context.watch<BoyosZacaiProvider>();
    final age = _age;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: _textPrimary,
        title: Text(
          _text('Boyos Zacai', 'বয়স যাচাই'),
          style: TextStyle(
            color: _textPrimary,
            fontSize: 18.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
          children: [
            _buildDateField(
              label: _text('Present date', 'বর্তমান তারিখ'),
              icon: Icons.today_rounded,
              value: _formatDate(_presentDate, _presentCalendar),
              calendar: _presentCalendar,
              onCalendarChanged: (c) => _calc.setPresentCalendar(c),
              onTap: () => _pickDate(isBirth: false),
            ),
            SizedBox(height: 12.h),
            _buildDateField(
              label: _text('Date of birth', 'জন্ম তারিখ'),
              icon: Icons.cake_rounded,
              value: _birthDate == null
                  ? _text('Tap to select', 'নির্বাচন করতে চাপুন')
                  : _formatDate(_birthDate!, _birthCalendar),
              calendar: _birthCalendar,
              onCalendarChanged: (c) => _calc.setBirthCalendar(c),
              onTap: () => _pickDate(isBirth: true),
              placeholder: _birthDate == null,
            ),
            SizedBox(height: 20.h),
            if (age == null)
              _buildHint()
            else
              _buildResult(age),
          ],
        ),
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required IconData icon,
    required String value,
    required CalendarType calendar,
    required ValueChanged<CalendarType> onCalendarChanged,
    required VoidCallback onTap,
    bool placeholder = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: _cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _textSecondary,
                    fontSize: 11.5.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              _buildCalendarToggle(calendar, onCalendarChanged),
            ],
          ),
          SizedBox(height: 10.h),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(11.r),
              onTap: onTap,
              child: Row(
                children: [
                  Container(
                    width: 40.r,
                    height: 40.r,
                    decoration: BoxDecoration(
                      color: _cellBg,
                      borderRadius: BorderRadius.circular(11.r),
                    ),
                    child: Icon(icon, color: _accent, size: 21.sp),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      value,
                      style: TextStyle(
                        color: placeholder ? _textSecondary : _textPrimary,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.edit_calendar_rounded,
                    color: _textSecondary,
                    size: 18.sp,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarToggle(
    CalendarType selected,
    ValueChanged<CalendarType> onChanged,
  ) {
    Widget segment(CalendarType type, String label) {
      final isActive = selected == type;
      return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(9.r),
          onTap: isActive ? null : () => onChanged(type),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 5.h),
            decoration: BoxDecoration(
              color: isActive ? _accent : Colors.transparent,
              borderRadius: BorderRadius.circular(9.r),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : _textSecondary,
                fontSize: 11.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(2.r),
      decoration: BoxDecoration(
        color: _cellBg,
        borderRadius: BorderRadius.circular(11.r),
        border: Border.all(color: _cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          segment(CalendarType.gregorian, _text('English', 'ইংরেজি')),
          segment(CalendarType.hijri, _text('Arabic', 'আরবি')),
          segment(CalendarType.bengali, _text('Bengali', 'বাংলা')),
        ],
      ),
    );
  }

  Widget _buildHint() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 18.h),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: _cardBorder),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: _textSecondary, size: 20.sp),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              _birthDate != null
                  ? _text(
                      'Date of birth must be before the present date.',
                      'জন্ম তারিখ অবশ্যই বর্তমান তারিখের আগে হতে হবে।',
                    )
                  : _text(
                      'Select a date of birth to calculate the age.',
                      'বয়স গণনা করতে জন্ম তারিখ নির্বাচন করুন।',
                    ),
              style: TextStyle(
                color: _textSecondary,
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResult(({int years, int months, int days, int totalMinutes}) age) {
    final cells = <({String label, String value})>[
      (label: _text('Years', 'বছর'), value: _digits(age.years.toString())),
      (label: _text('Months', 'মাস'), value: _digits(age.months.toString())),
      (label: _text('Days', 'দিন'), value: _digits(age.days.toString())),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _text('Calculated Age', 'গণনাকৃত বয়স'),
          style: TextStyle(
            color: _textPrimary,
            fontSize: 15.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 12.h),
        Row(
          children: [
            for (var i = 0; i < cells.length; i++) ...[
              Expanded(
                child: _buildStatCell(cells[i].value, cells[i].label),
              ),
              if (i != cells.length - 1) SizedBox(width: 10.w),
            ],
          ],
        ),
        SizedBox(height: 10.h),
        _buildMinutesCell(_digits(age.totalMinutes.toString())),
      ],
    );
  }

  Widget _buildStatCell(String value, String label) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 8.w),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: _cardBorder),
      ),
      child: Column(
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _accent,
              fontSize: 24.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            label,
            style: TextStyle(
              color: _textSecondary,
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMinutesCell(String value) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isDark
              ? const [Color(0xFF13404B), Color(0xFF0F2F3A)]
              : const [Color(0xFFE3F4F7), Color(0xFFD3ECF1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: _cardBorder),
      ),
      child: Row(
        children: [
          Icon(Icons.timer_outlined, color: _accent, size: 22.sp),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              _text('Total Minutes', 'মোট মিনিট'),
              style: TextStyle(
                color: _textSecondary,
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: _textPrimary,
              fontSize: 18.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
