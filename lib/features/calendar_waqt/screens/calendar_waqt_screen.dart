import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:ponjika/ponjika.dart';

import 'package:first_project/shared/services/app_globals.dart';

/// A month-at-a-glance "Calendar & Waqt" screen. For every day of the selected
/// month it lists the five daily prayers plus sunrise/sunset, sahri/iftar, and
/// the three forbidden (Sunnah/Nafl) prayer windows.
///
/// Prayer times are computed entirely offline with [PrayerTimes] (University of
/// Islamic Sciences, Karachi method + Hanafi madhab) so the whole month renders
/// without any network call. Coordinates default to Baitul Mukarram (Dhaka) but
/// the caller can pass the home screen's resolved location.
class CalendarWaqtScreen extends StatefulWidget {
  const CalendarWaqtScreen({
    super.key,
    this.latitude,
    this.longitude,
    this.locationLabel,
  });

  /// Resolved latitude from the caller; falls back to Baitul Mukarram.
  final double? latitude;

  /// Resolved longitude from the caller; falls back to Baitul Mukarram.
  final double? longitude;

  /// Human-readable location label shown under the title.
  final String? locationLabel;

  @override
  State<CalendarWaqtScreen> createState() => _CalendarWaqtScreenState();
}

class _CalendarWaqtScreenState extends State<CalendarWaqtScreen> {
  static const _baitulMukarramLat = 23.7286;
  static const _baitulMukarramLng = 90.4106;

  // Forbidden window widths, mirrored from the home forbidden-times card.
  static const Duration _sunriseWindow = Duration(minutes: 15);
  static const Duration _zawalWindow = Duration(minutes: 2);
  static const Duration _sunsetWindow = Duration(minutes: 14);

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

  // DateTime.weekday is 1=Mon..7=Sun.
  static const _weekdaysEn = <String>[
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  static const _weekdaysBn = <String>[
    'সোমবার',
    'মঙ্গলবার',
    'বুধবার',
    'বৃহস্পতিবার',
    'শুক্রবার',
    'শনিবার',
    'রবিবার',
  ];

  late int _selectedMonth;
  late int _selectedYear;

  bool get _isBangla => appLanguageNotifier.value == AppLanguage.bangla;
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = now.month;
    _selectedYear = now.year;
    appLanguageNotifier.addListener(_onLanguageChanged);
  }

  @override
  void dispose() {
    appLanguageNotifier.removeListener(_onLanguageChanged);
    super.dispose();
  }

  void _onLanguageChanged() {
    if (mounted) setState(() {});
  }

  // ---------------------------------------------------------------------------
  // Localization helpers
  // ---------------------------------------------------------------------------

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

  String _monthName(int month) =>
      (_isBangla ? _monthsBn : _monthsEn)[month - 1];

  String _weekdayName(DateTime date) =>
      (_isBangla ? _weekdaysBn : _weekdaysEn)[date.weekday - 1];

  /// Compact 12-hour clock, e.g. `03:41` — no meridiem, matching the design.
  String _clock(DateTime t) {
    final h12 = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final hh = h12.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    return _digits('$hh:$mm');
  }

  String _clockRange(DateTime start, DateTime end) =>
      '${_clock(start)} - ${_clock(end)}';

  // ---------------------------------------------------------------------------
  // Prayer-time computation (offline)
  // ---------------------------------------------------------------------------

  PrayerTimes _prayerTimesForDate(DateTime date) {
    final params = CalculationMethodParameters.karachi();
    params.madhab = Madhab.hanafi;
    return PrayerTimes(
      date: DateTime(date.year, date.month, date.day),
      coordinates: Coordinates(
        widget.latitude ?? _baitulMukarramLat,
        widget.longitude ?? _baitulMukarramLng,
      ),
      calculationParameters: params,
    );
  }

  int _daysInMonth(int year, int month) =>
      DateTime(year, month + 1, 0).day;

  // ---------------------------------------------------------------------------
  // Theme palette
  // ---------------------------------------------------------------------------

