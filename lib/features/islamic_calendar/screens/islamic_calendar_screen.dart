import 'dart:async';
import 'dart:convert';

import 'package:adhan_dart/adhan_dart.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:ponjika/ponjika.dart';

import 'package:first_project/core/constants/route_names.dart';
import 'package:first_project/features/islamic_calendar/services/google_calendar_events_service.dart';
import 'package:first_project/shared/services/app_globals.dart';
import 'package:first_project/shared/widgets/bottom_nav.dart';
import 'package:first_project/shared/widgets/noorify_glass.dart';

class IslamicCalendarScreen extends StatefulWidget {
  const IslamicCalendarScreen({super.key});

  @override
  State<IslamicCalendarScreen> createState() => _IslamicCalendarScreenState();
}

class _IslamicCalendarScreenState extends State<IslamicCalendarScreen> {
  static const _dhakaLat = 23.8103;
  static const _dhakaLng = 90.4125;

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

  static const _weekdaysEn = <String>[
    'Sun',
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
  ];
  static const _weekdaysBn = <String>[
    'শনি',
    'রবি',
    'সোম',
    'মঙ্গল',
    'বুধ',
    'বৃহঃ',
    'শুক্র',
  ];

  DateTime _selectedDate = DateTime.now();
  DateTime _displayedMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    1,
  );

  final Dio _calendarApi = Dio(
    BaseOptions(
      baseUrl: 'https://api.aladhan.com/v1',
      connectTimeout: const Duration(seconds: 12),
      receiveTimeout: const Duration(seconds: 12),
      sendTimeout: const Duration(seconds: 12),
      responseType: ResponseType.json,
    ),
  );

  final GoogleCalendarEventsService _googleCalendarEventsService =
      GoogleCalendarEventsService();

  Map<int, List<String>> _apiEventsByDay = const {};
  Map<int, List<String>> _googleEventsByDay = const {};
  bool _eventsLoading = false;
  final ScrollController _importantEventsController = ScrollController();
  Timer? _importantEventsAutoScrollTimer;
  int _importantEventsScrollDirection = 1;

  bool get _isBangla => appLanguageNotifier.value == AppLanguage.bangla;

  bool _looksMojibake(String value) {
    for (final unit in value.codeUnits) {
      if (unit == 0x00C3 ||
          unit == 0x00C2 ||
          unit == 0x00E0 ||
          unit == 0x00D8 ||
          unit == 0x00D9 ||
          unit == 0x00D0 ||
          unit == 0x00E2) {
        return true;
      }
    }
    return false;
  }

  String _repairMojibake(String value) {
    var output = value;
    for (var i = 0; i < 4; i++) {
      if (!_looksMojibake(output)) break;
      try {
        output = utf8.decode(latin1.encode(output));
      } catch (_) {
        break;
      }
    }
    return output;
  }

  bool _containsBangla(String value) {
    return RegExp(r'[\u0980-\u09FF]').hasMatch(value);
  }

  String _bn(String value, {required String fallback}) {
    final repaired = _repairMojibake(value);
    if (_containsBangla(repaired) && !_looksMojibake(repaired)) {
      return repaired;
    }
    return fallback;
  }

  String _text(String en, String bn) => _isBangla ? _bn(bn, fallback: en) : en;

  @override
  void initState() {
    super.initState();
    appLanguageNotifier.addListener(_onLanguageChanged);
    _restartImportantEventsAutoScroll();
    unawaited(_loadMonthEvents());
  }

  @override
  void dispose() {
    appLanguageNotifier.removeListener(_onLanguageChanged);
    _importantEventsAutoScrollTimer?.cancel();
    _importantEventsController.dispose();
    super.dispose();
  }

  void _onLanguageChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _changeMonth(int delta) {
    setState(() {
      _displayedMonth = DateTime(
        _displayedMonth.year,
        _displayedMonth.month + delta,
        1,
      );
      if (_selectedDate.year != _displayedMonth.year ||
          _selectedDate.month != _displayedMonth.month) {
        _selectedDate = DateTime(
          _displayedMonth.year,
          _displayedMonth.month,
          1,
        );
      }
    });
    _resetImportantEventsScroll();
    unawaited(_loadMonthEvents());
  }

  void _onSelectDate(DateTime date) {
    setState(() => _selectedDate = date);
    _resetImportantEventsScroll();
    _restartImportantEventsAutoScroll();
  }

  void _resetImportantEventsScroll() {
    if (_importantEventsController.hasClients) {
      _importantEventsController.jumpTo(0);
    }
    _importantEventsScrollDirection = 1;
  }

  void _restartImportantEventsAutoScroll() {
    _importantEventsAutoScrollTimer?.cancel();
    _importantEventsAutoScrollTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _autoScrollImportantEvents(),
    );
  }

  void _autoScrollImportantEvents() {
    if (!mounted || !_importantEventsController.hasClients) return;
    final position = _importantEventsController.position;
    if (position.maxScrollExtent <= 0) return;

    const step = 54.0;
    var target = position.pixels + (step * _importantEventsScrollDirection);
    if (target >= position.maxScrollExtent) {
      target = position.maxScrollExtent;
      _importantEventsScrollDirection = -1;
    } else if (target <= 0) {
      target = 0;
      _importantEventsScrollDirection = 1;
    }

    _importantEventsController.animateTo(
      target,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOut,
    );
  }

  bool _isSameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _isInDisplayedMonth(DateTime date) =>
      date.year == _displayedMonth.year && date.month == _displayedMonth.month;

  String _toBanglaDigits(String input) {
    const latin = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const bangla = [
      '\u09e6',
      '\u09e7',
      '\u09e8',
      '\u09e9',
      '\u09ea',
      '\u09eb',
      '\u09ec',
      '\u09ed',
      '\u09ee',
      '\u09ef',
    ];
    var output = input;
    for (var i = 0; i < latin.length; i++) {
      output = output.replaceAll(latin[i], bangla[i]);
    }
    return output;
  }

  String _digits(String input) => _isBangla ? _toBanglaDigits(input) : input;

  String _gregorianMonth(int month) =>
      _isBangla
      ? _bn(_monthsBn[month - 1], fallback: _monthsEn[month - 1])
      : _monthsEn[month - 1];

  String _weekday(int index) =>
      _isBangla
      ? _bn(_weekdaysBn[index], fallback: _weekdaysEn[index])
      : _weekdaysEn[index];

  String _hijriMonth(String english) {
    if (!_isBangla) return english;
    const map = <String, String>{
      'Muharram': 'মুহাররম',
      'Safar': 'সফর',
      "Rabi' al-awwal": 'রবিউল আউয়াল',
      "Rabi' al-thani": 'রবিউস সানি',
      'Jumada al-awwal': 'জুমাদিউল আউয়াল',
      'Jumada al-thani': 'জুমাদিউস সানি',
      'Rajab': 'রজব',
      "Sha'ban": 'শাবান',
      'Ramadan': 'রমজান',
      'Shawwal': 'শাওয়াল',
      "Dhu al-Qi'dah": 'জিলকদ',
      'Dhu al-Hijjah': 'জিলহজ',
    };
    final bangla = map[english];
    if (bangla == null) return english;
    return _bn(bangla, fallback: english);
  }

  String _formatGregorian(DateTime date) {
    final raw = '${date.day} ${_gregorianMonth(date.month)} ${date.year}';
    return _digits(raw);
  }

  String _formatBanglaDate(DateTime date) {
    final raw = Ponjika.format(date: date, format: 'DD MM YY');
    return _digits(raw);
  }

  String _formatHijri(DateTime date) {
    final h = HijriCalendar.fromDate(date);
    final raw = '${h.hDay} ${_hijriMonth(h.longMonthName)} ${h.hYear}';
    return _isBangla ? '${_digits(raw)} হিজরি' : '${_digits(raw)} AH';
  }

  List<DateTime> _visibleDays() {
    final first = DateTime(_displayedMonth.year, _displayedMonth.month, 1);
    final total = DateUtils.getDaysInMonth(
      _displayedMonth.year,
      _displayedMonth.month,
    );
    final leading = first.weekday % 7;
    final start = first.subtract(Duration(days: leading));
    final trailing = (leading + total) % 7;
    final trailingCount = trailing == 0 ? 0 : (7 - trailing);
    final length = leading + total + trailingCount;
    return List<DateTime>.generate(
      length,
      (index) => start.add(Duration(days: index)),
    );
  }

  List<String> _fallbackMappedIslamicEvents(DateTime date) {
    final h = HijriCalendar.fromDate(date);
    final key = '${h.hMonth}-${h.hDay}';
    final map = <String, List<String>>{
      '1-1': [_text('Islamic New Year', 'ইসলামিক নববর্ষ')],
      '1-10': [_text('Ashura', 'আশুরা')],
      '7-27': [_text('Isra and Miraj', 'শবে মেরাজ')],
      '8-15': [_text('Mid-Shaban', 'শবে বরাত')],
      '9-1': [_text('Start of Ramadan', 'রমজান শুরু')],
      '9-27': [_text('Laylat al-Qadr', 'শবে কদর')],
      '10-1': [_text('Eid al-Fitr', 'ঈদুল ফিতর')],
      '12-9': [_text('Day of Arafah', 'আরাফার দিন')],
      '12-10': [_text('Eid al-Adha', 'ঈদুল আযহা')],
    };
    return map[key] ?? const <String>[];
  }

  List<String> _eventsForDate(DateTime date) {
    if (_isInDisplayedMonth(date)) {
      final google = _googleEventsByDay[date.day] ?? const <String>[];
      final api = _apiEventsByDay[date.day] ?? const <String>[];
      if (google.isNotEmpty || api.isNotEmpty) {
        return <String>{...google, ...api}.toList(growable: false);
      }
    }
    return _fallbackMappedIslamicEvents(date);
  }

  Future<void> _loadMonthEvents() async {
    if (!mounted) return;
    setState(() => _eventsLoading = true);

    var apiMap = <int, List<String>>{};
    var googleMap = <int, List<String>>{};

    try {
      final response = await _calendarApi.get(
        '/calendar/${_displayedMonth.year}/${_displayedMonth.month}',
        queryParameters: {
          'latitude': _dhakaLat,
          'longitude': _dhakaLng,
          'method': 1,
        },
      );
      final root = response.data;
      if (root is! Map) throw const FormatException('Invalid root');
      final data = root['data'];
      if (data is! List) throw const FormatException('Invalid data');

      final map = <int, List<String>>{};
      for (final item in data) {
        if (item is! Map) continue;
        final dateObj = item['date'];
        if (dateObj is! Map) continue;
        final gregorianObj = dateObj['gregorian'];
        final hijriObj = dateObj['hijri'];
        if (gregorianObj is! Map || hijriObj is! Map) continue;

        final day = int.tryParse((gregorianObj['day'] ?? '').toString());
        if (day == null) continue;

        final holidaysRaw = hijriObj['holidays'];
        if (holidaysRaw is! List) continue;

        final cleaned = <String>{
          for (final e in holidaysRaw)
            if (e != null && e.toString().trim().isNotEmpty)
              e.toString().trim(),
        }.toList(growable: false);
        if (cleaned.isNotEmpty) {
          map[day] = cleaned;
        }
      }
      apiMap = map;
    } catch (_) {
      apiMap = const <int, List<String>>{};
    }

    try {
      googleMap = await _googleCalendarEventsService.fetchMonthEvents(
        year: _displayedMonth.year,
        month: _displayedMonth.month,
      );
    } catch (_) {
      googleMap = const <int, List<String>>{};
    }

    if (!mounted) return;
    setState(() {
      _apiEventsByDay = apiMap;
      _googleEventsByDay = googleMap;
      _eventsLoading = false;
    });
    _resetImportantEventsScroll();
    _restartImportantEventsAutoScroll();
  }

  String _eventSourceLabel() {
    if (_eventsLoading) {
      return _text('Syncing events...', 'ইভেন্ট সিঙ্ক হচ্ছে...');
    }
    final hasGoogle = _googleEventsByDay.isNotEmpty;
    final hasApi = _apiEventsByDay.isNotEmpty;
    if (hasGoogle && hasApi) {
      return _text(
        'Events from Google Calendar + API',
        'Google Calendar + API ইভেন্ট',
      );
    }
    if (hasGoogle) {
      return _text(
        'Events from Google Calendar',
        'Google Calendar থেকে ইভেন্ট',
      );
    }
    if (hasApi) {
      return _text('Events from API', 'API থেকে ইভেন্ট');
    }
    return _text('Using offline mapped events', 'অফলাইন ম্যাপ করা ইভেন্ট');
  }

  String _timelineDateLabel(DateTime date) {
    final month = _gregorianMonth(date.month);
    final day = _digits(date.day.toString());
    return '$day $month';
  }

  List<_ImportantEventTimelineItem> _buildNearbyImportantTimeline({
    int dayRadius = 20,
  }) {
    final items = <_ImportantEventTimelineItem>[];
    final start = _selectedDate.subtract(Duration(days: dayRadius));
    final end = _selectedDate.add(Duration(days: dayRadius));

    for (
      var cursor = start;
      !cursor.isAfter(end);
      cursor = cursor.add(const Duration(days: 1))
    ) {
      final events = _eventsForDate(cursor);
      for (final event in events) {
        items.add(
          _ImportantEventTimelineItem(
            date: cursor,
            event: event,
            isSelectedDate: _isSameDate(cursor, _selectedDate),
          ),
        );
      }
    }

    return items;
  }

  PrayerTimes _prayerTimesForDate(DateTime date) {
    final params = CalculationMethodParameters.karachi();
    params.madhab = Madhab.hanafi;
    return PrayerTimes(
      date: DateTime(date.year, date.month, date.day),
      coordinates: Coordinates(_dhakaLat, _dhakaLng),
      calculationParameters: params,
    );
  }

  String _formatTime(DateTime dateTime) {
    final hour12 = (dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12)
        .toString();
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final suffix = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '${_digits('$hour12:$minute')} $suffix';
  }

  String _prayerLabel(String key) {
    switch (key) {
      case 'Fajr':
        return _text('Fajr', '\u09ab\u099c\u09b0');
      case 'Sunrise':
        return _text(
          'Sunrise',
          '\u09b8\u09c2\u09b0\u09cd\u09af\u09cb\u09a6\u09af\u09bc',
        );
      case 'Dhuhr':
        return _text('Dhuhr', '\u09af\u09cb\u09b9\u09b0');
      case 'Asr':
        return _text('Asr', '\u0986\u09b8\u09b0');
      case 'Maghrib':
        return _text('Maghrib', '\u09ae\u09be\u0997\u09b0\u09bf\u09ac');
      case 'Isha':
        return _text('Isha', '\u098f\u09b6\u09be');
      default:
        return key;
    }
  }

  Widget _buildPrayerTimeRow(
    NoorifyGlassTheme glass, {
    required IconData icon,
    required String key,
    required DateTime at,
    required bool highlighted,
  }) {
    final rowColor = highlighted
        ? (glass.isDark ? const Color(0x2038D4C7) : const Color(0x1A1EA8B8))
        : (glass.isDark ? const Color(0x181A3345) : const Color(0x80FFFFFF));

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 9.h),
      decoration: BoxDecoration(
        color: rowColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: highlighted
              ? glass.accent.withValues(alpha: 0.65)
              : glass.glassBorder.withValues(alpha: 0.55),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18.sp, color: glass.accent),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              _prayerLabel(key),
              style: TextStyle(
                color: glass.textPrimary,
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            _formatTime(at.toLocal()),
            style: TextStyle(
              color: glass.textPrimary,
              fontSize: 14.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  double _moonProgress() {
    final day = HijriCalendar.fromDate(_selectedDate).hDay;
    return (day / 30).clamp(0.05, 1.0);
  }

  String _moonPhaseLabel() {
    final day = HijriCalendar.fromDate(_selectedDate).hDay;
    if (day <= 2) {
      return _text('New moon', 'নতুন চাঁদ');
    }
    if (day <= 7) {
      return _text('Waxing crescent', 'বাড়ন্ত চাঁদ');
    }
    if (day <= 14) {
      return _text('First half', 'অর্ধেক চাঁদ');
    }
    if (day == 15) {
      return _text('Full moon', 'পূর্ণিমা');
    }
    if (day <= 22) {
      return _text('Waning moon', 'ক্ষয়িষ্ণু চাঁদ');
    }
    return _text('Last crescent', 'শেষ ক্রিসেন্ট');
  }

  String _monthHeaderTitle() {
    final h = HijriCalendar.fromDate(_displayedMonth);
    final raw = '${_hijriMonth(h.longMonthName)} ${h.hYear}';
    return _isBangla ? '${_digits(raw)} হিজরি' : '${_digits(raw)} AH';
  }

  String _monthHeaderSubtitle() =>
      '${_gregorianMonth(_displayedMonth.month)} ${_digits(_displayedMonth.year.toString())}';

  List<BoxShadow> _softShadow(NoorifyGlassTheme glass) {
    return [
      BoxShadow(
        color: glass.isDark ? const Color(0x1F000000) : const Color(0x120E3853),
        blurRadius: 11,
        offset: const Offset(0, 4),
      ),
    ];
  }

  Widget _buildHeader(NoorifyGlassTheme glass) {
    return NoorifyGlassCard(
      radius: BorderRadius.circular(24.r),
      padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 10.h),
      boxShadow: _softShadow(glass),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                Navigator.of(context).pushReplacementNamed(RouteNames.discover);
              }
            },
            style: IconButton.styleFrom(
              backgroundColor: glass.isDark
                  ? const Color(0x2B1EA8B8)
                  : const Color(0x1A1EA8B8),
              foregroundColor: glass.accent,
            ),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              _text('Hijri Calendar', 'হিজরি ক্যালেন্ডার'),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: glass.textPrimary,
                fontSize: 28.sp,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          IconButton(
            onPressed: () =>
                Navigator.of(context).pushNamed(RouteNames.preferences),
            style: IconButton.styleFrom(
              backgroundColor: glass.isDark
                  ? const Color(0x2B1EA8B8)
                  : const Color(0x1A1EA8B8),
              foregroundColor: glass.accent,
            ),
            icon: const Icon(Icons.settings_rounded),
          ),
          SizedBox(width: 6.w),
          IconButton(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  _text(
                    'Notifications screen coming soon',
                    'নোটিফিকেশন স্ক্রিন শিগগিরই আসছে',
                  ),
                ),
              ),
            ),
            style: IconButton.styleFrom(
              backgroundColor: glass.isDark
                  ? const Color(0x2B1EA8B8)
                  : const Color(0x1A1EA8B8),
              foregroundColor: glass.accent,
            ),
            icon: const Icon(Icons.notifications_none_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildMoonCard(NoorifyGlassTheme glass) {
    final hijri = HijriCalendar.fromDate(_selectedDate);
    final dayLabel = _isBangla
        ? 'আজ ${_digits(hijri.hDay.toString())}তম দিন'
        : 'Day ${_digits(hijri.hDay.toString())}';

    return NoorifyGlassCard(
      radius: BorderRadius.circular(22.r),
      padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 14.h),
      boxShadow: _softShadow(glass),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _hijriMonth(hijri.longMonthName),
                  style: TextStyle(
                    color: glass.textPrimary,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  dayLabel,
                  style: TextStyle(
                    color: glass.textSecondary,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  _moonPhaseLabel(),
                  style: TextStyle(
                    color: glass.accentSoft,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 122.r,
            height: 122.r,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 118.r,
                  height: 118.r,
                  child: CircularProgressIndicator(
                    value: _moonProgress(),
                    strokeWidth: 8,
                    backgroundColor: glass.isDark
                        ? const Color(0x2A9EE7F4)
                        : const Color(0x2A1EA8B8),
                    valueColor: AlwaysStoppedAnimation<Color>(glass.accent),
                  ),
                ),
                Container(
                  width: 92.r,
                  height: 92.r,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: glass.isDark
                          ? const [Color(0xFF435D70), Color(0xFF1A2837)]
                          : const [Color(0xFFF4F9FC), Color(0xFFBED4E0)],
                    ),
                    border: Border.all(
                      color: glass.isDark
                          ? const Color(0x44D4ECF8)
                          : const Color(0x66FFFFFF),
                    ),
                  ),
                  child: Text(
                    _digits(hijri.hDay.toString()),
                    style: TextStyle(
                      color: glass.textPrimary,
                      fontSize: 34.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarCard(
    NoorifyGlassTheme glass,
    DateTime today,
    List<DateTime> visibleDays,
  ) {
    return NoorifyGlassCard(
      radius: BorderRadius.circular(22.r),
      padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 12.h),
      boxShadow: _softShadow(glass),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => _changeMonth(-1),
                icon: Icon(
                  Icons.chevron_left_rounded,
                  color: glass.textPrimary,
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      _monthHeaderTitle(),
                      style: TextStyle(
                        color: glass.textPrimary,
                        fontSize: 24.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      _monthHeaderSubtitle(),
                      style: TextStyle(
                        color: glass.textSecondary,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _changeMonth(1),
                icon: Icon(
                  Icons.chevron_right_rounded,
                  color: glass.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            children: List<Widget>.generate(
              7,
              (i) => Expanded(
                child: Center(
                  child: Text(
                    _weekday(i),
                    style: TextStyle(
                      color: glass.textSecondary,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 8.h),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: visibleDays.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              childAspectRatio: 1.02,
            ),
            itemBuilder: (context, index) {
              final date = visibleDays[index];
              final selected = _isSameDate(date, _selectedDate);
              final isToday = _isSameDate(date, today);
              final inMonth = _isInDisplayedMonth(date);
              final hasEvent = _eventsForDate(date).isNotEmpty;

              return InkWell(
                borderRadius: BorderRadius.circular(12.r),
                onTap: () => _onSelectDate(date),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12.r),
                    gradient: null,
                    color: selected
                        ? (glass.isDark
                              ? const Color(0xFF1F5F6F)
                              : const Color(0xFF85DFE6))
                        : (glass.isDark
                              ? const Color(0x241B3B4E)
                              : const Color(0x66FFFFFF)),
                    border: Border.all(
                      color: isToday
                          ? glass.accent.withValues(alpha: 0.95)
                          : glass.glassBorder.withValues(alpha: 0.7),
                      width: isToday ? 1.5 : 1,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Text(
                          _digits(date.day.toString()),
                          style: TextStyle(
                            color: selected
                                ? (glass.isDark
                                      ? const Color(0xFFE9FBFF)
                                      : const Color(0xFF0B4A52))
                                : (inMonth
                                      ? glass.textPrimary
                                      : glass.textMuted.withValues(
                                          alpha: 0.58,
                                        )),
                            fontSize: 20.sp,
                            fontWeight: selected
                                ? FontWeight.w800
                                : FontWeight.w700,
                          ),
                        ),
                      ),
                      if (hasEvent)
                        Positioned(
                          top: 4.h,
                          right: 4.w,
                          child: Icon(
                            Icons.circle,
                            size: 6.sp,
                            color: selected
                                ? const Color(0xFF0B4A52)
                                : glass.accent,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEventChips(NoorifyGlassTheme glass, List<String> events) {
    if (events.isEmpty) {
      return Padding(
        padding: EdgeInsets.only(top: 10.h),
        child: Text(
          _text(
            'No highlighted event on this date',
            'এই তারিখে উল্লেখযোগ্য ইভেন্ট নেই',
          ),
          style: TextStyle(
            color: glass.textSecondary,
            fontSize: 12.5.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(top: 10.h),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: events
            .take(3)
            .map((event) {
              return Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 10.w,
                  vertical: 8.h,
                ),
                decoration: BoxDecoration(
                  color: glass.isDark
                      ? const Color(0xFF163244)
                      : const Color(0xFFDDF4FA),
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(
                    color: glass.accent.withValues(alpha: 0.55),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.event_available_rounded,
                      size: 14.sp,
                      color: glass.accent,
                    ),
                    SizedBox(width: 6.w),
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: 180.w),
                      child: Text(
                        event,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: glass.textPrimary,
                          fontSize: 12.5.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            })
            .toList(growable: false),
      ),
    );
  }

  Widget _buildPrayerCard(NoorifyGlassTheme glass, PrayerTimes prayers) {
    final now = DateTime.now();
    final selectedIsToday = _isSameDate(_selectedDate, now);
    final rows = <({String key, DateTime at, IconData icon})>[
      (key: 'Fajr', at: prayers.fajr, icon: Icons.wb_twilight_outlined),
      (key: 'Sunrise', at: prayers.sunrise, icon: Icons.wb_sunny_outlined),
      (key: 'Dhuhr', at: prayers.dhuhr, icon: Icons.light_mode_outlined),
      (key: 'Asr', at: prayers.asr, icon: Icons.sunny_snowing),
      (key: 'Maghrib', at: prayers.maghrib, icon: Icons.nights_stay_outlined),
      (key: 'Isha', at: prayers.isha, icon: Icons.dark_mode_outlined),
    ];

    String? nextKey;
    if (selectedIsToday) {
      for (final row in rows) {
        if (row.at.isAfter(now)) {
          nextKey = row.key;
          break;
        }
      }
      nextKey ??= rows.first.key;
    }

    return NoorifyGlassCard(
      radius: BorderRadius.circular(18.r),
      padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 12.h),
      boxShadow: _softShadow(glass),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _text('Prayer Times', 'সালাতের সময়'),
                  style: TextStyle(
                    color: glass.textPrimary,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              TextButton(
                onPressed: () =>
                    Navigator.of(context).pushNamed(RouteNames.prayerTimes),
                child: Text(
                  _text('View all', 'রেফারেন্স দেখুন'),
                  style: TextStyle(
                    color: glass.accent,
                    fontSize: 12.5.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          ...rows.map(
            (row) => _buildPrayerTimeRow(
              glass,
              icon: row.icon,
              key: row.key,
              at: row.at,
              highlighted: row.key == nextKey,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            '${_text('Sehri ends', 'সেহরি শেষ')}: ${_formatTime(prayers.fajr.toLocal())}',
            style: TextStyle(
              color: glass.textSecondary,
              fontSize: 12.2.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            '${_text('Iftar starts', 'ইফতার শুরু')}: ${_formatTime(prayers.maghrib.toLocal())}',
            style: TextStyle(
              color: glass.textSecondary,
              fontSize: 12.2.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImportantEventsCard(
    NoorifyGlassTheme glass,
    List<String> events,
    List<_ImportantEventTimelineItem> timelineItems,
  ) {
    final timelineHeight = MediaQuery.of(context).size.width < 390
        ? 176.0
        : 148.0;
    return NoorifyGlassCard(
      radius: BorderRadius.circular(18.r),
      padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 12.h),
      boxShadow: _softShadow(glass),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _text('Important Events', 'গুরুত্বপূর্ণ তারিখসমূহ'),
            style: TextStyle(
              color: glass.textPrimary,
              fontSize: 16.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 8.h),
          Padding(
            padding: EdgeInsets.only(bottom: 6.h),
            child: Text(
              _eventSourceLabel(),
              style: TextStyle(
                color: glass.textSecondary,
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (events.isEmpty)
            Text(
              _text('No major event today', 'আজ বড় কোনো ইভেন্ট নেই'),
              style: TextStyle(
                color: glass.textSecondary,
                fontSize: 12.5.sp,
                fontWeight: FontWeight.w600,
              ),
            )
          else
            ...events
                .take(4)
                .map(
                  (event) => Padding(
                    padding: EdgeInsets.only(bottom: 9.h),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          size: 14.sp,
                          color: glass.accent,
                        ),
                        SizedBox(width: 7.w),
                        Expanded(
                          child: Text(
                            event,
                            style: TextStyle(
                              color: glass.textPrimary,
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          SizedBox(height: 8.h),
          Text(
            _text('Nearby Events', 'আগে ও পরের ইভেন্ট'),
            style: TextStyle(
              color: glass.textPrimary,
              fontSize: 12.5.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 6.h),
          if (timelineItems.isEmpty)
            Text(
              _text(
                'No nearby events in this range',
                'এই সময়ে কাছাকাছি ইভেন্ট নেই',
              ),
              style: TextStyle(
                color: glass.textSecondary,
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
              ),
            )
          else
            SizedBox(
              height: timelineHeight,
              child: ListView.builder(
                controller: _importantEventsController,
                padding: EdgeInsets.zero,
                itemCount: timelineItems.length,
                itemBuilder: (context, index) {
                  final item = timelineItems[index];
                  return Padding(
                    padding: EdgeInsets.only(bottom: 9.h),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: EdgeInsets.only(top: 2.h),
                          width: 7.r,
                          height: 7.r,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: item.isSelectedDate
                                ? glass.accent
                                : glass.textSecondary.withValues(alpha: 0.7),
                          ),
                        ),
                        SizedBox(width: 7.w),
                        Expanded(
                          child: Text(
                            '${_timelineDateLabel(item.date)} • ${item.event}',
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: item.isSelectedDate
                                  ? glass.textPrimary
                                  : glass.textSecondary,
                              fontSize: 12.7.sp,
                              height: 1.25,
                              fontWeight: item.isSelectedDate
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final glass = NoorifyGlassTheme(context);
    final today = DateTime.now();
    final visibleDays = _visibleDays();
    final selectedEvents = _eventsForDate(_selectedDate);
    final timelineItems = _buildNearbyImportantTimeline();
    final prayerTimes = _prayerTimesForDate(_selectedDate);

    return Scaffold(
      backgroundColor: glass.bgBottom,
      body: NoorifyGlassBackground(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(14.w, 10.h, 14.w, 14.h),
                  children: [
                    _buildHeader(glass),
                    Padding(
                      padding: EdgeInsets.fromLTRB(4.w, 8.h, 4.w, 8.h),
                      child: Text(
                        _text(
                          'Today: ${_formatGregorian(_selectedDate)} • ${_formatHijri(_selectedDate)}',
                          'আজ: ${_formatGregorian(_selectedDate)} • ${_formatHijri(_selectedDate)}',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: glass.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 18.sp,
                        ),
                      ),
                    ),
                    _buildMoonCard(glass),
                    SizedBox(height: 10.h),
                    _buildCalendarCard(glass, today, visibleDays),
                    _buildEventChips(glass, selectedEvents),
                    SizedBox(height: 12.h),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildPrayerCard(glass, prayerTimes),
                        SizedBox(height: 10.h),
                        _buildImportantEventsCard(
                          glass,
                          selectedEvents,
                          timelineItems,
                        ),
                      ],
                    ),
                    SizedBox(height: 10.h),
                    NoorifyGlassCard(
                      radius: BorderRadius.circular(16.r),
                      padding: EdgeInsets.symmetric(
                        horizontal: 14.w,
                        vertical: 10.h,
                      ),
                      boxShadow: _softShadow(glass),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _DateInfoRow(
                            label: _text('Gregorian', 'ইংরেজি'),
                            value: _formatGregorian(_selectedDate),
                          ),
                          SizedBox(height: 6.h),
                          _DateInfoRow(
                            label: _text('Hijri', 'হিজরি'),
                            value: _formatHijri(_selectedDate),
                          ),
                          SizedBox(height: 6.h),
                          _DateInfoRow(
                            label: _text('Bangla', 'বাংলা'),
                            value: _formatBanglaDate(_selectedDate),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              bottomNav(context, 1),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateInfoRow extends StatelessWidget {
  const _DateInfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final glass = NoorifyGlassTheme(context);
    return Row(
      children: [
        SizedBox(
          width: 78.w,
          child: Text(
            label,
            style: TextStyle(
              color: glass.textSecondary,
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: glass.textPrimary,
              fontSize: 13.5.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _ImportantEventTimelineItem {
  const _ImportantEventTimelineItem({
    required this.date,
    required this.event,
    required this.isSelectedDate,
  });

  final DateTime date;
  final String event;
  final bool isSelectedDate;
}
