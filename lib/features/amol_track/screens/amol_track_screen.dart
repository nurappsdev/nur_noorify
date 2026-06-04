import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:first_project/shared/services/app_globals.dart';
import 'package:first_project/features/amol_track/models/amol_track_models.dart';
import 'package:first_project/features/amol_track/services/amol_track_service.dart';

/// "Today Amol Track" — a daily deeds tracker. The user can mark fardh prayers
/// and other deeds done for any day in the visible week; progress is shown as
/// an overall ring plus per-section bars, and persists locally on device.
class AmolTrackScreen extends StatefulWidget {
  const AmolTrackScreen({super.key, this.availableFrom = const {}});

  /// For today, the earliest time each deed (by id) can be tracked — typically
  /// its prayer time. A deed whose time hasn't arrived yet cannot be marked
  /// done. Deeds absent from this map have no time gate.
  final Map<String, DateTime> availableFrom;

  @override
  State<AmolTrackScreen> createState() => _AmolTrackScreenState();
}

class _AmolTrackScreenState extends State<AmolTrackScreen> {
  final AmolTrackService _service = AmolTrackService();

  /// The day currently being viewed/edited. Defaults to today.
  late DateTime _selectedDate;

  /// Completed item ids for [_selectedDate].
  Set<String> _completed = <String>{};

