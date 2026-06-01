part of '../screens/daily_activity_screen.dart';

mixin DailyActivityViewMixin
    on State<DailyActivityScreen>, DailyActivityControllerMixin {
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
    for (var i = 0; i < 2; i++) {
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

  String _text(String english, String bangla) {
    if (!_isBangla) return english;
    final repaired = _repairMojibake(bangla);
    if (_looksMojibake(repaired)) return english;
    return _containsBangla(repaired) ? repaired : english;
  }

  String _greetingText() {
    final hour = _now.hour;
    if (hour < 12) return _text('Assalamu Alaikum,', 'আসসালামু আলাইকুম,');
    if (hour < 17) return _text('Good Afternoon,', 'শুভ অপরাহ্ন,');
    return _text('Good Evening,', 'শুভ সন্ধ্যা,');
  }

  String _profileDisplayName([String? rawName]) {
    final value = (rawName ?? profileNameNotifier.value).trim();
    return value;
  }

  bool _hasProfileName([String? rawName]) =>
      _profileDisplayName(rawName).isNotEmpty;

  String _profileInitial([String? rawName]) {
    final name = _profileDisplayName(rawName);
    return name.isEmpty ? 'N' : name[0].toUpperCase();
  }

  ImageProvider<Object>? _profileAvatarImage({
    String? encodedPhoto,
    String? remotePhotoUrl,
  }) {
    final encoded = (encodedPhoto ?? profilePhotoBase64Notifier.value ?? '')
        .trim();
    if (encoded.isNotEmpty) {
      try {
        return MemoryImage(base64Decode(encoded));
      } catch (_) {
        // Fallback to url/default avatar when local image data is invalid.
      }
    }

    final remoteUrl = (remotePhotoUrl ?? profilePhotoUrlNotifier.value ?? '')
        .trim();
    if (remoteUrl.isNotEmpty) {
      return NetworkImage(remoteUrl);
    }
    return null;
  }

  String _activePrayerShortCountdown() {
    final value = _formattedActiveRemaining();
    return _isBangla ? '$value \u09ac\u09be\u0995\u09bf' : 'in $value';
  }

  String _localizedCount(int value) {
    final raw = value.toString();
    return _isBangla ? _toBanglaDigits(raw) : raw;
  }

  String _localizedDistance(double km) {
    final raw = km.toStringAsFixed(1);
    return _isBangla ? '${_toBanglaDigits(raw)} km' : '$raw km';
  }

  String _prayerMeridiem(String prayer) {
    return prayer == 'Fajr' ? 'AM' : 'PM';
  }

  bool get _isDarkTheme => Theme.of(context).brightness == Brightness.dark;

  Color get _glassStart =>
      _isDarkTheme ? const Color(0xFF121F2E) : const Color(0xF7FFFFFF);
  Color get _glassEnd =>
      _isDarkTheme ? const Color(0xFF0D1824) : const Color(0xDBF2F8FD);
  Color get _glassBorder =>
      _isDarkTheme ? const Color(0x22D2F4FF) : const Color(0xCCFFFFFF);
  Color get _glassShadow =>
      _isDarkTheme ? const Color(0x50000000) : const Color(0x260E3853);

  Color get _textPrimary =>
      _isDarkTheme ? Colors.white : const Color(0xFF143349);
  Color get _textSecondary =>
      _isDarkTheme ? const Color(0xFF9BC1D8) : const Color(0xFF5F7E94);
  Color get _textMuted =>
      _isDarkTheme ? const Color(0xFF88AFC7) : const Color(0xFF4D6B82);
  Color get _textWeak =>
      _isDarkTheme ? const Color(0xFFAFC4D4) : const Color(0xFF5D7C91);

  Color get _accentStrong =>
      _isDarkTheme ? const Color(0xFF1FD5C0) : const Color(0xFF1EA8B8);
  Color get _accentSoft =>
      _isDarkTheme ? const Color(0xFF7ED9EE) : const Color(0xFF2EA2BF);
  Color get _accentGold =>
      _isDarkTheme ? const Color(0xFFE6C77A) : const Color(0xFFB78A2E);
  Color get _accentGoldSoft =>
      _isDarkTheme ? const Color(0x66E6C77A) : const Color(0x66B78A2E);

  Color get _surfaceSubtle =>
      _isDarkTheme ? const Color(0xFF172A3A) : const Color(0xECFFFFFF);
  Color get _surfaceStrong =>
      _isDarkTheme ? const Color(0xFF162433) : const Color(0xFFE8F2F8);
  Color get _surfaceBorder =>
      _isDarkTheme ? const Color(0x334F7590) : const Color(0xFFD1E1EC);

  Widget _buildGlassCard({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(14),
    BorderRadiusGeometry radius = const BorderRadius.all(Radius.circular(18)),
    bool ornamentedCorners = false,
  }) {
    final card = ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: LinearGradient(
              colors: [_glassStart, _glassEnd],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: _glassBorder),
            boxShadow: [
              BoxShadow(
                color: _glassShadow,
                blurRadius: 24,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );

    if (!ornamentedCorners) return card;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        card,
        Positioned(
          top: -2,
          right: 14,
          child: _cornerOrnament(),
        ),
        Positioned(
          bottom: -2,
          left: 14,
          child: _cornerOrnament(),
        ),
      ],
    );
  }

  Widget _cornerOrnament() {
    return Transform.rotate(
      angle: 0.785398,
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: _accentGold,
          borderRadius: BorderRadius.circular(1.5),
          boxShadow: [
            BoxShadow(
              color: _accentGoldSoft,
              blurRadius: 8,
              spreadRadius: 0.5,
            ),
          ],
        ),
      ),
    );
  }

  Widget _ornamentDivider({EdgeInsetsGeometry? padding}) {
    final line = Expanded(
      child: Container(
        height: 1,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _accentGoldSoft.withValues(alpha: 0),
              _accentGoldSoft,
              _accentGoldSoft.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
    return Padding(
      padding: padding ?? const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          line,
          const SizedBox(width: 8),
          Transform.rotate(
            angle: 0.785398,
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: _accentGold,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
          const SizedBox(width: 8),
          line,
        ],
      ),
    );
  }

  String _arabicWeekdayLabel() {
    const labels = {
      DateTime.sunday: 'ইয়াউমুছ আহাদ',
      DateTime.monday: 'ইয়াউমুছ ইসনাইন',
      DateTime.tuesday: 'ইয়াউমুছ ছুলাছা',
      DateTime.wednesday: 'ইয়াউমুছ আরবিয়া',
      DateTime.thursday: 'ইয়াউমুছ খামিস',
      DateTime.friday: 'ইয়াউমুছ জুমুআহ',
      DateTime.saturday: 'ইয়াউমুছ সাবত',
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

  String _skyClock(DateTime? t) =>
      t == null ? '--:--' : _localizedPrayerTime(_formatPrayerTime(t));

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

    return _SunArcArea(
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

  // Moonlight palette for the nighttime section, independent of the app theme
  // so the night vibe reads the same in light and dark mode.
  static const Color _moonInk = Color(0xFFCFE0FF);
  static const Color _moonInkSoft = Color(0xFF9FB6E0);
  static const Color _moonGlow = Color(0xFFBFD2FF);
  static const Color _moonGold = Color(0xFFE9D8A6);

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
        child: _MoonArcArea(
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

  Widget _buildTahajjudReminderCard() {
    final tahajjudClock = _skyClock(_tahajjudTime());
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            colors: [Color(0xFF1B1142), Color(0xFF23215C), Color(0xFF15244F)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: const Color(0x55B79CF0)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x55382C7A),
              blurRadius: 26,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: Stack(
          children: [
            // A few static stars for the distinct night vibe.
            const Positioned(
              top: 12,
              right: 22,
              child: Icon(Icons.star_rounded, size: 9, color: Color(0x88FFFFFF)),
            ),
            const Positioned(
              top: 30,
              right: 48,
              child: Icon(Icons.star_rounded, size: 6, color: Color(0x66FFFFFF)),
            ),
            const Positioned(
              bottom: 18,
              right: 16,
              child: Icon(Icons.star_rounded, size: 7, color: Color(0x55FFFFFF)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Color(0xFFE9D8A6), Color(0xFFC9A24B)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x88E9D8A6),
                              blurRadius: 14,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.nightlight_round,
                          size: 18,
                          color: Color(0xFF231A04),
                        ),
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
                                    _text('Tahajjud Reminder', 'তাহাজ্জুদের আহ্বান'),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: _moonInk,
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  'التهجد',
                                  style: TextStyle(
                                    color: _moonGold,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _text(
                                'Last third of the night',
                                'রাতের শেষ তৃতীয়াংশ',
                              ),
                              style: const TextStyle(
                                color: _moonInkSoft,
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
                  Text(
                    _text(
                      '“Our Lord descends to the lowest heaven in the last third of the night…” — stand, pray, and ask.',
                      '“আমাদের রব রাতের শেষ তৃতীয়াংশে নিকটবর্তী আকাশে অবতরণ করেন…” — উঠুন, নামাজ পড়ুন ও দোয়া করুন।',
                    ),
                    style: const TextStyle(
                      color: _moonInk,
                      fontSize: 12,
                      height: 1.45,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time_rounded,
                        size: 16,
                        color: _moonGlow,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _text('Recommended', 'প্রস্তাবিত'),
                        style: const TextStyle(
                          color: _moonInkSoft,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        tahajjudClock,
                        style: const TextStyle(
                          color: _moonInk,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      _buildTahajjudReminderToggle(),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTahajjudReminderToggle() {
    return ValueListenableBuilder<bool>(
      valueListenable: tahajjudAlertEnabledNotifier,
      builder: (context, enabled, _) {
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              tahajjudAlertEnabledNotifier.value = !enabled;
              unawaited(saveAppPreferences());
            },
            borderRadius: BorderRadius.circular(999),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: enabled
                    ? const LinearGradient(
                        colors: [Color(0xFFE9D8A6), Color(0xFFC9A24B)],
                      )
                    : null,
                color: enabled ? null : const Color(0x332C3C72),
                border: Border.all(
                  color: enabled
                      ? const Color(0x00000000)
                      : const Color(0x66B79CF0),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    enabled
                        ? Icons.notifications_active_rounded
                        : Icons.notifications_none_rounded,
                    size: 14,
                    color: enabled ? const Color(0xFF231A04) : _moonInk,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    enabled
                        ? _text('On', 'চালু')
                        : _text('Remind me', 'মনে করিয়ে দিন'),
                    style: TextStyle(
                      color: enabled ? const Color(0xFF231A04) : _moonInk,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
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

  Widget _buildTopHeader() {
    return _buildGlassCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      ornamentedCorners: true,
      child: Column(
        children: [
          Row(
            children: [
              ValueListenableBuilder<String>(
                valueListenable: profileNameNotifier,
                builder: (context, profileName, child) {
                  return ValueListenableBuilder<String?>(
                    valueListenable: profilePhotoBase64Notifier,
                    builder: (context, profilePhotoBase64, child) {
                      return ValueListenableBuilder<String?>(
                        valueListenable: profilePhotoUrlNotifier,
                        builder: (context, profilePhotoUrl, child) {
                          final profileImage = _profileAvatarImage(
                            encodedPhoto: profilePhotoBase64,
                            remotePhotoUrl: profilePhotoUrl,
                          );
                          final hasName = _hasProfileName(profileName);
                          return Expanded(
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: _isDarkTheme
                                      ? const Color(0xFF1A2F45)
                                      : const Color(0xFFDDEBF5),
                                  backgroundImage: profileImage,
                                  child: profileImage == null
                                      ? (hasName
                                            ? Text(
                                                _profileInitial(profileName),
                                                style: TextStyle(
                                                  color: _isDarkTheme
                                                      ? Colors.white
                                                      : const Color(0xFF183247),
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              )
                                            : Icon(
                                                Icons.auto_awesome_rounded,
                                                size: 18,
                                                color: _isDarkTheme
                                                    ? const Color(0xFF9EE7F4)
                                                    : const Color(0xFF1EA8B8),
                                              ))
                                      : null,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.nightlight_round,
                                            size: 12,
                                            color: _accentGold,
                                          ),
                                          const SizedBox(width: 5),
                                          Flexible(
                                            child: Text(
                                              _greetingText(),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: _isDarkTheme
                                                    ? const Color(0xB3D8E5F7)
                                                    : const Color(0xFF4B687F),
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                                letterSpacing: 0.2,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      if (hasName)
                                        Text(
                                          _profileDisplayName(profileName),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: _textPrimary,
                                            fontSize: 20,
                                            fontWeight: FontWeight.w700,
                                            height: 1,
                                          ),
                                        )
                                      else
                                        InkWell(
                                          onTap: () => Navigator.of(
                                            context,
                                          ).pushNamed(RouteNames.editProfile),
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _isDarkTheme
                                                  ? const Color(0x2D2EB8E6)
                                                  : const Color(0x251EA8B8),
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                              border: Border.all(
                                                color: _isDarkTheme
                                                    ? const Color(0x6659C8E4)
                                                    : const Color(0x66A7D7E2),
                                              ),
                                            ),
                                            child: Text(
                                              _text(
                                                'Set your profile name',
                                                'Set your profile name',
                                              ),
                                              style: TextStyle(
                                                color: _accentSoft,
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
              Material(
                color: _isDarkTheme
                    ? const Color(0xFF193048)
                    : const Color(0xE8FFFFFF),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: () =>
                      Navigator.of(context).pushNamed(RouteNames.preferences),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: EdgeInsets.all(10),
                    child: Icon(
                      Icons.notifications_none_rounded,
                      color: _isDarkTheme
                          ? const Color(0xFFB6CFE5)
                          : const Color(0xFF47677E),
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 14,
                color: _isDarkTheme
                    ? const Color(0xFF8FB5CC)
                    : const Color(0xFF5D7B93),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  _locationLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _isDarkTheme
                        ? const Color(0xFFB6CFE5)
                        : const Color(0xFF56758E),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              InkWell(
                onTap: _refreshLocationFromHeader,
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: _isDarkTheme
                        ? const Color(0xFF1B344A)
                        : const Color(0xE8FFFFFF),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: _isDarkTheme
                          ? const Color(0x3359C8E4)
                          : const Color(0x66B7D5E6),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh_rounded, size: 13, color: _accentSoft),
                      const SizedBox(width: 4),
                      Text(
                        _text('Refresh', 'রিফ্রেশ'),
                        style: TextStyle(
                          color: _accentSoft,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                _formattedTime,
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
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
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              _isBangla
                  ? '$_formattedHijriDate | $_formattedBanglaDate'
                  : '$_formattedHijriDate | $_formattedBritishDate',
              maxLines: 1,
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
    );
  }

  Widget _buildPrayerStrip() {
    return _buildGlassCard(
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
      ornamentedCorners: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.brightness_5_outlined,
                size: 13,
                color: _accentGold,
              ),
              const SizedBox(width: 6),
              Text(
                _text('Prayer Times', 'নামাজের সময়'),
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _isDarkTheme
                        ? const [Color(0x55E6C77A), Color(0x3320D3BF)]
                        : const [Color(0x33B78A2E), Color(0x1F1EA8B8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: _accentGoldSoft),
                ),
                child: Text(
                  _isShowingActivePrayer
                      ? '${_localizedActiveRemainingLabel()}: ${_activePrayerShortCountdown()}'
                      : '${_localizedPrayerTimeLabel()}: ${_localizedPrayerTime(_prayerTimes[_displayPrayer] ?? '--:--')}',
                  style: TextStyle(
                    color: _isDarkTheme
                        ? const Color(0xFFF5E2B8)
                        : const Color(0xFF7A5A1F),
                    fontSize: 10.8,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _localizedCountdownLabel(),
            style: TextStyle(
              color: _textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              Icon(
                Icons.access_time_filled_rounded,
                size: 14,
                color: _accentSoft,
              ),
              const SizedBox(width: 5),
              Text(
                '${_localizedPrayerName(_displayPrayer)} · ',
                style: TextStyle(
                  color: _textSecondary,
                  fontSize: 11.2,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                _arabicPrayerName(_displayPrayer),
                style: TextStyle(
                  color: _accentGold,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                _localizedPrayerTime(_prayerTimes[_displayPrayer] ?? '--:--'),
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          _ornamentDivider(padding: const EdgeInsets.only(top: 8, bottom: 4)),
          SizedBox(
            height: 104,
            child: PageView.builder(
              controller: _prayerPageController,
              itemCount: _prayerCarouselItemsCount,
              onPageChanged: (index) {
                final prayer = _prayerForCarouselIndex(index);
                if (prayer == _activePrayer) {
                  if (_selectedPrayer != null) {
                    setState(() => _selectedPrayer = null);
                  }
                  return;
                }
                if (_selectedPrayer != prayer) {
                  setState(() => _selectedPrayer = prayer);
                }
              },
              itemBuilder: (context, index) {
                final prayer = _prayerForCarouselIndex(index);
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: _buildPrayerTimeChip(prayer, pageIndex: index),
                );
              },
            ),
          ),
          if (!_isShowingActivePrayer) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  foregroundColor: _accentStrong,
                ),
                onPressed: () {
                  setState(() => _selectedPrayer = null);
                  _syncPrayerPageToActive(animate: true);
                },
                icon: const Icon(Icons.my_location_rounded, size: 15),
                label: Text(_text('Back to current', 'বর্তমানে ফিরুন')),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPrayerTimeChip(String prayer, {required int pageIndex}) {
    final isActive = prayer == _displayPrayer;
    final time = _localizedPrayerTime(_prayerTimes[prayer] ?? '--:--');
    final icon = _prayerIcon(prayer);

    return InkWell(
      onTap: () {
        setState(() => _selectedPrayer = prayer);
        final around = _prayerPageController.hasClients
            ? (_prayerPageController.page?.round() ?? pageIndex)
            : pageIndex;
        final targetIndex = _carouselIndexForPrayer(prayer, around: around);
        if (_prayerPageController.hasClients) {
          _prayerPageController.animateToPage(
            targetIndex,
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOut,
          );
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedScale(
        scale: isActive ? 1.02 : 1,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: isActive
                ? const LinearGradient(
                    colors: [Color(0xFF1FD5C0), Color(0xFF1EA8B8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isActive
                ? null
                : (_isDarkTheme
                      ? const Color(0xFF162433)
                      : const Color(0xFFE8F2F8)),
            border: Border.all(
              color: isActive
                  ? const Color(0x88A9FFF4)
                  : (_isDarkTheme
                        ? const Color(0x334E728E)
                        : const Color(0xFFCADCE9)),
            ),
            boxShadow: isActive
                ? const [
                    BoxShadow(
                      color: Color(0x4D1FD5C0),
                      blurRadius: 16,
                      spreadRadius: 0.3,
                      offset: Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    size: 12.5,
                    color: isActive
                        ? const Color(0xDD032F35)
                        : (_isDarkTheme
                              ? const Color(0xFF9BC1D8)
                              : const Color(0xFF56758A)),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _localizedPrayerName(prayer),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isActive
                            ? const Color(0xFF032F35)
                            : (_isDarkTheme
                                  ? Colors.white
                                  : const Color(0xFF214259)),
                        fontSize: 10.8,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    _arabicPrayerName(prayer),
                    style: TextStyle(
                      color: isActive
                          ? const Color(0xCC032F35)
                          : _accentGold,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      height: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                time,
                style: TextStyle(
                  color: isActive
                      ? const Color(0xFF032F35)
                      : (_isDarkTheme ? Colors.white : const Color(0xFF214259)),
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  Text(
                    _prayerMeridiem(prayer),
                    style: TextStyle(
                      color: isActive
                          ? const Color(0xDD032F35)
                          : (_isDarkTheme
                                ? const Color(0xFF86A8BE)
                                : const Color(0xFF5D7C91)),
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  if (isActive)
                    Transform.rotate(
                      angle: 0.785398,
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xDD032F35),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _prayerIcon(String prayer) {
    switch (prayer) {
      case 'Fajr':
        return Icons.wb_twilight_rounded;
      case 'Zuhr':
        return Icons.wb_sunny_rounded;
      case 'Asr':
        return Icons.brightness_5_rounded;
      case 'Maghrib':
        return Icons.bedtime_rounded;
      case 'Isha':
        return Icons.nights_stay_rounded;
      default:
        return Icons.schedule_rounded;
    }
  }

  double? _miniCompassDelta() {
    final heading = _homeHeading;
    final bearing = _homeQiblaBearing;
    if (heading == null || bearing == null) return null;
    return _signedQiblaDelta(bearing, heading);
  }

  String _miniQiblaValueText() {
    const degree = '\u00B0';
    final delta = _miniCompassDelta();
    if (delta == null) return '--';
    final angle = delta.abs().round();
    if (angle == 0) return '0$degree';
    return '$angle$degree ${delta >= 0 ? 'E' : 'W'}';
  }

  Widget _buildMiniCompassDial() {
    final heading = _homeHeading;
    final qiblaBearing = _homeQiblaBearing;
    final dialTurns = heading == null ? 0.0 : -heading / 360;
    final qiblaTurns = (heading != null && qiblaBearing != null)
        ? _signedQiblaDelta(qiblaBearing, heading) / 360
        : null;
    final hasLiveQibla = qiblaTurns != null;
    final northColor = _isDarkTheme
        ? const Color(0xFFD6E6F3)
        : const Color(0xFF2B4A5F);

    return SizedBox(
      width: 108,
      height: 108,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 108,
            height: 108,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: _isDarkTheme
                    ? const Color(0x446EA8C9)
                    : const Color(0x66BCD2E1),
              ),
              gradient: RadialGradient(
                colors: _isDarkTheme
                    ? const [Color(0xFF1B3145), Color(0xFF122537)]
                    : const [Color(0xFFFFFFFF), Color(0xFFE8F2F8)],
              ),
              boxShadow: [
                BoxShadow(
                  color: hasLiveQibla
                      ? const Color(0x5521D6C2)
                      : (_isDarkTheme
                            ? const Color(0x22000000)
                            : const Color(0x220E3853)),
                  blurRadius: hasLiveQibla ? (_isDarkTheme ? 18 : 14) : 8,
                  spreadRadius: hasLiveQibla ? 1 : 0,
                ),
              ],
            ),
          ),
          AnimatedRotation(
            turns: dialTurns,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            child: SizedBox(
              width: 96,
              height: 96,
              child: CustomPaint(
                painter: _MiniCompassMarksPainter(isDark: _isDarkTheme),
              ),
            ),
          ),
          AnimatedRotation(
            turns: dialTurns,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            child: SizedBox(
              width: 86,
              height: 86,
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.topCenter,
                    child: Text(
                      'N',
                      style: TextStyle(
                        color: northColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'E',
                      style: TextStyle(
                        color: _textWeak,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Text(
                      'S',
                      style: TextStyle(
                        color: _textWeak,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'W',
                      style: TextStyle(
                        color: _textWeak,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (qiblaTurns != null)
            AnimatedRotation(
              turns: qiblaTurns,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              child: SizedBox(
                width: 82,
                height: 82,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(82, 82),
                      painter: _MiniQiblaNeedlePainter(isDark: _isDarkTheme),
                    ),
                    Align(
                      alignment: Alignment.topCenter,
                      child: _MiniKaabaMarker(isDark: _isDarkTheme),
                    ),
                  ],
                ),
              ),
            ),
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: _accentSoft,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQiblaAndCountdownRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildGlassCard(
            child: InkWell(
              onTap: () =>
                  Navigator.of(context).pushNamed(RouteNames.prayerCompass),
              borderRadius: BorderRadius.circular(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _text('Qibla', 'কিবলা'),
                    style: TextStyle(
                      color: _textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Center(child: _buildMiniCompassDial()),
                  const SizedBox(height: 8),
                  Text(
                    _text('Qibla Direction: ', 'কিবলার দিক: ') +
                        _miniQiblaValueText(),
                    style: TextStyle(
                      color: _textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: _buildIftarCountdownCard()),
      ],
    );
  }

  Widget _buildIftarCountdownCard() {
    return _buildGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _text(
              'Sehri & Iftar',
              '\u09b8\u09c7\u09b9\u09b0\u09bf \u0993 \u0987\u09ab\u09a4\u09be\u09b0',
            ),
            style: TextStyle(
              color: _textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 9),
          Container(
            decoration: BoxDecoration(
              color: _surfaceSubtle,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _surfaceBorder),
            ),
            child: Column(
              children: [
                _buildMealInfoRow(
                  icon: Icons.free_breakfast_rounded,
                  title: _localizedNextSehriLabel(),
                  time: _localizedTimeOrPlaceholder(_nextSehriAt),
                  showDivider: true,
                ),
                _buildMealInfoRow(
                  icon: Icons.dinner_dining_rounded,
                  title: _localizedNextIftarLabel(),
                  time: _localizedTimeOrPlaceholder(_nextIftarAt),
                  highlight: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: _isDarkTheme
                  ? const Color(0x1F1FD5C0)
                  : const Color(0x1A1EA8B8),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _isDarkTheme
                    ? const Color(0x339DEFE5)
                    : const Color(0x3351BFC9),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.timelapse_rounded, size: 15, color: _accentSoft),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${_localizedRemainingLabel()}: ${_formattedIftarRemaining()}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _accentStrong,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
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

  Widget _buildMealInfoRow({
    required IconData icon,
    required String title,
    required String time,
    bool highlight = false,
    bool showDivider = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 9),
      decoration: BoxDecoration(
        color: highlight
            ? (_isDarkTheme ? const Color(0x1F1FD5C0) : const Color(0x1A1EA8B8))
            : Colors.transparent,
        borderRadius: highlight ? BorderRadius.circular(10) : BorderRadius.zero,
        border: showDivider
            ? Border(bottom: BorderSide(color: _surfaceBorder))
            : (highlight
                  ? Border.all(
                      color: _isDarkTheme
                          ? const Color(0x339DEFE5)
                          : const Color(0x3351BFC9),
                    )
                  : null),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: _isDarkTheme
                  ? const Color(0x332FD8C7)
                  : const Color(0x221EA8B8),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 17, color: _accentSoft),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            time,
            style: TextStyle(
              color: highlight ? _accentStrong : _textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMosquePreviewCard() {
    final items = _nearbyMosquePreview.take(3).toList(growable: false);
    final hasData = items.isNotEmpty;

    return _buildGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                _text('Nearby Mosques', 'নিকটবর্তী মসজিদ'),
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: _openFindMosque,
                style: TextButton.styleFrom(
                  foregroundColor: _accentStrong,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  visualDensity: VisualDensity.compact,
                ),
                child: Text(_text('View all', 'সব দেখুন')),
              ),
            ],
          ),
          const SizedBox(height: 6),
          InkWell(
            onTap: _openFindMosque,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              constraints: const BoxConstraints(minHeight: 132),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(
                  colors: _isDarkTheme
                      ? const [Color(0xFF1A3045), Color(0xFF142435)]
                      : const [Color(0xFFF6FBFF), Color(0xFFE6F1F8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: _isDarkTheme
                      ? const Color(0x334F7590)
                      : const Color(0xFFCFDFEA),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Column(
                  children: [
                    if (hasData) ...[
                      for (final item in items) ...[
                        _buildMosquePreviewPill(
                          name: item.name,
                          distance: _localizedDistance(item.distanceKm),
                        ),
                        if (item != items.last) const SizedBox(height: 8),
                      ],
                    ] else ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(4, 10, 4, 14),
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_searching_rounded,
                              size: 18,
                              color: _textWeak,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _text(
                                  'Tap to sync your nearest mosque list',
                                  'নিকটবর্তী মসজিদের তালিকা সিঙ্ক করতে ট্যাপ করুন',
                                ),
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
                    ],
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _accentStrong,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          _text(
                            hasData ? 'Updated list' : 'Find Mosque',
                            hasData ? 'আপডেটেড তালিকা' : 'মসজিদ খুঁজুন',
                          ),
                          style: TextStyle(
                            color: _isDarkTheme
                                ? const Color(0xFF042A31)
                                : Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_nearbyMosquePreviewUpdatedAt != null) ...[
            const SizedBox(height: 6),
            Text(
              _text(
                'Last synced from Find Mosque',
                'Find Mosque থেকে সর্বশেষ সিঙ্ক',
              ),
              style: TextStyle(
                color: _textMuted,
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMosquePreviewPill({
    required String name,
    required String distance,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: _isDarkTheme ? const Color(0xB2122231) : const Color(0xEFFFFFFF),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: _isDarkTheme
              ? const Color(0x334F7590)
              : const Color(0xFFD1E1EC),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.location_city_rounded, size: 16, color: _textWeak),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            distance,
            style: TextStyle(
              color: _accentStrong,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openZakatCalculator() async {
    final uri = Uri.parse('https://ilmifytech.agency/zakat');

    final launchedInApp = await launchUrl(
      uri,
      mode: LaunchMode.inAppBrowserView,
      browserConfiguration: const BrowserConfiguration(showTitle: true),
    );
    if (launchedInApp) return;

    final launchedWebView = await launchUrl(
      uri,
      mode: LaunchMode.inAppWebView,
      webViewConfiguration: const WebViewConfiguration(
        enableJavaScript: true,
        enableDomStorage: true,
      ),
    );
    if (launchedWebView) return;

    final launchedExternal = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!launchedExternal && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _text(
              'Unable to open Zakat calculator',
              'যাকাত ক্যালকুলেটর খোলা যাচ্ছে না',
            ),
          ),
        ),
      );
    }
  }

  Widget _buildQuickActions() {
    final actions =
        <({String titleEn, String titleBn, IconData icon, String route})>[
          if (kQuranFeatureEnabled)
            (
              titleEn: 'Quran',
              titleBn: '\u0995\u09c1\u09b0\u0986\u09a8',
              icon: Icons.auto_stories_rounded,
              route: RouteNames.quran,
            ),
          (
            titleEn: 'Hadith',
            titleBn: '\u09b9\u09be\u09a6\u09bf\u09b8',
            icon: Icons.menu_book_rounded,
            route: RouteNames.hadith,
          ),
          (
            titleEn: 'Dua',
            titleBn: '\u09a6\u09cb\u09af\u09bc\u09be',
            icon: Icons.volunteer_activism_rounded,
            route: RouteNames.dua,
          ),
          (
            titleEn: 'Asma',
            titleBn: '\u0986\u09b8\u09ae\u09be',
            icon: Icons.nightlight_round,
            route: RouteNames.asma,
          ),
        ];

    final menuLinks =
        <({String titleEn, String titleBn, IconData icon, VoidCallback onTap})>[
          (
            titleEn: 'Calendar',
            titleBn:
                '\u0995\u09cd\u09af\u09be\u09b2\u09c7\u09a8\u09cd\u09a1\u09be\u09b0',
            icon: Icons.calendar_month_rounded,
            onTap: () =>
                Navigator.of(context).pushNamed(RouteNames.islamicCalendar),
          ),
          (
            titleEn: 'Find Mosque',
            titleBn: '\u09ae\u09b8\u099c\u09bf\u09a6',
            icon: Icons.location_city_rounded,
            onTap: () => Navigator.of(context).pushNamed(RouteNames.findMosque),
          ),
          (
            titleEn: 'Qibla',
            titleBn: '\u0995\u09bf\u09ac\u09b2\u09be',
            icon: Icons.near_me_rounded,
            onTap: () =>
                Navigator.of(context).pushNamed(RouteNames.prayerCompass),
          ),
          (
            titleEn: 'Prayer',
            titleBn: '\u09a8\u09be\u09ae\u09be\u099c',
            icon: Icons.schedule_rounded,
            onTap: () =>
                Navigator.of(context).pushNamed(RouteNames.prayerTimes),
          ),
          (
            titleEn: 'Tasbih',
            titleBn: '\u09a4\u09be\u09b8\u09ac\u09bf\u09b9',
            icon: Icons.exposure_plus_1_rounded,
            onTap: () => Navigator.of(context).pushNamed(RouteNames.tasbih),
          ),
          (
            titleEn: 'Zakat',
            titleBn: '\u09af\u09be\u0995\u09be\u09a4',
            icon: Icons.savings_rounded,
            onTap: () => unawaited(_openZakatCalculator()),
          ),
          (
            titleEn: 'Settings',
            titleBn: '\u09b8\u09c7\u099f\u09bf\u0982\u09b8',
            icon: Icons.settings_rounded,
            onTap: () =>
                Navigator.of(context).pushNamed(RouteNames.preferences),
          ),
        ];

    return _buildGlassCard(
      padding: const EdgeInsets.fromLTRB(11, 10, 11, 11),
      ornamentedCorners: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_awesome_outlined,
                size: 13,
                color: _accentGold,
              ),
              const SizedBox(width: 6),
              Text(
                _text(
                  'Quick Menu',
                  '\u09a6\u09cd\u09b0\u09c1\u09a4 \u09ae\u09c7\u09a8\u09c1',
                ),
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  foregroundColor: _accentStrong,
                ),
                onPressed: () =>
                    Navigator.of(context).pushNamed(RouteNames.discover),
                icon: const Icon(Icons.grid_view_rounded, size: 15),
                label: Text(
                  _text(
                    'Open Discover',
                    '\u09a1\u09bf\u09b8\u0995\u09ad\u09be\u09b0',
                  ),
                ),
              ),
            ],
          ),
          _ornamentDivider(padding: const EdgeInsets.only(top: 4, bottom: 8)),
          Row(
            children: [
              for (int i = 0; i < actions.length; i++) ...[
                Expanded(
                  child: _buildQuickActionCard(
                    title: _text(actions[i].titleEn, actions[i].titleBn),
                    icon: actions[i].icon,
                    onTap: () =>
                        Navigator.of(context).pushNamed(actions[i].route),
                  ),
                ),
                if (i != actions.length - 1) const SizedBox(width: 7),
              ],
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                for (int i = 0; i < menuLinks.length; i++) ...[
                  _buildMenuLinkChip(
                    title: _text(menuLinks[i].titleEn, menuLinks[i].titleBn),
                    icon: menuLinks[i].icon,
                    onTap: menuLinks[i].onTap,
                  ),
                  if (i != menuLinks.length - 1) const SizedBox(width: 7),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: _isDarkTheme
                  ? const [Color(0xFF1C2A39), Color(0xFF121E2B)]
                  : const [Color(0xFFF8FCFF), Color(0xFFECF5FB)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            border: Border.all(color: _surfaceBorder),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: _surfaceStrong,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: _accentSoft, size: 19),
              ),
              const SizedBox(height: 6),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuLinkChip({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: _isDarkTheme
                ? const Color(0xFF162433)
                : const Color(0xF8FFFFFF),
            border: Border.all(color: _surfaceBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: _accentSoft),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 11.2,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 10,
                color: _textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLastReadCard() {
    final secondary = _lastReadSecondaryLine();

    return _buildGlassCard(
      child: Row(
        children: [
          Icon(Icons.menu_book_rounded, color: _accentSoft, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _localizedLastReadLabel(),
                  style: TextStyle(
                    color: _textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _lastReadPrimaryLine(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (secondary != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    secondary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: _openLastRead,
            style: FilledButton.styleFrom(
              backgroundColor: _accentStrong,
              foregroundColor: _isDarkTheme
                  ? const Color(0xFF032F35)
                  : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
              textStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
            child: Text(_localizedContinueLabel()),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyActivityCard() {
    final items = _activities;
    // Both activity cards share the same row so they stay visible together,
    // side by side, without scrolling between them. IntrinsicHeight keeps the
    // two cards the same height even when their titles wrap differently.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int i = 0; i < items.length; i++) ...[
            Expanded(child: _buildActivityStatCard(items[i])),
            if (i != items.length - 1) const SizedBox(width: 12),
          ],
        ],
      ),
    );
  }

  Widget _buildActivityStatCard(ActivityItem item) {
    final progress = item.total == 0 ? 0.0 : item.done / item.total;
    final clamped = progress.clamp(0.0, 1.0);
    final percent = (clamped * 100).round();
    return _buildGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _surfaceStrong,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _activityIcon(item.title),
                  color: _accentSoft,
                  size: 18,
                ),
              ),
              const Spacer(),
              Text(
                _isBangla
                    ? '${_toBanglaDigits(percent.toString())}%'
                    : '$percent%',
                style: TextStyle(
                  color: _accentStrong,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            item.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: clamped,
              minHeight: 7,
              backgroundColor: _isDarkTheme
                  ? const Color(0xFF1B2D3E)
                  : const Color(0xFFD8E7F1),
              valueColor: AlwaysStoppedAnimation<Color>(_accentStrong),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_localizedCount(item.done)}/${_localizedCount(item.total)}',
            style: TextStyle(
              color: _textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  IconData _activityIcon(String title) {
    final value = title.toLowerCase();
    if (value.contains('alms') || value.contains('zakat')) {
      return Icons.volunteer_activism_rounded;
    }
    if (value.contains('quran') || value.contains('recite')) {
      return Icons.menu_book_rounded;
    }
    return Icons.check_circle_outline_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isDarkTheme
          ? const Color(0xFF060C17)
          : const Color(0xFFF0F7FC),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _isDarkTheme
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
        child: Stack(
          children: [
            Positioned.fill(
              child: Opacity(
                opacity: _isDarkTheme ? 0.08 : 1.0,
                child: Image.asset(
                  'assets/397.png',
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                ),
              ),
            ),
            Positioned(
              top: -120,
              left: -80,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: _isDarkTheme
                        ? const [Color(0x3323DFCC), Color(0x00060C17)]
                        : const [Color(0x4423DFCC), Color(0x00FFFFFF)],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 80,
              right: -90,
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: _isDarkTheme
                        ? const [Color(0x2230A4CF), Color(0x0008111B)]
                        : const [Color(0x3330A4CF), Color(0x00FFFFFF)],
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: RefreshIndicator(
                      color: _isDarkTheme
                          ? const Color(0xFF1FD5C0)
                          : const Color(0xFF1EA8B8),
                      backgroundColor: _isDarkTheme
                          ? const Color(0xFF102233)
                          : const Color(0xFFFFFFFF),
                      onRefresh: () =>
                          _refreshPrayerScheduleFromSource(forceRefresh: true),
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(14, 10, 14, 18),
                        children: [
                          _buildSunArcCard(),
                          if (_isLastThirdOfNight()) ...[
                            const SizedBox(height: 12),
                            _buildTahajjudReminderCard(),
                          ],
                          const SizedBox(height: 12),
                          _buildTopHeader(),
                          const SizedBox(height: 12),
                          _buildPrayerStrip(),
                          const SizedBox(height: 12),
                          _buildQiblaAndCountdownRow(),
                          const SizedBox(height: 12),
                          _buildMosquePreviewCard(),
                          const SizedBox(height: 12),
                          _buildQuickActions(),
                          if (kQuranFeatureEnabled) ...[
                            const SizedBox(height: 12),
                            _buildLastReadCard(),
                          ],
                          const SizedBox(height: 12),
                          _buildDailyActivityCard(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniCompassMarksPainter extends CustomPainter {
  const _MiniCompassMarksPainter({required this.isDark});

  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final majorTickPaint = Paint()
      ..color = isDark ? const Color(0xFF8AA4B8) : const Color(0xFF6A8EA4)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    final minorTickPaint = Paint()
      ..color = isDark ? const Color(0xFF9CB3C3) : const Color(0xFF86A5B9)
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 36; i++) {
      final angle = (i * 10) * math.pi / 180;
      final major = i % 3 == 0;
      final inner = radius - (major ? 9 : 5);
      final p1 = Offset(
        center.dx + inner * math.sin(angle),
        center.dy - inner * math.cos(angle),
      );
      final p2 = Offset(
        center.dx + (radius - 2) * math.sin(angle),
        center.dy - (radius - 2) * math.cos(angle),
      );
      canvas.drawLine(p1, p2, major ? majorTickPaint : minorTickPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _MiniCompassMarksPainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}

class _MiniQiblaNeedlePainter extends CustomPainter {
  const _MiniQiblaNeedlePainter({required this.isDark});

  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const tipY = 13.0;
    final needleColor = isDark
        ? const Color(0xFF21D6C2)
        : const Color(0xFF1EA8B8);

    final glowPaint = Paint()
      ..color = isDark ? const Color(0x6621D6C2) : const Color(0x551EA8B8)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    final linePaint = Paint()
      ..color = needleColor
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(center, Offset(center.dx, tipY + 10), glowPaint);
    canvas.drawLine(center, Offset(center.dx, tipY + 10), linePaint);

    final arrow = Path()
      ..moveTo(center.dx, tipY)
      ..lineTo(center.dx - 4.8, tipY + 8)
      ..lineTo(center.dx + 4.8, tipY + 8)
      ..close();
    canvas.drawPath(arrow, Paint()..color = needleColor);
  }

  @override
  bool shouldRepaint(covariant _MiniQiblaNeedlePainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}

class _SunArcPainter extends CustomPainter {
  const _SunArcPainter({
    required this.progress,
    required this.accentStrong,
    required this.accentSoft,
    required this.accentGold,
    required this.trackColor,
    required this.isDark,
  });

  final double progress;
  final Color accentStrong;
  final Color accentSoft;
  final Color accentGold;
  final Color trackColor;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final radius = math.min(w / 2 - 8, h - 18);
    final baseY = h - 8;
    final center = Offset(cx, baseY);

    final dashedTrack = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    final dashCount = 56;
    for (var i = 0; i < dashCount; i++) {
      final t = i / dashCount;
      final angle = math.pi - (math.pi * t);
      final inner = radius - 2;
      final outer = radius + 2;
      final p1 = Offset(
        center.dx + inner * math.cos(angle),
        center.dy - inner * math.sin(angle),
      );
      final p2 = Offset(
        center.dx + outer * math.cos(angle),
        center.dy - outer * math.sin(angle),
      );
      if (i % 2 == 0) {
        canvas.drawLine(p1, p2, dashedTrack);
      }
    }

    final arcRect = Rect.fromCircle(center: center, radius: radius);
    final filledSweep = math.pi * progress.clamp(0.0, 1.0);
    final filledPaint = Paint()
      ..shader = LinearGradient(
        colors: [accentSoft, accentStrong],
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
      ).createShader(arcRect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(arcRect, math.pi, filledSweep, false, filledPaint);

    final ground = Paint()
      ..color = trackColor
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(8, baseY),
      Offset(w - 8, baseY),
      ground,
    );

    final mosqueColor = (isDark ? Colors.white : const Color(0xFF1F4E66))
        .withValues(alpha: isDark ? 0.06 : 0.07);
    final mosquePaint = Paint()..color = mosqueColor;
    final domeRadius = radius * 0.32;
    final domeCenter = Offset(cx, baseY - domeRadius * 0.55);
    final domePath = Path()
      ..moveTo(domeCenter.dx - domeRadius, baseY)
      ..lineTo(domeCenter.dx - domeRadius, domeCenter.dy)
      ..arcToPoint(
        Offset(domeCenter.dx + domeRadius, domeCenter.dy),
        radius: Radius.circular(domeRadius),
      )
      ..lineTo(domeCenter.dx + domeRadius, baseY)
      ..close();
    canvas.drawPath(domePath, mosquePaint);

    canvas.drawRect(
      Rect.fromLTWH(
        cx - domeRadius * 1.7,
        baseY - domeRadius * 0.55,
        domeRadius * 0.35,
        domeRadius * 0.55,
      ),
      mosquePaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        cx + domeRadius * 1.35,
        baseY - domeRadius * 0.55,
        domeRadius * 0.35,
        domeRadius * 0.55,
      ),
      mosquePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _SunArcPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.accentStrong != accentStrong ||
      oldDelegate.accentSoft != accentSoft ||
      oldDelegate.trackColor != trackColor ||
      oldDelegate.isDark != isDark;
}

class _SunIconMarker extends StatelessWidget {
  const _SunIconMarker({required this.color, this.scale = 1.0});

  final Color color;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final iconSize = 13.0 * scale;
    final glowBlur = 10.0 + (scale - 1.0) * 14.0;
    final glowSpread = 0.6 + (scale - 1.0) * 1.0;
    return Container(
      width: iconSize + 6,
      height: iconSize + 6,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.55),
            blurRadius: glowBlur,
            spreadRadius: glowSpread,
          ),
        ],
      ),
      child: Icon(
        Icons.wb_sunny_rounded,
        size: iconSize,
        color: Colors.white,
      ),
    );
  }
}

class _ArcLabel extends StatelessWidget {
  const _ArcLabel({
    required this.title,
    required this.time,
    required this.titleColor,
    required this.timeColor,
    this.trailing,
  });

  final String title;
  final String time;
  final Color titleColor;
  final Color timeColor;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(
                color: titleColor,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 3),
              trailing!,
            ],
          ],
        ),
        const SizedBox(height: 1),
        Text(
          time,
          style: TextStyle(
            color: timeColor,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _ArcEndpoint extends StatelessWidget {
  const _ArcEndpoint({
    required this.icon,
    required this.time,
    required this.iconColor,
    required this.textColor,
    this.alignRight = false,
  });

  final IconData icon;
  final String time;
  final Color iconColor;
  final Color textColor;
  final bool alignRight;

  @override
  Widget build(BuildContext context) {
    final children = [
      Icon(icon, size: 12, color: iconColor),
      const SizedBox(width: 3),
      Text(
        time,
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    ];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: alignRight ? children.reversed.toList() : children,
    );
  }
}

class _SunArcArea extends StatefulWidget {
  const _SunArcArea({
    required this.currentProgress,
    required this.isBangla,
    required this.accentStrong,
    required this.accentSoft,
    required this.accentGold,
    required this.trackColor,
    required this.isDark,
    required this.textPrimary,
    required this.textSecondary,
    required this.leadingTitle,
    required this.leadingTimeLabel,
    required this.trailingTitle,
    required this.trailingTimeLabel,
    required this.sunriseClockText,
    required this.sunsetClockText,
    required this.middayTimeLabel,
  });

  final double currentProgress;
  final bool isBangla;
  final Color accentStrong;
  final Color accentSoft;
  final Color accentGold;
  final Color trackColor;
  final bool isDark;
  final Color textPrimary;
  final Color textSecondary;
  final String leadingTitle;
  final String leadingTimeLabel;
  final String trailingTitle;
  final String trailingTimeLabel;
  final String sunriseClockText;
  final String sunsetClockText;
  final String middayTimeLabel;

  @override
  State<_SunArcArea> createState() => _SunArcAreaState();
}

class _SunArcAreaState extends State<_SunArcArea>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );
    _controller.value = widget.currentProgress.clamp(0.0, 1.0);
  }

  @override
  void didUpdateWidget(_SunArcArea old) {
    super.didUpdateWidget(old);
    if (!_controller.isAnimating &&
        old.currentProgress != widget.currentProgress) {
      _controller.value = widget.currentProgress.clamp(0.0, 1.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _replay() {
    _controller.stop();
    _controller.value = 0.0;
    _controller.animateTo(widget.currentProgress.clamp(0.0, 1.0));
  }

  double _sunIconScale(double progress) {
    // Sun appears largest near the apex (midday), smaller near the horizon.
    final fromCenter = (progress - 0.5).abs() * 2; // 0 at apex, 1 at edges
    return 1.0 + (1.0 - fromCenter) * 0.55;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _replay,
      behavior: HitTestBehavior.opaque,
      child: AspectRatio(
        aspectRatio: 2.7,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final h = constraints.maxHeight;
            final cx = w / 2;
            final baseY = h - 6;
            final radius = math.min(w / 2 - 6, h - 14);
            final apexY = baseY - radius;

            return AnimatedBuilder(
              animation: _animation,
              builder: (context, _) {
                final progress = _animation.value.clamp(0.0, 1.0);
                final angle = math.pi * (1 - progress);
                final sunDx = cx + radius * math.cos(angle);
                final sunDy = baseY - radius * math.sin(angle);
                final iconScale = _sunIconScale(progress);

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _SunArcPainter(
                          progress: progress,
                          accentStrong: widget.accentStrong,
                          accentSoft: widget.accentSoft,
                          accentGold: widget.accentGold,
                          trackColor: widget.trackColor,
                          isDark: widget.isDark,
                        ),
                      ),
                    ),
                    Positioned(
                      left: cx,
                      top: apexY - 16,
                      child: FractionalTranslation(
                        translation: const Offset(-0.5, 0),
                        child: Text(
                          widget.middayTimeLabel,
                          style: TextStyle(
                            color: widget.textPrimary,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: sunDx,
                      top: sunDy,
                      child: FractionalTranslation(
                        translation: const Offset(-0.5, -0.5),
                        child: _SunIconMarker(
                          color: widget.accentGold,
                          scale: iconScale,
                        ),
                      ),
                    ),
                    Align(
                      alignment: const Alignment(-0.55, -0.15),
                      child: _ArcLabel(
                        title: widget.leadingTitle,
                        time: widget.leadingTimeLabel,
                        titleColor: widget.textPrimary,
                        timeColor: widget.textSecondary,
                      ),
                    ),
                    Align(
                      alignment: const Alignment(0.55, -0.15),
                      child: _ArcLabel(
                        title: widget.trailingTitle,
                        time: widget.trailingTimeLabel,
                        titleColor: widget.textPrimary,
                        timeColor: widget.textSecondary,
                        trailing: Icon(
                          Icons.check_circle_rounded,
                          size: 11,
                          color: widget.accentStrong,
                        ),
                      ),
                    ),
                    Positioned(
                      left: -2,
                      bottom: -2,
                      child: _ArcEndpoint(
                        icon: Icons.wb_twilight_rounded,
                        time: widget.sunriseClockText,
                        iconColor: widget.accentGold,
                        textColor: widget.textSecondary,
                      ),
                    ),
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: _ArcEndpoint(
                        icon: Icons.wb_sunny_rounded,
                        time: widget.sunsetClockText,
                        iconColor: widget.accentGold,
                        textColor: widget.textSecondary,
                        alignRight: true,
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _MiniKaabaMarker extends StatelessWidget {
  const _MiniKaabaMarker({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDark ? const Color(0xFF0F1E2A) : const Color(0xFFEAF3F9),
        border: Border.all(
          color: isDark ? const Color(0x66FFFFFF) : const Color(0xFFBDD2E2),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? const Color(0x5521D6C2) : const Color(0x331EA8B8),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      padding: const EdgeInsets.all(3),
      child: ClipOval(
        child: Image.asset(
          'assets/kakbah.png',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Icon(
              Icons.location_on_rounded,
              size: 14,
              color: isDark ? const Color(0xFF21D6C2) : const Color(0xFF1EA8B8),
            );
          },
        ),
      ),
    );
  }
}

/// A single twinkling star, with positions expressed as fractions of the
/// painting area so the field scales with the card.
class _NightStar {
  const _NightStar({
    required this.dxFraction,
    required this.dyFraction,
    required this.radius,
    required this.phase,
  });

  final double dxFraction;
  final double dyFraction;
  final double radius;
  final double phase;
}

/// Nighttime counterpart of [_SunArcArea]: a moon rides the Maghrib→Fajr arc
/// over a calm starfield, with the last third of the night highlighted in gold.
class _MoonArcArea extends StatefulWidget {
  const _MoonArcArea({
    required this.progress,
    required this.isLastThird,
    required this.maghribLabel,
    required this.fajrLabel,
    required this.midnightLabel,
    required this.tahajjudLabel,
    required this.maghribClock,
    required this.fajrClock,
    required this.tahajjudClock,
  });

  final double progress;
  final bool isLastThird;
  final String maghribLabel;
  final String fajrLabel;
  final String midnightLabel;
  final String tahajjudLabel;
  final String maghribClock;
  final String fajrClock;
  final String tahajjudClock;

  @override
  State<_MoonArcArea> createState() => _MoonArcAreaState();
}

class _MoonArcAreaState extends State<_MoonArcArea>
    with TickerProviderStateMixin {
  late final AnimationController _progressController;
  late final Animation<double> _progressAnimation;
  late final AnimationController _twinkleController;
  late final List<_NightStar> _stars;

  static const Color _silver = Color(0xFFDCE7FF);
  static const Color _silverSoft = Color(0xFF8FA6D6);
  static const Color _indigo = Color(0xFF6E8BD8);
  static const Color _gold = Color(0xFFE9D8A6);

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    );
    _progressAnimation = CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOutCubic,
    );
    _progressController.animateTo(widget.progress.clamp(0.0, 1.0));
    _twinkleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    final random = math.Random(7);
    _stars = List<_NightStar>.generate(16, (_) {
      return _NightStar(
        dxFraction: random.nextDouble(),
        // Keep stars in the upper sky, away from the ground/labels.
        dyFraction: random.nextDouble() * 0.62,
        radius: 0.6 + random.nextDouble() * 1.4,
        phase: random.nextDouble() * math.pi * 2,
      );
    });
  }

  @override
  void didUpdateWidget(_MoonArcArea old) {
    super.didUpdateWidget(old);
    if (!_progressController.isAnimating &&
        old.progress != widget.progress) {
      _progressController.value = widget.progress.clamp(0.0, 1.0);
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    _twinkleController.dispose();
    super.dispose();
  }

  void _replay() {
    _progressController
      ..stop()
      ..value = 0.0
      ..animateTo(widget.progress.clamp(0.0, 1.0));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _replay,
      behavior: HitTestBehavior.opaque,
      child: AspectRatio(
        aspectRatio: 2.7,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final h = constraints.maxHeight;
            final cx = w / 2;
            final baseY = h - 6;
            final radius = math.min(w / 2 - 6, h - 14);
            final apexY = baseY - radius;

            return AnimatedBuilder(
              animation: Listenable.merge([
                _progressAnimation,
                _twinkleController,
              ]),
              builder: (context, _) {
                final progress = _progressAnimation.value.clamp(0.0, 1.0);
                final angle = math.pi * (1 - progress);
                final moonDx = cx + radius * math.cos(angle);
                final moonDy = baseY - radius * math.sin(angle);

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _MoonArcPainter(
                          progress: progress,
                          twinkle: _twinkleController.value,
                          stars: _stars,
                          silver: _silver,
                          silverSoft: _silverSoft,
                          indigo: _indigo,
                          gold: _gold,
                          isLastThird: widget.isLastThird,
                        ),
                      ),
                    ),
                    Positioned(
                      left: cx,
                      top: apexY - 16,
                      child: FractionalTranslation(
                        translation: const Offset(-0.5, 0),
                        child: Text(
                          widget.midnightLabel,
                          style: const TextStyle(
                            color: _silver,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: moonDx,
                      top: moonDy,
                      child: FractionalTranslation(
                        translation: const Offset(-0.5, -0.5),
                        child: _MoonMarker(
                          highlight: widget.isLastThird,
                          gold: _gold,
                          silver: _silver,
                        ),
                      ),
                    ),
                    Align(
                      alignment: const Alignment(0.32, -0.18),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.tahajjudLabel,
                            style: TextStyle(
                              color: widget.isLastThird ? _gold : _silverSoft,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            widget.tahajjudClock,
                            style: const TextStyle(
                              color: _silverSoft,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      left: -2,
                      bottom: -2,
                      child: _MoonEndpoint(
                        icon: Icons.brightness_3_rounded,
                        label: widget.maghribLabel,
                        time: widget.maghribClock,
                        color: _silver,
                        subColor: _silverSoft,
                      ),
                    ),
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: _MoonEndpoint(
                        icon: Icons.wb_twilight_rounded,
                        label: widget.fajrLabel,
                        time: widget.fajrClock,
                        color: _silver,
                        subColor: _silverSoft,
                        alignRight: true,
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _MoonMarker extends StatelessWidget {
  const _MoonMarker({
    required this.highlight,
    required this.gold,
    required this.silver,
  });

  final bool highlight;
  final Color gold;
  final Color silver;

  @override
  Widget build(BuildContext context) {
    final base = highlight ? gold : silver;
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: base,
        boxShadow: [
          BoxShadow(
            color: base.withValues(alpha: highlight ? 0.7 : 0.5),
            blurRadius: highlight ? 18 : 12,
            spreadRadius: highlight ? 2 : 1,
          ),
        ],
      ),
      child: Icon(
        Icons.nightlight_round,
        size: 13,
        color: const Color(0xFF101A36),
      ),
    );
  }
}

class _MoonEndpoint extends StatelessWidget {
  const _MoonEndpoint({
    required this.icon,
    required this.label,
    required this.time,
    required this.color,
    required this.subColor,
    this.alignRight = false,
  });

  final IconData icon;
  final String label;
  final String time;
  final Color color;
  final Color subColor;
  final bool alignRight;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignRight
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 3),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        Text(
          time,
          style: TextStyle(
            color: subColor,
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _MoonArcPainter extends CustomPainter {
  const _MoonArcPainter({
    required this.progress,
    required this.twinkle,
    required this.stars,
    required this.silver,
    required this.silverSoft,
    required this.indigo,
    required this.gold,
    required this.isLastThird,
  });

  final double progress;
  final double twinkle;
  final List<_NightStar> stars;
  final Color silver;
  final Color silverSoft;
  final Color indigo;
  final Color gold;
  final bool isLastThird;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final radius = math.min(w / 2 - 6, h - 14);
    final baseY = h - 6;
    final center = Offset(cx, baseY);

    // Twinkling stars across the upper sky.
    for (final star in stars) {
      final twinklePhase = math.sin(twinkle * 2 * math.pi + star.phase);
      final alpha = (0.35 + 0.45 * ((twinklePhase + 1) / 2)).clamp(0.0, 1.0);
      final paint = Paint()
        ..color = silver.withValues(alpha: alpha)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(star.dxFraction * w, star.dyFraction * (baseY - 4)),
        star.radius,
        paint,
      );
    }

    // Dashed arc track.
    final dashedTrack = Paint()
      ..color = silverSoft.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round;
    const dashCount = 56;
    for (var i = 0; i < dashCount; i++) {
      if (i.isOdd) continue;
      final t = i / dashCount;
      final angle = math.pi - (math.pi * t);
      final p1 = Offset(
        center.dx + (radius - 2) * math.cos(angle),
        center.dy - (radius - 2) * math.sin(angle),
      );
      final p2 = Offset(
        center.dx + (radius + 2) * math.cos(angle),
        center.dy - (radius + 2) * math.sin(angle),
      );
      canvas.drawLine(p1, p2, dashedTrack);
    }

    // Filled arc up to the current night progress.
    final arcRect = Rect.fromCircle(center: center, radius: radius);
    final filledSweep = math.pi * progress.clamp(0.0, 1.0);
    final filledPaint = Paint()
      ..shader = LinearGradient(
        colors: [indigo, silver],
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
      ).createShader(arcRect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(arcRect, math.pi, filledSweep, false, filledPaint);

    // Ground line.
    final ground = Paint()
      ..color = silverSoft.withValues(alpha: 0.4)
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(8, baseY), Offset(w - 8, baseY), ground);

    // Tahajjud onset marker at two-thirds of the night.
    const tahajjudFraction = 2 / 3;
    final tahajjudAngle = math.pi * (1 - tahajjudFraction);
    final tickInner = Offset(
      center.dx + (radius - 5) * math.cos(tahajjudAngle),
      center.dy - (radius - 5) * math.sin(tahajjudAngle),
    );
    final tickOuter = Offset(
      center.dx + (radius + 5) * math.cos(tahajjudAngle),
      center.dy - (radius + 5) * math.sin(tahajjudAngle),
    );
    final tickPaint = Paint()
      ..color = gold.withValues(alpha: isLastThird ? 1 : 0.7)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(tickInner, tickOuter, tickPaint);
  }

  @override
  bool shouldRepaint(covariant _MoonArcPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.twinkle != twinkle ||
      oldDelegate.isLastThird != isLastThird;
}
