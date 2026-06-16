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

  /// Formats a remaining duration as a live countdown that ticks down to the
  /// second. Hours and minutes are dropped once they reach zero so the label
  /// stays compact (e.g. `1h 04m 09s` → `04m 09s` → `09s`).
  String _liveCountdownLabel(Duration value) {
    final safe = value.isNegative ? Duration.zero : value;
    final hours = safe.inHours;
    final minutes = safe.inMinutes % 60;
    final seconds = safe.inSeconds % 60;
    if (_isBangla) {
      final hh = _toBanglaDigits(hours.toString().padLeft(2, '0'));
      final mm = _toBanglaDigits(minutes.toString().padLeft(2, '0'));
      final ss = _toBanglaDigits(seconds.toString().padLeft(2, '0'));
      if (hours > 0) return '$hh ঘণ্টা $mm মিনিট $ss সেকেন্ড';
      if (minutes > 0) return '$mm মিনিট $ss সেকেন্ড';
      return '$ss সেকেন্ড';
    }
    final hh = hours.toString().padLeft(2, '0');
    final mm = minutes.toString().padLeft(2, '0');
    final ss = seconds.toString().padLeft(2, '0');
    if (hours > 0) return '${hh}h ${mm}m ${ss}s';
    if (minutes > 0) return '${mm}m ${ss}s';
    return '${ss}s';
  }

  String _activePrayerProgressLabel() {
    final remaining = _activeRemaining.isNegative
        ? Duration.zero
        : _activeRemaining;
    return _isBangla
        ? '${_liveCountdownLabel(remaining)} বাকি'
        : '${_liveCountdownLabel(remaining)} left';
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

  /// The prayer currently *in progress* during the daytime strip. [_activePrayer]
  /// now holds the prayer currently in progress — e.g. between Zuhr and Asr it
  /// is Zuhr, spanning Zuhr → Asr. Returns null for the Fajr→Zuhr forenoon
  /// (where [_activePrayer] is Fajr), which is shown as Chasht instead.
  ({String key, DateTime start, DateTime end})? _ongoingDayPrayer() {
    final schedule = _todaySchedule;
    if (schedule == null) return null;
    switch (_activePrayer) {
      case 'Zuhr':
        return (key: 'Zuhr', start: schedule.dzuhr, end: schedule.ashr);
      case 'Asr':
        return (key: 'Asr', start: schedule.ashr, end: schedule.maghrib);
      default:
        return null;
    }
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
                '$_formattedHijriDate',
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
            ),
            SizedBox(width: 6.w),
            Icon(Icons.nightlight_round, size: 12.sp, color: _accentGold),
          ],
        ),
        SizedBox(height: 4.h),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _formattedTimeWithSeconds,
              style: TextStyle(
                color: _textPrimary,
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
            Expanded(
              child: Text(
                _activeHeaderDate,
                maxLines: 2,
                textAlign: TextAlign.right,
                overflow: TextOverflow.visible,
                style: TextStyle(
                  color: _textSecondary,
                  fontSize: 9.sp,
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
  /// Progress is linear in real time across daylight: 0 at sunrise, 1 at
  /// sunset, so the sun moves at a steady pace and crests (0.5) at the midpoint
  /// of the day. The actual sunrise is used when available — Fajr (dawn) is
  /// ~1.5h earlier and would skew the whole morning half.
  double _sunPathProgress() {
    final schedule = _todaySchedule;
    if (schedule == null) return 0.5;
    final sunrise = schedule.sunrise ?? schedule.fajr;
    final sunset = schedule.maghrib;

    if (!_now.isAfter(sunrise)) return 0.0;
    if (!_now.isBefore(sunset)) return 1.0;

    final total = sunset.difference(sunrise).inSeconds;
    if (total <= 0) return 0.5;
    final elapsed = _now.difference(sunrise).inSeconds;
    return (elapsed / total).clamp(0.0, 1.0);
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

  String _profileDisplayName([String? rawName]) {
    final value = (rawName ?? profileNameNotifier.value).trim();
    return value;
  }

  String _profileInitial([String? rawName]) {
    final name = _profileDisplayName(rawName);
    return name.isEmpty ? 'N' : name[0].toUpperCase();
  }

  bool _hasProfileName([String? rawName]) =>
      _profileDisplayName(rawName).isNotEmpty;
  String _greetingText() {
    final hour = _now.hour;
    if (hour < 12) return _text('Assalamu Alaikum,', 'আসসালামু আলাইকুম,');
    if (hour < 17) return _text('Good Afternoon,', 'শুভ অপরাহ্ন,');
    return _text('Good Evening,', 'শুভ সন্ধ্যা,');
  }

  /// Sun (daytime) or moon (nighttime) progress card. The two halves of the day
  /// track separately: the sun arc covers Fajr→Maghrib, the moon arc covers
  /// Maghrib→Fajr.
  Widget _buildSunArcCard() {
    final isNight = _isNightTime;
    return _buildGlassCard(
      padding: EdgeInsets.fromLTRB(14.w, 10.h, 14.w, 10.h),
      ornamentedCorners: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                                  radius: 16.r,
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
                                                  fontSize: 13.sp,
                                                ),
                                              )
                                            : Icon(
                                                Icons.auto_awesome_rounded,
                                                size: 16.sp,
                                                color: _isDarkTheme
                                                    ? const Color(0xFF9EE7F4)
                                                    : const Color(0xFF1EA8B8),
                                              ))
                                      : null,
                                ),
                                SizedBox(width: 18.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Row(
                                      //   children: [
                                      //     Icon(
                                      //       Icons.nightlight_round,
                                      //       size: 12.sp,
                                      //       color: _accentGold,
                                      //     ),
                                      //     SizedBox(width: 5.w),
                                      //     Flexible(
                                      //       child: Text(
                                      //         _greetingText(),
                                      //         maxLines: 1,
                                      //         overflow: TextOverflow.ellipsis,
                                      //         style: TextStyle(
                                      //           color: _isDarkTheme
                                      //               ? const Color(0xB3D8E5F7)
                                      //               : const Color(0xFF4B687F),
                                      //           fontSize: 10.sp,
                                      //           fontWeight: FontWeight.w500,
                                      //           letterSpacing: 0.2,
                                      //         ),
                                      //       ),
                                      //     ),
                                      //
                                      //   ],
                                      // ),
                                      SizedBox(height: 2.h),
                                      if (hasName)
                                        Text(
                                          _profileDisplayName(profileName),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: _textPrimary,
                                            fontSize: 14.sp,
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
                                            999.r,
                                          ),
                                          child: Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 10.w,
                                              vertical: 5.h,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _isDarkTheme
                                                  ? const Color(0x2D2EB8E6)
                                                  : const Color(0x251EA8B8),
                                              borderRadius:
                                                  BorderRadius.circular(999.r),
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
                                                fontSize: 11.5.sp,
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
                borderRadius: BorderRadius.circular(12.r),
                child: InkWell(
                  onTap: () =>
                      Navigator.of(context).pushNamed(RouteNames.notifications),
                  borderRadius: BorderRadius.circular(12.r),
                  child: Padding(
                    padding: EdgeInsets.all(10.r),
                    child: Icon(
                      Icons.notifications_none_rounded,
                      color: _isDarkTheme
                          ? const Color(0xFFB6CFE5)
                          : const Color(0xFF47677E),
                      size: 20.sp,
                    ),
                  ),
                ),
              ),
            ],
          ),


           _buildHeroDateStripContent(),
          _ornamentDivider(
            padding: EdgeInsets.only(top: 4.h, bottom: 4.h),
          ),
          SizedBox(height: 8.h),

          if (isNight) _buildMoonArcArea() else _buildSunArcArea(),

          SizedBox(height: 10.h),
          if (_activeForbiddenWindow() != null)
            ..._buildForbiddenProgressSection()
          else if (isNight)
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
    final ashr = schedule?.ashr;
    final chasht = _chashtTime();

    // The two arc shoulders name the prayer currently in progress (leading,
    // rising side) and the one coming next (trailing). Daylight passes through
    // three windows: the forenoon shown as Chasht→Zuhr, then Zuhr→Asr, then
    // Asr→Maghrib. At e.g. 1pm — past Zuhr but before Asr — Zuhr is ongoing and
    // Asr is next, so those two are shown rather than Asr→Maghrib.
    final beforeZuhr = dzuhr == null ? _now.hour < 12 : _now.isBefore(dzuhr);
    final beforeAsr = ashr == null ? _now.hour < 16 : _now.isBefore(ashr);

    final String leadingTitle;
    final String leadingTimeLabel;
    final String trailingTitle;
    final String trailingTimeLabel;
    if (beforeZuhr) {
      leadingTitle = _text('Chasht', 'চাশত');
      leadingTimeLabel = _skyClock(chasht);
      trailingTitle = _text('Zuhr', 'যুহর');
      trailingTimeLabel = _skyClock(dzuhr);
    } else if (beforeAsr) {
      leadingTitle = _text('Zuhr', 'যুহর');
      leadingTimeLabel = _skyClock(dzuhr);
      trailingTitle = _text('Asr', 'আসর');
      trailingTimeLabel = _skyClock(ashr);
    } else {
      leadingTitle = _text('Asr', 'আসর');
      leadingTimeLabel = _skyClock(ashr);
      trailingTitle = _text('Maghrib', 'মাগরিব');
      trailingTimeLabel = _skyClock(schedule?.maghrib);
    }

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
      sunriseClockText: _skyClock(schedule?.sunrise ?? schedule?.fajr),
      sunsetClockText: _skyClock(schedule?.maghrib),
      currentTimeLabel: _skyClock(_now),
      replayTick: _arcReplayTick,
    );
  }

  List<Widget> _buildDayProgressSection() {
    final schedule = _todaySchedule;
    final dzuhr = schedule?.dzuhr;
    final chasht = _chashtTime();
    // The progress strip presents the forenoon window as the Chasht period.
    // The forenoon runs Fajr→Zuhr, so the in-progress prayer is Fajr.
    final isChasht = _activePrayer == 'Fajr';
    // Outside the forenoon, name the prayer currently in progress (e.g. Zuhr
    // between Zuhr and Asr) and show its matching Zuhr→Asr window, rather than
    // the upcoming prayer.
    final ongoing = _ongoingDayPrayer();
    final segmentName = isChasht
        ? _text('Chasht', 'চাশত')
        : _localizedPrayerName(ongoing?.key ?? _activePrayer);
    final segmentWindow = isChasht
        ? _windowLabel(chasht, dzuhr)
        : (ongoing != null
              ? _windowLabel(ongoing.start, ongoing.end)
              : _activePrayerWindowLabel());
    final segmentProgress = isChasht
        ? _segmentProgress(chasht, dzuhr)
        : (ongoing != null
              ? _segmentProgress(ongoing.start, ongoing.end)
              : _activeProgress.clamp(0.0, 1.0));

    return [
      Row(
        children: [
          Text(
            segmentName,
            style: TextStyle(
              color: _textPrimary,
              fontSize: 11.5.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          Text(
            segmentWindow,
            style: TextStyle(
              color: _textSecondary,
              fontSize: 10.5.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      SizedBox(height: 5.h),
      ClipRRect(
        borderRadius: BorderRadius.circular(999.r),
        child: LinearProgressIndicator(
          value: segmentProgress,
          minHeight: 3.h,
          backgroundColor: _isDarkTheme
              ? const Color(0xFF1B2D3E)
              : const Color(0xFFD8E7F1),
          valueColor: AlwaysStoppedAnimation<Color>(_accentStrong),
        ),
      ),
      SizedBox(height: 5.h),
      Row(
        children: [
          Container(
            width: 6.w,
            height: 6.h,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _accentStrong,
            ),
          ),
          SizedBox(width: 5.w),
          Text(
            _text('Ongoing', 'চলমান'),
            style: TextStyle(
              color: _accentStrong,
              fontSize: 10.5.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          Text(
            _activePrayerProgressLabel(),
            style: TextStyle(
              color: _textSecondary,
              fontSize: 10.5.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    ];
  }

  /// Warning palette for the forbidden (Sunnah/Nafl prohibited) windows, kept
  /// in step with the dedicated forbidden-times card.
  Color get _forbiddenWarn =>
      _isDarkTheme ? const Color(0xFFFF8A6B) : const Color(0xFFD24A28);

  /// The forbidden prayer window currently in progress, or null when none is
  /// active. Boundaries mirror the forbidden-times card:
  ///   • Sunrise: sunrise → sunrise + 15 min
  ///   • Zawal:   Dhuhr − 2 min → Dhuhr
  ///   • Sunset:  Maghrib − 14 min → Maghrib
  ({IconData icon, String name, DateTime start, DateTime end})?
  _activeForbiddenWindow() {
    final schedule = _todaySchedule;
    if (schedule == null) return null;
    final sunrise = schedule.sunrise ?? schedule.fajr;
    final dhuhr = schedule.dzuhr;
    final maghrib = schedule.maghrib;

    final periods =
        <({IconData icon, String name, DateTime start, DateTime end})>[
          (
            icon: Icons.wb_twilight_rounded,
            name: _text('Sunrise', 'সূর্যোদয়'),
            start: sunrise,
            end: sunrise.add(const Duration(minutes: 15)),
          ),
          (
            icon: Icons.wb_sunny_rounded,
            name: _text('Zawal', 'যাওয়াল'),
            start: dhuhr.subtract(const Duration(minutes: 2)),
            end: dhuhr,
          ),
          (
            icon: Icons.brightness_4_rounded,
            name: _text('Sunset', 'সূর্যাস্ত'),
            start: maghrib.subtract(const Duration(minutes: 14)),
            end: maghrib,
          ),
        ];

    for (final period in periods) {
      if (!_now.isBefore(period.start) && _now.isBefore(period.end)) {
        return period;
      }
    }
    return null;
  }

  String _forbiddenRemainingLabel(Duration value) {
    final safe = value.isNegative ? Duration.zero : value;
    final minutes = safe.inMinutes;
    final seconds = safe.inSeconds % 60;
    if (_isBangla) {
      final mm = _toBanglaDigits(minutes.toString());
      final ss = _toBanglaDigits(seconds.toString());
      return minutes > 0 ? '$mm মিনিট $ss সেকেন্ড' : '$ss সেকেন্ড';
    }
    return minutes > 0 ? '${minutes}m ${seconds}s' : '${seconds}s';
  }

  /// Progress strip for an in-progress forbidden window, rendered in the warning
  /// palette so it visibly stands apart from the normal day/night progress.
  List<Widget> _buildForbiddenProgressSection() {
    final window = _activeForbiddenWindow();
    if (window == null) return const [];
    final warn = _forbiddenWarn;
    final progress = _segmentProgress(window.start, window.end);
    final remaining = window.end.difference(_now);

    return [
      Row(
        children: [
          Icon(window.icon, size: 13.sp, color: warn),
          SizedBox(width: 6.w),
          Expanded(
            child: Text(
              '${_text('Forbidden', 'নিষিদ্ধ')} · ${window.name}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _textPrimary,
                fontSize: 11.5.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            _windowLabel(window.start, window.end),
            style: TextStyle(
              color: _textSecondary,
              fontSize: 10.5.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      SizedBox(height: 5.h),
      ClipRRect(
        borderRadius: BorderRadius.circular(999.r),
        child: LinearProgressIndicator(
          value: progress,
          minHeight: 5.h,
          backgroundColor: _isDarkTheme
              ? const Color(0x33FF8A6B)
              : const Color(0x1FD24A28),
          valueColor: AlwaysStoppedAnimation<Color>(warn),
        ),
      ),
      SizedBox(height: 5.h),
      Row(
        children: [
          Icon(Icons.warning_amber_rounded, size: 11.sp, color: warn),
          SizedBox(width: 5.w),
          Text(
            _text('Avoid Sunnah & Nafl now', 'এখন সুন্নত-নফল নিষিদ্ধ'),
            style: TextStyle(
              color: warn,
              fontSize: 10.5.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          Text(
            '${_text('Ends in', 'বাকি')} ${_forbiddenRemainingLabel(remaining)}',
            style: TextStyle(
              color: _textSecondary,
              fontSize: 10.5.sp,
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
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),
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
        padding: EdgeInsets.fromLTRB(10.w, 8.h, 10.w, 8.h),
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
          replayTick: _arcReplayTick,
        ),
      ),
    );
  }

  List<Widget> _buildNightProgressSection() {
    final isLastThird = _isLastThirdOfNight();
    final window = _currentNightWindow();
    // Live time remaining until dawn (Fajr), ticking down each second.
    final fajrRemaining = window == null
        ? Duration.zero
        : window.end.difference(_now);
    final fajrCountdown = _liveCountdownLabel(fajrRemaining);
    final label = isLastThird
        ? _text('Last third of the night', 'রাতের শেষ তৃতীয়াংশ')
        : _text('Night in progress', 'রাত চলছে');
    return [
      Row(
        children: [
          Icon(Icons.nightlight_round, size: 13.sp, color: _accentGold),
          SizedBox(width: 6.w),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _textPrimary,
                fontSize: 11.5.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            '${_text('Tahajjud', 'তাহাজ্জুদ')} · ${_skyClock(_tahajjudTime())}',
            style: TextStyle(
              color: _textSecondary,
              fontSize: 10.5.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      SizedBox(height: 5.h),
      ClipRRect(
        borderRadius: BorderRadius.circular(999.r),
        child: LinearProgressIndicator(
          value: _nightProgress(),
          minHeight: 5.h,
          backgroundColor: _isDarkTheme
              ? const Color(0xFF1B2D3E)
              : const Color(0xFFD8E7F1),
          valueColor: AlwaysStoppedAnimation<Color>(
            isLastThird ? _accentGold : _accentSoft,
          ),
        ),
      ),
      SizedBox(height: 5.h),
      Row(
        children: [
          Icon(
            isLastThird ? Icons.auto_awesome_rounded : Icons.bedtime_outlined,
            size: 11.sp,
            color: isLastThird ? _accentGold : _accentSoft,
          ),
          SizedBox(width: 5.w),
          Text(
            isLastThird
                ? _text('Time for Tahajjud', 'তাহাজ্জুদের সময়')
                : _text('Resting hours', 'বিশ্রামের সময়'),
            style: TextStyle(
              color: isLastThird ? _accentGold : _accentSoft,
              fontSize: 10.5.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          Text(
            '${_text('Fajr in', 'ফজর বাকি')} $fajrCountdown',
            style: TextStyle(
              color: _textSecondary,
              fontSize: 10.5.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    ];
  }
}