  /// Which sections are expanded. The fardh prayers section starts open.
  final Set<String> _expanded = {'fardh'};

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    _init();
  }

  Future<void> _init() async {
    await _service.load();
    if (!mounted) return;
    setState(() {
      _completed = _service.completedFor(_selectedDate);
      _loading = false;
    });
  }

  bool get _isBangla => appLanguageNotifier.value == AppLanguage.bangla;
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  String _t(String en, String bn) => _isBangla ? bn : en;

  String _digits(String input) {
    if (!_isBangla) return input;
    const bn = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
    final buffer = StringBuffer();
    for (final ch in input.split('')) {
      final code = ch.codeUnitAt(0);
      if (code >= 0x30 && code <= 0x39) {
        buffer.write(bn[code - 0x30]);
      } else {
        buffer.write(ch);
      }
    }
    return buffer.toString();
  }

  // ----- palette ------------------------------------------------------------

  Color _c(int dark, int light) => Color(_isDark ? dark : light);

  Color get _textPrimary => _c(0xFFFFFFFF, 0xFF143349);
  Color get _textSecondary => _c(0xFF9BC1D8, 0xFF5F7E94);
  Color get _textMuted => _c(0xFF6E8DA3, 0xFF8AA2B4);
  Color get _accent => _c(0xFF1FD5C0, 0xFF1EA8B8);
  Color get _gold => _c(0xFFE6C77A, 0xFFB78A2E);
  Color get _done => _c(0xFF1FB574, 0xFF159A5F);
  Color get _trackBg => _c(0xFF1B2D3E, 0xFFD8E7F1);

  Color get _cardStart => _c(0xFF121F2E, 0xFFFFFFFF);
  Color get _cardEnd => _c(0xFF0D1824, 0xFFF2F8FD);
  Color get _cardBorder => _c(0x22D2F4FF, 0xFFDCE9F2);
  Color get _surface => _c(0xFF162433, 0xFFE8F2F8);

  // ----- date helpers -------------------------------------------------------

  static const _weekdayShortEn = [
    'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', //
  ];
  static const _weekdayShortBn = [
    'রবি', 'সোম', 'মঙ্গল', 'বুধ', 'বৃহস্পতি', 'শুক্র', 'শনি', //
  ];
  static const _weekdayFullEn = [
    'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday',
    'Saturday', //
  ];
  static const _weekdayFullBn = [
    'রবিবার', 'সোমবার', 'মঙ্গলবার', 'বুধবার', 'বৃহস্পতিবার', 'শুক্রবার',
    'শনিবার', //
  ];
  static const _monthEn = [
    'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August',
    'September', 'October', 'November', 'December', //
  ];
  static const _monthBn = [
    'জানুয়ারি', 'ফেব্রুয়ারি', 'মার্চ', 'এপ্রিল', 'মে', 'জুন', 'জুলাই',
    'আগস্ট', 'সেপ্টেম্বর', 'অক্টোবর', 'নভেম্বর', 'ডিসেম্বর', //
  ];

  int _weekdayIndex(DateTime d) => d.weekday % 7; // Sun=0 .. Sat=6

  String _weekdayShort(DateTime d) => _isBangla
      ? _weekdayShortBn[_weekdayIndex(d)]
      : _weekdayShortEn[_weekdayIndex(d)];

  String _fullDateLabel(DateTime d) {
    final weekday =
        _isBangla ? _weekdayFullBn[_weekdayIndex(d)] : _weekdayFullEn[_weekdayIndex(d)];
    final month = _isBangla ? _monthBn[d.month - 1] : _monthEn[d.month - 1];
    final day = _digits(d.day.toString().padLeft(2, '0'));
    final year = _digits(d.year.toString());
    return '$weekday, $month $day, $year';
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool get _isToday {
    final now = DateTime.now();
    return _isSameDay(_selectedDate, now);
  }

  /// True for any day after today — a deed that hasn't arrived yet and so
  /// cannot be tracked.
  bool _isFuture(DateTime day) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return DateTime(day.year, day.month, day.day).isAfter(today);
  }

  /// True when [item] is on the currently selected day but its time hasn't yet
  /// come, so it cannot be tracked. Covers future days as a whole and, for
  /// today, individual deeds whose prayer time is still ahead (e.g. Maghrib or
  /// Isha in the afternoon). Past days are always trackable.
  bool _isNotYetAvailable(AmolItem item) {
    if (_isFuture(_selectedDate)) return true;
    if (!_isToday) return false;
    final time = widget.availableFrom[item.id];
    if (time == null) return false;
    return time.isAfter(DateTime.now());
  }

  /// The 7-day window shown in the strip: two days before the selected date
  /// through four days after, so the selected day sits near the start like the
  /// reference design.
  List<DateTime> get _weekWindow => List.generate(
        7,
        (i) => _selectedDate.subtract(Duration(days: 2 - i)),
      );

  // ----- actions ------------------------------------------------------------

  void _selectDate(DateTime date) {
    setState(() {
      _selectedDate = DateTime(date.year, date.month, date.day);
      _completed = _service.completedFor(_selectedDate);
    });
  }

  void _showFutureAmolAlert() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: _cardStart,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18.r),
            side: BorderSide(color: _cardBorder),
          ),
          icon: Icon(
            Icons.event_busy_rounded,
            color: _gold,
            size: 30.sp,
          ),
          content: Text(
            _t(
              'Future Amol track not possible.',
              'ভবিষ্যতের আমল ট্র্যাক করা সম্ভব নয়।',
            ),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _textPrimary,
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              style: TextButton.styleFrom(foregroundColor: _accent),
              child: Text(
                _t('OK', 'ঠিক আছে'),
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _toggleItem(AmolItem item) async {
    if (_isNotYetAvailable(item)) {
      _showFutureAmolAlert();
      return;
    }
    final nowDone = await _service.toggle(_selectedDate, item.id);
    if (!mounted) return;
    setState(() {
      if (nowDone) {
        _completed.add(item.id);
      } else {
        _completed.remove(item.id);
      }
    });
  }

  void _toggleSection(String id) {
    setState(() {
      if (!_expanded.remove(id)) _expanded.add(id);
    });
  }

  // ----- build --------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppLanguage>(
      valueListenable: appLanguageNotifier,
      builder: (context, _, _) {
        return Scaffold(
          backgroundColor: _c(0xFF060C17, 0xFFF0F7FC),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _isDark
                    ? const [
                        Color(0xFF060C17),
                        Color(0xFF0A1521),
                        Color(0xFF08111B),
                      ]
                    : const [
                        Color(0xFFF7FBFF),
                        Color(0xFFEAF4FB),
                        Color(0xFFF2F8FD),
                      ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SafeArea(
              child: _loading
                  ? Center(
                      child: CircularProgressIndicator(color: _accent),
                    )
                  : Column(
                      children: [
                        _buildAppBar(),
                        Expanded(
                          child: ListView(
                            physics: const BouncingScrollPhysics(),
                            padding:
                                EdgeInsets.fromLTRB(14.w, 6.h, 14.w, 20.h),
                            children: [
                              _buildDateStrip(),
                              SizedBox(height: 12.h),
                              _buildWeekStrip(),
                              SizedBox(height: 12.h),
                              _buildOverallCard(),
                              SizedBox(height: 14.h),
                              for (final section in kAmolSections) ...[
                                _buildSection(section),
                                SizedBox(height: 12.h),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: EdgeInsets.fromLTRB(6.w, 6.h, 14.w, 6.h),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: _textPrimary,
              size: 20.sp,
            ),
          ),
          Expanded(
            child: Text(
              _t('Amol Tracker (Beta)', 'আমল ট্র্যাকার (বেটা)'),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _textPrimary,
                fontSize: 17.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(width: 36.w),
        ],
      ),
    );
  }

  Widget _buildDateStrip() {
    return _card(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _fullDateLabel(_selectedDate),
              style: TextStyle(
                color: _textPrimary,
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Icon(Icons.calendar_month_rounded, color: _accent, size: 20.sp),
        ],
      ),
    );
  }

  Widget _buildWeekStrip() {
    return _card(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 10.h),
      child: Row(
        children: [
          for (final day in _weekWindow)
            Expanded(child: _buildDayCell(day)),
        ],
      ),
    );
  }

  Widget _buildDayCell(DateTime day) {
    final selected = _isSameDay(day, _selectedDate);
    final done = _service.completedCountFor(day);
    final progress = kAmolTotalCount == 0 ? 0.0 : done / kAmolTotalCount;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _selectDate(day),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _weekdayShort(day),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: selected ? _accent : _textMuted,
              fontSize: 9.5.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 6.h),
          SizedBox(
            width: 34.r,
            height: 34.r,
            child: CustomPaint(
              painter: _RingPainter(
                progress: progress.clamp(0.0, 1.0),
                trackColor: _trackBg,
                progressColor: selected ? _gold : _accent,
                strokeWidth: 2.6.r,
              ),
              child: Center(
                child: Container(
                  width: selected ? 24.r : 0,
                  height: selected ? 24.r : 0,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected ? _done : Colors.transparent,
                  ),
                  child: selected
                      ? Center(
                          child: Text(
                            _digits(day.day.toString()),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        )
                      : null,
                ),
              ),
            ),
          ),
          if (!selected) ...[
            SizedBox(height: 2.h),
            Text(
              _digits(day.day.toString()),
              style: TextStyle(
                color: _textPrimary,
                fontSize: 11.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOverallCard() {
    final done = _completed.length;
    final total = kAmolTotalCount;
    final progress = total == 0 ? 0.0 : done / total;
    final percent = (progress * 100).round();

    return _card(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
      child: Row(
        children: [
          SizedBox(
            width: 48.r,
            height: 48.r,
            child: CustomPaint(
              painter: _RingPainter(
                progress: progress.clamp(0.0, 1.0),
                trackColor: _trackBg,
                progressColor: _gold,
                strokeWidth: 4.r,
              ),
              child: Center(
                child: Text(
                  '${_digits(percent.toString())}%',
                  style: TextStyle(
                    color: _textPrimary,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isToday
                      ? _t("Track today's amol", 'আজকের আমল ট্রাক করুন')
                      : _t("Track this day's amol", 'এই দিনের আমল ট্রাক করুন'),
                  style: TextStyle(
                    color: _textPrimary,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  _t('Tap a deed below to mark it done',
                      'নিচের আমলে ট্যাপ করে সম্পন্ন চিহ্নিত করুন'),
                  style: TextStyle(
                    color: _textSecondary,
                    fontSize: 10.5.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 10.w),
          _countBadge(done, total),
        ],
      ),
    );
  }

  Widget _countBadge(int done, int total) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isDark
              ? const [Color(0x55E6C77A), Color(0x3320D3BF)]
              : const [Color(0x33B78A2E), Color(0x1F1EA8B8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(999.r),
        border: Border.all(color: _gold.withValues(alpha: 0.4)),
      ),
      child: Text(
        '${_digits(done.toString())}/${_digits(total.toString())}',
        style: TextStyle(
          color: _isDark ? const Color(0xFFF5E2B8) : const Color(0xFF7A5A1F),
          fontSize: 12.sp,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildSection(AmolSection section) {
    final expanded = _expanded.contains(section.id);
    final ids = section.items.map((e) => e.id).toSet();
    final done = ids.where(_completed.contains).length;
    final total = section.items.length;
    final progress = total == 0 ? 0.0 : done / total;

    return _card(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => _toggleSection(section.id),
            borderRadius: BorderRadius.circular(8.r),
            child: Row(
              children: [
                Icon(section.icon, color: _gold, size: 16.sp),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    _t(section.titleEn, section.titleBn),
                    style: TextStyle(
                      color: _textPrimary,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                AnimatedRotation(
                  turns: expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.keyboard_arrow_up_rounded,
                    color: _textSecondary,
                    size: 22.sp,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 10.h),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999.r),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    minHeight: 5.h,
                    backgroundColor: _trackBg,
                    valueColor: AlwaysStoppedAnimation<Color>(_done),
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              Text(
                '${_digits(done.toString())}/${_digits(total.toString())}',
                style: TextStyle(
                  color: _textSecondary,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: EdgeInsets.only(top: 6.h),
              child: Column(
                children: [
                  for (final item in section.items) _buildItemRow(item),
                ],
              ),
            ),
            crossFadeState: expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 220),
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow(AmolItem item) {
    final done = _completed.contains(item.id);
    final locked = _isNotYetAvailable(item);
    return InkWell(
      onTap: () => _toggleItem(item),
      borderRadius: BorderRadius.circular(12.r),
      child: Opacity(
        opacity: locked ? 0.45 : 1.0,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 9.h, horizontal: 2.w),
          child: Row(
            children: [
              Container(
                width: 38.r,
                height: 38.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done ? _done.withValues(alpha: 0.18) : _surface,
                ),
                child: Icon(
                  item.icon,
                  color: done ? _done : _accent,
                  size: 19.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  _t(item.titleEn, item.titleBn),
                  style: TextStyle(
                    color: _textPrimary,
                    fontSize: 13.5.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (locked)
                Icon(
                  Icons.lock_outline_rounded,
                  color: _textMuted,
                  size: 18.sp,
                )
              else
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 24.r,
                  height: 24.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: done ? _done : Colors.transparent,
                    border: Border.all(
                      color: done ? _done : _textMuted,
                      width: 1.6,
                    ),
                  ),
                  child: done
                      ? Icon(Icons.check_rounded,
                          color: Colors.white, size: 15.sp)
                      : null,
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ----- shared card --------------------------------------------------------

  Widget _card({required Widget child, required EdgeInsetsGeometry padding}) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        gradient: LinearGradient(
          colors: [_cardStart, _cardEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: _cardBorder),
      ),
      child: child,
    );
  }
}

/// Draws a circular progress ring (a full track with an arc swept from the top
/// proportional to [progress]).
class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
    required this.strokeWidth,
  });

  final double progress;
  final Color trackColor;
  final Color progressColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = trackColor;
    canvas.drawCircle(center, radius, track);

    if (progress <= 0) return;

    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth
      ..color = progressColor;
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * progress, false, arc);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress ||
      old.trackColor != trackColor ||
      old.progressColor != progressColor ||
      old.strokeWidth != strokeWidth;
}
