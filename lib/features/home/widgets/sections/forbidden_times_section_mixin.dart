part of '../../screens/daily_activity_screen.dart';

/// Warning-style card listing the three periods in which performing salah is
/// prohibited — sunrise, midday (Zawal), and sunset — based on the Bangladesh
/// prayer schedule. Shows each period's local time, a short description, a
/// live countdown to the next period, and highlights the active one.
mixin DailyForbiddenTimesSectionMixin
    on
        State<DailyActivityScreen>,
        DailyActivityControllerMixin,
        DailyActivityViewBaseMixin {
  // Each forbidden period is treated as a short window so the screen can flag
  // when one is currently active and count down to the next.
  static const Duration _forbiddenWindow = Duration(minutes: 15);

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
      String descEn,
      String descBn,
      DateTime display,
      DateTime start,
      DateTime end,
    })
  >
  _forbiddenPeriods(DailyPrayerSchedule schedule) {
    final sunrise = schedule.sunrise ?? schedule.fajr;
    final dhuhr = schedule.dzuhr;
    final maghrib = schedule.maghrib;
    // Zawal (Istiwa) taken as the midpoint between sunrise and Dhuhr.
    final zawal = sunrise.add(dhuhr.difference(sunrise) ~/ 2);

    return [
      (
        icon: Icons.wb_twilight_rounded,
        titleEn: 'Sunrise',
        titleBn: 'সূর্যোদয়',
        descEn: 'Just after sunrise, until the sun has fully risen.',
        descBn: 'সূর্যোদয়ের পরপরই, সূর্য সম্পূর্ণ ওঠা পর্যন্ত।',
        display: sunrise,
        start: sunrise,
        end: sunrise.add(_forbiddenWindow),
      ),
      (
        icon: Icons.wb_sunny_rounded,
        titleEn: 'Midday / Zawal',
        titleBn: 'যাওয়াল',
        descEn: 'Around midday, when the sun is at its zenith (Istiwa).',
        descBn: 'মধ্যাহ্নে, যখন সূর্য মধ্যগগনে অবস্থান করে (ইস্তিওয়া)।',
        display: zawal,
        start: zawal,
        end: zawal.add(_forbiddenWindow),
      ),
      (
        icon: Icons.brightness_4_rounded,
        titleEn: 'Sunset',
        titleBn: 'সূর্যাস্ত',
        descEn: 'During sunset, until the sun has fully set (Maghrib).',
        descBn: 'সূর্যাস্তের সময়, সূর্য সম্পূর্ণ ডোবা পর্যন্ত (মাগরিব)।',
        display: maghrib,
        start: maghrib.subtract(_forbiddenWindow),
        end: maghrib,
      ),
    ];
  }

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
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
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
              blurRadius: 22,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: warning icon + title + subtitle.
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isDarkTheme
                        ? const Color(0x33FF7043)
                        : const Color(0x1FD24A28),
                    border: Border.all(color: _forbiddenBorder),
                  ),
                  child: Icon(
                    Icons.warning_amber_rounded,
                    size: 19,
                    color: _forbiddenStrong,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🚫 ${_text('Forbidden Prayer Times', 'নিষিদ্ধ নামাজের সময়')}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _textPrimary,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _text(
                          'Prayer is prohibited during these periods',
                          'এই সময়গুলোতে নামাজ পড়া নিষিদ্ধ',
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 11),

            // Status banner: active highlight or countdown to next period.
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: hasActive
                    ? (_isDarkTheme
                          ? const Color(0x33FF7043)
                          : const Color(0x1FD24A28))
                    : (_isDarkTheme
                          ? const Color(0x14FF8A6B)
                          : const Color(0x14D24A28)),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _forbiddenBorder),
              ),
              child: Row(
                children: [
                  Icon(
                    hasActive
                        ? Icons.block_rounded
                        : Icons.timelapse_rounded,
                    size: 15,
                    color: _forbiddenStrong,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      hasActive
                          ? '${_text('Active now — prayer prohibited', 'এখন চলছে — নামাজ নিষিদ্ধ')} · '
                                '${_text(periods[activeIndex].titleEn, periods[activeIndex].titleBn)}'
                          : (nextStart != null
                                ? '${_text('Next forbidden time', 'পরবর্তী নিষিদ্ধ সময়')}: '
                                      '$nextTitle · ${_formatForbiddenCountdown(nextStart.difference(_now))}'
                                : _text(
                                    'No forbidden time upcoming',
                                    'কোনো নিষিদ্ধ সময় নেই',
                                  )),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _forbiddenStrong,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            for (int i = 0; i < periods.length; i++) ...[
              _buildForbiddenRow(periods[i], isActive: i == activeIndex),
              if (i != periods.length - 1) const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildForbiddenRow(
    ({
      IconData icon,
      String titleEn,
      String titleBn,
      String descEn,
      String descBn,
      DateTime display,
      DateTime start,
      DateTime end,
    })
    period, {
    required bool isActive,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: isActive
            ? (_isDarkTheme
                  ? const Color(0x33FF7043)
                  : const Color(0x1FD24A28))
            : (_isDarkTheme
                  ? const Color(0x14FF8A6B)
                  : const Color(0x0FD24A28)),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? _forbiddenStrong : _forbiddenBorder,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _isDarkTheme
                  ? const Color(0x33FF7043)
                  : const Color(0x1FD24A28),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(period.icon, size: 18, color: _forbiddenStrong),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        '${_text(period.titleEn, period.titleBn)} '
                        '(${_isBangla ? period.titleEn : period.titleBn})',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _textPrimary,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (isActive) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _forbiddenStrong,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          _text('Now', 'এখন'),
                          style: TextStyle(
                            color: _isDarkTheme
                                ? const Color(0xFF2A0F06)
                                : Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  _text(period.descEn, period.descBn),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _textMuted,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _skyClock(period.display),
            style: TextStyle(
              color: _forbiddenStrong,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
