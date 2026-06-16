part of '../../screens/daily_activity_screen.dart';

/// Compact warning-style card listing the three periods in which voluntary
/// (Sunnah / Nafl) prayers are prohibited — sunrise, midday (Zawal), and
/// sunset. Windows are derived live from the device's prayer schedule (Adhan
/// calculation + GPS location):
///
///   • Sunrise: sunrise → sunrise + 15 min
///   • Zawal:   Dhuhr − 2 min → Dhuhr
///   • Sunset:  Maghrib − 14 min → Maghrib
mixin DailyForbiddenTimesSectionMixin
    on
        State<DailyActivityScreen>,
        DailyActivityControllerMixin,
        DailyActivityViewBaseMixin {
  // Window widths for each prohibited period, applied to the live schedule.
  static const Duration _sunriseWindow = Duration(minutes: 15);
  static const Duration _zawalWindow = Duration(minutes: 2);
  static const Duration _sunsetWindow = Duration(minutes: 14);

  // Warning palette, tuned for both light and dark themes while staying within
  // the app's Islamic visual language.
  Color get _forbiddenStrong =>
      _isDarkTheme ? const Color(0xFFFF8A6B) : const Color(0xFFD24A28);
  Color get _forbiddenBorder =>
      _isDarkTheme ? const Color(0x55FF8A6B) : const Color(0xFFF1C7B8);

  List<
    ({
      IconData icon,
      String titleEn,
      String titleBn,
      DateTime start,
      DateTime end,
    })
  >
  _forbiddenPeriods(DailyPrayerSchedule schedule) {
    // All three boundaries come straight from the live Adhan/GPS schedule.
    final sunrise = schedule.sunrise ?? schedule.fajr;
    final dhuhr = schedule.dzuhr;
    final maghrib = schedule.maghrib;

    return [
      (
        icon: Icons.wb_twilight_rounded,
        titleEn: 'Sunrise',
        titleBn: 'সূর্যোদয়',
        start: sunrise,
        end: sunrise.add(_sunriseWindow),
      ),
      (
        icon: Icons.wb_sunny_rounded,
        titleEn: 'Zawal',
        titleBn: 'যাওয়াল',
        start: dhuhr.subtract(_zawalWindow),
        end: dhuhr,
      ),
      (
        icon: Icons.brightness_4_rounded,
        titleEn: 'Sunset',
        titleBn: 'সূর্যাস্ত',
        start: maghrib.subtract(_sunsetWindow),
        end: maghrib,
      ),
    ];
  }

  /// Zero-padded 12-hour clock with localized digits and meridiem, e.g.
  /// `05:09 AM` (or `০৫:০৯ পূর্বাহ্ণ` in Bangla).
  String _forbiddenClock(DateTime t) {
    final h12 = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final hh = h12.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    final clock = '$hh:$mm';
    final localizedClock = _isBangla ? _toBanglaDigits(clock) : clock;
    return '$localizedClock ${_localizedMeridiem(t.hour < 12)}';
  }

  String _forbiddenRange(DateTime start, DateTime end) =>
      '${_forbiddenClock(start)} - ${_forbiddenClock(end)}';

  String _formatForbiddenCountdown(Duration value) {
    final safe = value.isNegative ? Duration.zero : value;
    final hours = safe.inHours;
    final minutes = safe.inMinutes % 60;
    if (_isBangla) {
      if (hours > 0) {
        return '${_toBanglaDigits(hours.toString())} ঘণ্টা '
            '${_toBanglaDigits(minutes.toString())} মিনিট';
      }
      return '${_toBanglaDigits(minutes.toString())} মিনিট';
    }
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  Widget _buildForbiddenTimesCard() {
    final schedule = _todaySchedule;
    if (schedule == null) return const SizedBox.shrink();

    final periods = _forbiddenPeriods(schedule);

    // Currently active forbidden window, if any.
    final activeIndex = periods.indexWhere(
      (p) => !_now.isBefore(p.start) && _now.isBefore(p.end),
    );
    final hasActive = activeIndex != -1;

    // Next upcoming period today; otherwise tomorrow's sunrise.
    final upcoming = periods.where((p) => p.start.isAfter(_now)).toList()
      ..sort((a, b) => a.start.compareTo(b.start));
    DateTime? nextStart;
    String? nextTitle;
    if (upcoming.isNotEmpty) {
      nextStart = upcoming.first.start;
      nextTitle = _text(upcoming.first.titleEn, upcoming.first.titleBn);
    } else {
      final tomorrow = _tomorrowSchedule;
      final tomorrowSunrise = tomorrow?.sunrise ?? tomorrow?.fajr;
      if (tomorrowSunrise != null) {
        nextStart = tomorrowSunrise;
        nextTitle = _text('Sunrise', 'সূর্যোদয়');
      }
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),
          gradient: LinearGradient(
            colors: _isDarkTheme
                ? const [Color(0xFF1F1512), Color(0xFF170F0D)]
                : const [Color(0xFFFFF6F1), Color(0xFFFCEAE2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: _forbiddenBorder),
          boxShadow: [
            BoxShadow(
              color: _isDarkTheme
                  ? const Color(0x33FF6B45)
                  : const Color(0x1FD24A28),
              blurRadius: 18.r,
              offset: Offset(0, 10.h),
            ),
          ],
        ),
        padding: EdgeInsets.fromLTRB(12.w, 11.h, 12.w, 11.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: warning icon + title + "Sunnah & Nafl only" note.
            Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: 17.sp,
                  color: _forbiddenStrong,
                ),
                SizedBox(width: 7.w),
                Expanded(
                  child: Text(
                    '🚫 ${_text('Forbidden Prayer Times', 'নিষিদ্ধ নামাজের সময়')}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _textPrimary,
                      fontSize: 13.5.sp,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                SizedBox(width: 6.w),
                // Scope note: these prohibitions apply to voluntary prayers.
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: _isDarkTheme
                        ? const Color(0x33FF7043)
                        : const Color(0x1FD24A28),
                    borderRadius: BorderRadius.circular(999.r),
                    border: Border.all(color: _forbiddenBorder),
                  ),
                  child: Text(
                    _text('Sunnah & Nafl', 'সুন্নত ও নফল'),
                    style: TextStyle(
                      color: _forbiddenStrong,
                      fontSize: 9.5.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 9.h),

            // Status banner: active highlight or countdown to the next period.
            Row(
              children: [
                Icon(
                  hasActive ? Icons.block_rounded : Icons.timelapse_rounded,
                  size: 13.sp,
                  color: _forbiddenStrong,
                ),
                SizedBox(width: 5.w),
                Expanded(
                  child: Text(
                    hasActive
                        ? '${_text('Active now', 'এখন চলছে')} · '
                              '${_text(periods[activeIndex].titleEn, periods[activeIndex].titleBn)}'
                        : (nextStart != null
                              ? '${_text('Next', 'পরবর্তী')}: $nextTitle · '
                                    '${_formatForbiddenCountdown(nextStart.difference(_now))}'
                              : _text('No forbidden time', 'নিষিদ্ধ সময় নেই')),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _forbiddenStrong,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 9.h),

            // Three periods side by side: title on top, time range below.
            // IntrinsicHeight bounds the row to its tallest cell so the
            // stretched columns share one height (instead of an infinite one).
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (int i = 0; i < periods.length; i++) ...[
                    Expanded(
                      child: _buildForbiddenColumn(
                        periods[i],
                        isActive: i == activeIndex,
                      ),
                    ),
                    if (i != periods.length - 1) SizedBox(width: 8.w),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// A single forbidden period rendered as a vertical cell — icon and bilingual
  /// title on top, the start–end range stacked below — so the three periods sit
  /// next to each other in columns.
  Widget _buildForbiddenColumn(
    ({
      IconData icon,
      String titleEn,
      String titleBn,
      DateTime start,
      DateTime end,
    })
    period, {
    required bool isActive,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 9.h),
      decoration: BoxDecoration(
        color: isActive
            ? (_isDarkTheme ? const Color(0x33FF7043) : const Color(0x1FD24A28))
            : (_isDarkTheme
                  ? const Color(0x14FF8A6B)
                  : const Color(0x0FD24A28)),
        borderRadius: BorderRadius.circular(11.r),
        border: Border.all(
          color: isActive ? _forbiddenStrong : _forbiddenBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(period.icon, size: 18.sp, color: _forbiddenStrong),
          SizedBox(height: 5.h),
          Text(
            _text(period.titleEn, period.titleBn),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _textPrimary,
              fontSize: 11.5.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 6.h),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              _forbiddenRange(period.start, period.end),
              maxLines: 1,
              style: TextStyle(
                color: _forbiddenStrong,
                fontSize: 11.sp,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (isActive) ...[
            SizedBox(height: 6.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: _forbiddenStrong,
                borderRadius: BorderRadius.circular(999.r),
              ),
              child: Text(
                _text('Now', 'এখন'),
                style: TextStyle(
                  color: _isDarkTheme ? const Color(0xFF2A0F06) : Colors.white,
                  fontSize: 8.5.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