  Color get _bg => _isDark ? const Color(0xFF060C17) : const Color(0xFFF0F7FC);
  Color get _cardBg =>
      _isDark ? const Color(0xFF101C2A) : const Color(0xFFFFFFFF);
  Color get _cellBg =>
      _isDark ? const Color(0xFF16283A) : const Color(0xFFEEF5FA);
  Color get _cardBorder =>
      _isDark ? const Color(0x22D2F4FF) : const Color(0xFFDCE8F1);
  Color get _textPrimary =>
      _isDark ? Colors.white : const Color(0xFF143349);
  Color get _textSecondary =>
      _isDark ? const Color(0xFF9BC1D8) : const Color(0xFF5F7E94);
  Color get _greenStart => const Color(0xFF1EA67E);
  Color get _greenEnd => const Color(0xFF14805F);
  Color get _forbiddenStart =>
      _isDark ? const Color(0xFF3A2422) : const Color(0xFF6E3B33);
  Color get _forbiddenEnd =>
      _isDark ? const Color(0xFF2A1A18) : const Color(0xFF5A2F29);

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dayCount = _daysInMonth(_selectedYear, _selectedMonth);

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: _textPrimary,
        title: Text(
          _text('Calendar & Waqt', 'ক্যালেন্ডার'),
          style: TextStyle(
            color: _textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildSelectors(),
            if ((widget.locationLabel ?? '').trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: _textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        widget.locationLabel!.trim(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 20),
                itemCount: dayCount,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final date = DateTime(
                    _selectedYear,
                    _selectedMonth,
                    index + 1,
                  );
                  final isToday =
                      date.year == now.year &&
                      date.month == now.month &&
                      date.day == now.day;
                  return _buildDayCard(date, isToday: isToday);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectors() {
    final years = <int>[
      for (var y = _selectedYear - 5; y <= _selectedYear + 5; y++) y,
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: _dropdownShell(
              child: DropdownButton<int>(
                value: _selectedMonth,
                isExpanded: true,
                underline: const SizedBox.shrink(),
                dropdownColor: _cardBg,
                iconEnabledColor: _textSecondary,
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
                items: [
                  for (var m = 1; m <= 12; m++)
                    DropdownMenuItem<int>(
                      value: m,
                      child: Text(_monthName(m)),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _selectedMonth = value);
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _dropdownShell(
              child: DropdownButton<int>(
                value: _selectedYear,
                isExpanded: true,
                underline: const SizedBox.shrink(),
                dropdownColor: _cardBg,
                iconEnabledColor: _textSecondary,
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
                items: [
                  for (final y in years)
                    DropdownMenuItem<int>(
                      value: y,
                      child: Text(_digits(y.toString())),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _selectedYear = value);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dropdownShell({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _cardBorder),
      ),
      child: child,
    );
  }

  Widget _buildDayCard(DateTime date, {required bool isToday}) {
    final prayers = _prayerTimesForDate(date);
    final fajr = prayers.fajr.toLocal();
    final sunrise = prayers.sunrise.toLocal();
    final dhuhr = prayers.dhuhr.toLocal();
    final asr = prayers.asr.toLocal();
    final maghrib = prayers.maghrib.toLocal();
    final isha = prayers.isha.toLocal();

    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _cardBorder),
        boxShadow: [
          BoxShadow(
            color: _isDark
                ? const Color(0x40000000)
                : const Color(0x1A0E3853),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDayHeader(date, isToday: isToday),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPrayerGrid(
                  fajr: fajr,
                  dhuhr: dhuhr,
                  asr: asr,
                  maghrib: maghrib,
                  isha: isha,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildPairCell(
                        leftLabel: _text('Sunrise', 'সূর্যোদয়'),
                        leftValue: _clock(sunrise),
                        rightLabel: _text('Sunset', 'সূর্যাস্ত'),
                        rightValue: _clock(maghrib),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildPairCell(
                        leftLabel: _text('Sahri', 'সাহরি'),
                        leftValue: _clock(fajr),
                        rightLabel: _text('Iftar', 'ইফতার'),
                        rightValue: _clock(maghrib),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildForbiddenTimes(
                  sunrise: sunrise,
                  dhuhr: dhuhr,
                  maghrib: maghrib,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayHeader(DateTime date, {required bool isToday}) {
    final hijri = HijriCalendar.fromDate(date);
    final hijriMonth = _hijriMonthName(hijri.hMonth);
    final hijriLine =
        '${_digits(hijri.hDay.toString())} $hijriMonth '
        '${_digits(hijri.hYear.toString())} ${_text('AH', 'হিজরি')}';
    final banglaLine = Ponjika.format(date: date, format: 'DD MM YY');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_greenStart, _greenEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${_digits('${date.day}')} ${_monthName(date.month)}, '
                  '${_digits(date.year.toString())} • ${_weekdayName(date)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (isToday)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _text('Today', 'আজ'),
                    style: TextStyle(
                      color: _greenEnd,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '$hijriLine • $banglaLine',
            style: const TextStyle(
              color: Color(0xFFE6F6EF),
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrayerGrid({
    required DateTime fajr,
    required DateTime dhuhr,
    required DateTime asr,
    required DateTime maghrib,
    required DateTime isha,
  }) {
    final cells = <({String label, DateTime at})>[
      (label: _text('Fajr', 'ফজর'), at: fajr),
      (label: _text('Dhuhr', 'যুহর'), at: dhuhr),
      (label: _text('Asr', 'আসর'), at: asr),
      (label: _text('Maghrib', 'মাগরিব'), at: maghrib),
      (label: _text('Isha', 'ইশা'), at: isha),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: _cellBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          for (final cell in cells)
            Expanded(
              child: Column(
                children: [
                  Text(
                    cell.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _clock(cell.at),
                    style: TextStyle(
                      color: _textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPairCell({
    required String leftLabel,
    required String leftValue,
    required String rightLabel,
    required String rightValue,
  }) {
    Widget item(String label, String value) => Expanded(
      child: Column(
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _textSecondary,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              color: _textPrimary,
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 6),
      decoration: BoxDecoration(
        color: _cellBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          item(leftLabel, leftValue),
          item(rightLabel, rightValue),
        ],
      ),
    );
  }

  Widget _buildForbiddenTimes({
    required DateTime sunrise,
    required DateTime dhuhr,
    required DateTime maghrib,
  }) {
    final periods = <({String label, DateTime start, DateTime end})>[
      (
        label: _text('Morning', 'সকাল'),
        start: sunrise,
        end: sunrise.add(_sunriseWindow),
      ),
      (
        label: _text('Noon', 'দুপুর'),
        start: dhuhr.subtract(_zawalWindow),
        end: dhuhr,
      ),
      (
        label: _text('Evening', 'সন্ধ্যা'),
        start: maghrib.subtract(_sunsetWindow),
        end: maghrib,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _text('Forbidden Prayer Times', 'সালাতের নিষিদ্ধ সময়'),
          style: TextStyle(
            color: _textPrimary,
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (var i = 0; i < periods.length; i++) ...[
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 9,
                    horizontal: 4,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_forbiddenStart, _forbiddenEnd],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        periods[i].label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFF3D9D2),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _clockRange(periods[i].start, periods[i].end),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (i != periods.length - 1) const SizedBox(width: 8),
            ],
          ],
        ),
      ],
    );
  }

  static const Map<int, String> _hijriMonthsEn = {
    1: 'Muharram',
    2: 'Safar',
    3: 'Rabiul Awwal',
    4: 'Rabius Sani',
    5: 'Jamadial Awwal',
    6: 'Jamadias Sani',
    7: 'Rajab',
    8: 'Shaban',
    9: 'Ramadan',
    10: 'Shawwal',
    11: 'Zilkad',
    12: 'Zilhajj',
  };

  static const Map<int, String> _hijriMonthsBn = {
    1: 'মুহাররম',
    2: 'সফর',
    3: 'রবিউল আউয়াল',
    4: 'রবিউস সানি',
    5: 'জমাদিউল আউয়াল',
    6: 'জমাদিউস সানি',
    7: 'রজব',
    8: 'শাবান',
    9: 'রমজান',
    10: 'শাওয়াল',
    11: 'জিলকদ',
    12: 'জিলহজ্জ',
  };

  String _hijriMonthName(int month) =>
      (_isBangla ? _hijriMonthsBn : _hijriMonthsEn)[month] ?? '';
}
