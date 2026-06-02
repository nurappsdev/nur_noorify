part of '../../screens/daily_activity_screen.dart';

/// The hero "sky" card at the top of the home screen: a sun-path arc during the
/// day, a moon-path arc at night, the Hijri date strip, and the matching
/// day/night progress readout below it.
mixin DailySkySectionMixin
    on
        State<DailyActivityScreen>,
        DailyActivityControllerMixin,
        DailyActivityViewBaseMixin {
  String _arabicWeekdayLabel() {
    const labels = {
      DateTime.sunday: 'ইয়াউমুছ আহাদ',
      DateTime.monday: 'ইয়াউমুছ ইসনাইন',
      DateTime.tuesday: 'ইয়াউমুছ ছুলাছা',
      DateTime.wednesday: 'ইয়াউমুছ আরবিয়া',
      DateTime.thursday: 'ইয়াউমুছ খামিস',
      DateTime.friday: 'ইয়াউমুছ জুমুআহ',
      DateTime.saturday: 'ইয়াউমুছ সাবত',
    };
    return labels[_now.weekday] ?? '';
  }

  String _banglaWeekdayLabel() {
    const labels = {
      DateTime.sunday: 'রবিবার',
      DateTime.monday: 'সোমবার',
      DateTime.tuesday: 'মঙ্গলবার',
      DateTime.wednesday: 'বুধবার',
      DateTime.thursday: 'বৃহস্পতিবার',
      DateTime.friday: 'শুক্রবার',
      DateTime.saturday: 'শনিবার',
    };
    return labels[_now.weekday] ?? '';
  }

  String _banglaSeasonLabel() {
    final month = _now.month;
    if (month >= 4 && month <= 5) {
      return 'গ্রীষ্মকাল';
    }
    if (month >= 6 && month <= 7) {
      return 'বর্ষাকাল';
    }
    if (month >= 8 && month <= 9) {
      return 'শরতকাল';
    }
    if (month == 10) {
      return 'হেমন্তকাল';
    }
    if (month == 11 || month == 12) {
      return 'শীতকাল';
    }
    return 'বসন্তকাল';
  }

  String _activePrayerProgressLabel() {
    final remaining = _activeRemaining.isNegative
        ? Duration.zero
        : _activeRemaining;
    final totalMinutes = remaining.inMinutes;
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (_isBangla) {
      if (hours > 0) {
        return '${_toBanglaDigits(hours.toString())} ঘণ্টা '
            '${_toBanglaDigits(minutes.toString())} মিনিট বাকি';
      }
      return '${_toBanglaDigits(minutes.toString())} মিনিট বাকি';
    }
    if (hours > 0) {
      return '${hours}h ${minutes}m left';
    }
    return '$minutes min left';
  }

  String _activePrayerWindowLabel() {
    final scheduleToday = _todaySchedule;
    if (scheduleToday == null) return '--:-- - --:--';
    final boundaries = <String, ({DateTime start, DateTime end})>{
      'Fajr': (start: scheduleToday.fajr, end: scheduleToday.dzuhr),
      'Zuhr': (start: scheduleToday.dzuhr, end: scheduleToday.ashr),
      'Asr': (start: scheduleToday.ashr, end: scheduleToday.maghrib),
      'Maghrib': (start: scheduleToday.maghrib, end: scheduleToday.isha),
      'Isha': (
        start: scheduleToday.isha,
        end: scheduleToday.isha.add(const Duration(hours: 4)),
      ),
    };
    final entry = boundaries[_activePrayer];
    if (entry == null) return '--:-- - --:--';
    return _windowLabel(entry.start, entry.end);
  }

  /// Formats a start–end prayer window as zero-padded 12-hour clock text.
  String _windowLabel(DateTime? start, DateTime? end) {
    if (start == null || end == null) return '--:-- - --:--';
    String fmt(DateTime t) {
      final h12 = t.hour % 12 == 0 ? 12 : t.hour % 12;
      final hh = h12.toString().padLeft(2, '0');
      final mm = t.minute.toString().padLeft(2, '0');
      final value = '$hh:$mm';
      return _isBangla ? _toBanglaDigits(value) : value;
    }

    return '${fmt(start)} - ${fmt(end)}';
  }

  /// Chasht (Duha) has no dedicated entry in the schedule, so it is taken as
  /// the midpoint between sunrise and Zuhr.
  DateTime? _chashtTime() {
    final schedule = _todaySchedule;
    if (schedule == null) return null;
    final sunrise = schedule.fajr;
    final zuhr = schedule.dzuhr;
    if (!zuhr.isAfter(sunrise)) return null;
    return sunrise.add(zuhr.difference(sunrise) ~/ 2);
  }

  /// Fraction of a start–end window already elapsed at [_now].
  double _segmentProgress(DateTime? start, DateTime? end) {
    if (start == null || end == null) return 0.0;
    final total = end.difference(start).inSeconds;
    if (total <= 0) return 0.0;
    final elapsed = _now.difference(start).inSeconds;
    return (elapsed / total).clamp(0.0, 1.0);
  }

  Widget _buildHeroDateStripContent() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                '$_formattedHijriDate । ${_arabicWeekdayLabel()}',
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.nightlight_round, size: 16, color: _accentGold),
          ],
        ),
        const SizedBox(height: 4),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Text(
              _formattedTime,
              style: TextStyle(
                color: _textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            Expanded(
              child: Text(
                _activeHeaderDate,
                maxLines: 2,
                textAlign: TextAlign.right,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        // Text(
        //   '${_banglaWeekdayLabel()}, $_formattedBanglaDate বঙ্গাব্দ, ${_banglaSeasonLabel()}',
        //   textAlign: TextAlign.center,
        //   maxLines: 1,
        //   overflow: TextOverflow.ellipsis,
        //   style: TextStyle(
        //     color: _textSecondary,
        //     fontSize: 11.5,
        //     fontWeight: FontWeight.w600,
        //   ),
        // ),
      ],
    );
  }

  /// Position of the sun along the arc, where 0.5 is the apex.
  ///
  /// The apex is anchored to Dhuhr (solar noon) so the sun crests exactly at
  /// midday: the Fajr→Dhuhr span fills the first half of the arc and the
  /// Dhuhr→Maghrib span fills the second half.
  double _sunPathProgress() {
    final schedule = _todaySchedule;
    if (schedule == null) return 0.5;
    final sunrise = schedule.fajr;
    final noon = schedule.dzuhr;
    final sunset = schedule.maghrib;

    if (!_now.isAfter(sunrise)) return 0.0;
    if (!_now.isBefore(sunset)) return 1.0;

    if (_now.isBefore(noon)) {
      final total = noon.difference(sunrise).inSeconds;
      if (total <= 0) return 0.5;
      final elapsed = _now.difference(sunrise).inSeconds;
      return (elapsed / total * 0.5).clamp(0.0, 0.5);
    }

    final total = sunset.difference(noon).inSeconds;
    if (total <= 0) return 0.5;
    final elapsed = _now.difference(noon).inSeconds;
    return (0.5 + elapsed / total * 0.5).clamp(0.5, 1.0);
  }

  /// Sun (daytime) or moon (nighttime) progress card. The two halves of the day
  /// track separately: the sun arc covers Fajr→Maghrib, the moon arc covers
  /// Maghrib→Fajr.
  Widget _buildSunArcCard() {
    final isNight = _isNightTime;
    return _buildGlassCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      ornamentedCorners: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isNight) _buildMoonArcArea() else _buildSunArcArea(),
          _ornamentDivider(padding: const EdgeInsets.only(top: 10, bottom: 6)),
          _buildHeroDateStripContent(),
          const SizedBox(height: 10),
          if (isNight)
            ..._buildNightProgressSection()
          else
            ..._buildDayProgressSection(),
        ],
      ),
    );
  }

  Widget _buildSunArcArea() {
    final schedule = _todaySchedule;
    final dzuhr = schedule?.dzuhr;
    final chasht = _chashtTime();
    final isForenoon = dzuhr == null ? _now.hour < 12 : _now.isBefore(dzuhr);

    // The two arc shoulder labels follow the half of the day: the forenoon
    // shows Chasht (rising) and Zuhr (apex); the afternoon shows Asr and
    // Maghrib (descending toward sunset).
    final leadingTitle = isForenoon
        ? _text('Chasht', 'চাশত')
        : _text('Asr', 'আসর');
    final leadingTimeLabel = isForenoon
        ? _skyClock(chasht)
        : _skyClock(schedule?.ashr);
    final trailingTitle = isForenoon
        ? _text('Zuhr', 'যুহর')
        : _text('Maghrib', 'মাগরিব');
    final trailingTimeLabel = isForenoon
        ? _skyClock(schedule?.dzuhr)
        : _skyClock(schedule?.maghrib);

    return SunArcArea(
      currentProgress: _sunPathProgress(),
      isBangla: _isBangla,
      accentStrong: _accentStrong,
      accentSoft: _accentSoft,
      accentGold: _accentGold,
      trackColor: _isDarkTheme
          ? const Color(0x33A4D8E2)
          : const Color(0x40274F6B),
      isDark: _isDarkTheme,
      textPrimary: _textPrimary,
      textSecondary: _textSecondary,
      leadingTitle: leadingTitle,
      leadingTimeLabel: leadingTimeLabel,
      trailingTitle: trailingTitle,
      trailingTimeLabel: trailingTimeLabel,
      sunriseClockText: _skyClock(schedule?.fajr),
      sunsetClockText: _skyClock(schedule?.maghrib),
      middayTimeLabel: _skyClock(schedule?.dzuhr),
    );
  }

  List<Widget> _buildDayProgressSection() {
    final schedule = _todaySchedule;
    final dzuhr = schedule?.dzuhr;
    final chasht = _chashtTime();
    // The progress strip presents the forenoon window as the Chasht period.
    final isChasht = _activePrayer == 'Zuhr';
    final segmentName = isChasht
        ? _text('Chasht', 'চাশত')
        : _localizedPrayerName(_activePrayer);
    final segmentWindow = isChasht
        ? _windowLabel(chasht, dzuhr)
        : _activePrayerWindowLabel();
    final segmentProgress = isChasht
        ? _segmentProgress(chasht, dzuhr)
        : _activeProgress.clamp(0.0, 1.0);

    return [
      Row(
        children: [
          Text(
            segmentName,
            style: TextStyle(
              color: _textPrimary,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          Text(
            segmentWindow,
            style: TextStyle(
              color: _textSecondary,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      const SizedBox(height: 5),
      ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: LinearProgressIndicator(
          value: segmentProgress,
          minHeight: 5,
          backgroundColor: _isDarkTheme
              ? const Color(0xFF1B2D3E)
              : const Color(0xFFD8E7F1),
          valueColor: AlwaysStoppedAnimation<Color>(_accentStrong),
        ),
      ),
      const SizedBox(height: 5),
      Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _accentStrong,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            _text('Ongoing', 'চলমান'),
            style: TextStyle(
              color: _accentStrong,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          Text(
            _activePrayerProgressLabel(),
            style: TextStyle(
              color: _textSecondary,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    ];
  }

  Widget _buildMoonArcArea() {
    final schedule = _todaySchedule;
    final window = _currentNightWindow();
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Color(0xFF0A1430), Color(0xFF111F45), Color(0xFF1A2B55)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          border: Border.all(color: const Color(0x3357739C)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x402A4A8C),
              blurRadius: 22,
              offset: Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        child: MoonArcArea(
          progress: _nightProgress(),
          isLastThird: _isLastThirdOfNight(),
          maghribLabel: _text('Maghrib', 'মাগরিব'),
          fajrLabel: _text('Fajr', 'ফজর'),
          midnightLabel: _text('Midnight', 'মধ্যরাত'),
          tahajjudLabel: _text('Tahajjud', 'তাহাজ্জুদ'),
          maghribClock: _skyClock(schedule?.maghrib),
          fajrClock: _skyClock(window?.end),
          tahajjudClock: _skyClock(_tahajjudTime()),
        ),
      ),
    );
  }

  List<Widget> _buildNightProgressSection() {
    final isLastThird = _isLastThirdOfNight();
    final pct = (_nightProgress() * 100).round();
    final pctText = _isBangla
        ? '${_toBanglaDigits(pct.toString())}%'
        : '$pct%';
    final label = isLastThird
        ? _text('Last third of the night', 'রাতের শেষ তৃতীয়াংশ')
        : _text('Night in progress', 'রাত চলছে');
    return [
      Row(
        children: [
          Icon(Icons.nightlight_round, size: 13, color: _accentGold),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _textPrimary,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            '${_text('Tahajjud', 'তাহাজ্জুদ')} · ${_skyClock(_tahajjudTime())}',
            style: TextStyle(
              color: _textSecondary,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      const SizedBox(height: 5),
      ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: LinearProgressIndicator(
          value: _nightProgress(),
          minHeight: 5,
          backgroundColor: _isDarkTheme
              ? const Color(0xFF1B2D3E)
              : const Color(0xFFD8E7F1),
          valueColor: AlwaysStoppedAnimation<Color>(
            isLastThird ? _accentGold : _accentSoft,
          ),
        ),
      ),
      const SizedBox(height: 5),
      Row(
        children: [
          Icon(
            isLastThird
                ? Icons.auto_awesome_rounded
                : Icons.bedtime_outlined,
            size: 11,
            color: isLastThird ? _accentGold : _accentSoft,
          ),
          const SizedBox(width: 5),
          Text(
            isLastThird
                ? _text('Time for Tahajjud', 'তাহাজ্জুদের সময়')
                : _text('Resting hours', 'বিশ্রামের সময়'),
            style: TextStyle(
              color: isLastThird ? _accentGold : _accentSoft,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          Text(
            '${_text('Night', 'রাত')} $pctText',
            style: TextStyle(
              color: _textSecondary,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    ];
  }
}
