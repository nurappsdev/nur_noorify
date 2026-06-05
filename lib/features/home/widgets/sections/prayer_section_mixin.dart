part of '../../screens/daily_activity_screen.dart';

/// The prayer-times strip: header chip with the live countdown, the swipeable
/// prayer carousel, and the "back to current" control.
mixin DailyPrayerSectionMixin
    on
        State<DailyActivityScreen>,
        DailyActivityControllerMixin,
        DailyActivityViewBaseMixin {
  String _activePrayerShortCountdown() {
    final value = _formattedActiveRemaining();
    return _isBangla ? '$value বাকি' : 'ends in $value';
  }

  String _prayerMeridiem(String prayer) {
    return prayer == 'Fajr' ? 'AM' : 'PM';
  }

  DateTime? _prayerDateTime(String prayer) {
    final schedule = _todaySchedule;
    if (schedule == null) return null;
    switch (prayer) {
      case 'Fajr':
        return schedule.fajr;
      case 'Zuhr':
        return schedule.dzuhr;
      case 'Asr':
        return schedule.ashr;
      case 'Maghrib':
        return schedule.maghrib;
      case 'Isha':
        return schedule.isha;
      default:
        return null;
    }
  }

  /// When a prayer's window closes — i.e. when the next prayer begins. This
  /// mirrors the `windowEnd` logic in [_buildActivePrayerData], so the ranges
  /// shown on the cards match the countdown/progress behaviour. Isha runs until
  /// tomorrow's Fajr.
  DateTime? _prayerEndDateTime(String prayer) {
    final schedule = _todaySchedule;
    if (schedule == null) return null;
    switch (prayer) {
      case 'Fajr':
        return schedule.dzuhr;
      case 'Zuhr':
        return schedule.ashr;
      case 'Asr':
        return schedule.maghrib;
      case 'Maghrib':
        return schedule.isha;
      case 'Isha':
        return _tomorrowSchedule?.fajr ??
            schedule.fajr.add(const Duration(days: 1));
      default:
        return null;
    }
  }

  /// Localized "start – end" range for a prayer, e.g. `11:57 – 04:38`.
  String _prayerTimeRangeLabel(String prayer) {
    final start = _localizedPrayerTime(_prayerTimes[prayer] ?? '--:--');
    final end = _prayerEndDateTime(prayer);
    final endLabel = _localizedPrayerTime(
      end == null ? '--:--' : _formatPrayerTime(end),
    );
    return '$start – $endLabel';
  }

  String _compactDuration(Duration duration) {
    final safe = duration.isNegative ? Duration.zero : duration;
    final hours = safe.inHours;
    final minutes = safe.inMinutes % 60;
    final value = hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m';
    return _isBangla ? _toBanglaDigits(value) : value;
  }

  String _prayerStatusLabel(String prayer) {
    if (prayer == _activePrayer) {
      return _text('Now', 'এখন');
    }
    final time = _prayerDateTime(prayer);
    if (time == null) return _text('Scheduled', 'নির্ধারিত');
    final diff = time.difference(_now);
    if (diff.inMinutes > 0) {
      return _isBangla
          ? '${_compactDuration(diff)} পরে'
          : 'in ${_compactDuration(diff)}';
    }
    return _text('Passed', 'শেষ হয়েছে');
  }

  String _displayPrayerSummary() {
    final time = _prayerDateTime(_displayPrayer);
    if (time == null) {
      return _text('Calculated prayer schedule', 'নির্ধারিত নামাজের সময়সূচি');
    }
    final diff = time.difference(_now);
    if (_displayPrayer == _activePrayer) {
      return _localizedCountdownLabel();
    }
    if (diff.isNegative) {
      return _isBangla
          ? '${_localizedPrayerName(_displayPrayer)} আজ সম্পন্ন হয়েছে'
          : '${_localizedPrayerName(_displayPrayer)} has passed today';
    }
    return _isBangla
        ? '${_localizedPrayerName(_displayPrayer)} শুরু হতে ${_compactDuration(diff)}'
        : '${_localizedPrayerName(_displayPrayer)} starts in ${_compactDuration(diff)}';
  }

  String _locationContextLabel() {
    final label = _locationLabel.trim();
    final location = label.isEmpty ? 'Baitul Mukarram, Dhaka' : label;
    return _isBangla
        ? '${_toBanglaDigits(_formattedBritishDate)} · $location'
        : 'Today · $location';
  }

  Widget _buildCalendarWaqtButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12.r),
        onTap: () => Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (_) => CalendarWaqtScreen(
              latitude: _latitude,
              longitude: _longitude,
              locationLabel: _locationLabel,
            ),
          ),
        ),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 11.h),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _isDarkTheme
                  ? const [Color(0xFF13404B), Color(0xFF0F2F3A)]
                  : const [Color(0xFFE3F4F7), Color(0xFFD3ECF1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: _isDarkTheme
                  ? const Color(0x3359C8E4)
                  : const Color(0x66A7D7E2),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.calendar_month_rounded,
                size: 17.sp,
                color: _accentStrong,
              ),
              SizedBox(width: 8.w),
              Text(
                _text('Calendar & Waqt', 'ক্যালেন্ডার ও ওয়াক্ত'),
                style: TextStyle(
                  color: _accentStrong,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrayerStrip() {
    return _buildGlassCard(
      padding: EdgeInsets.fromLTRB(12.w, 13.h, 12.w, 11.h),
      ornamentedCorners: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34.w,
                height: 34.h,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: _isDarkTheme
                        ? const [Color(0xFF1E5362), Color(0xFF12313D)]
                        : const [Color(0xFFE4F8FB), Color(0xFFCFEFF4)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: _surfaceBorder),
                ),
                child: Icon(
                  Icons.mosque_rounded,
                  size: 17.sp,
                  color: _accentStrong,
                ),
              ),
              SizedBox(width: 9.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _text('Prayer Times', 'নামাজের সময়'),
                      style: TextStyle(
                        color: _textPrimary,
                        fontSize: 14.5.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      _locationContextLabel(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _textSecondary,
                        fontSize: 10.2.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              Tooltip(
                message: _isShowingActivePrayer
                    ? '${_localizedActiveRemainingLabel()}: ${_activePrayerShortCountdown()}'
                    : '${_localizedPrayerTimeLabel()}: ${_localizedPrayerTime(_prayerTimes[_displayPrayer] ?? '--:--')}',
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _isDarkTheme
                          ? const [Color(0x55E6C77A), Color(0x3320D3BF)]
                          : const [Color(0x33B78A2E), Color(0x1F1EA8B8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(999.r),
                    border: Border.all(color: _accentGoldSoft),
                  ),
                  child: Text(
                    _isShowingActivePrayer
                        ? _activePrayerShortCountdown()
                        : _prayerStatusLabel(_displayPrayer),
                    style: TextStyle(
                      color: _isDarkTheme
                          ? const Color(0xFFF5E2B8)
                          : const Color(0xFF7A5A1F),
                      fontSize: 10.5.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          // Container(
          //   padding: EdgeInsets.all(10.r),
          //   decoration: BoxDecoration(
          //     color: _isDarkTheme
          //         ? const Color(0x66101F2C)
          //         : const Color(0xCCF6FBFE),
          //     borderRadius: BorderRadius.circular(14.r),
          //     border: Border.all(color: _surfaceBorder),
          //   ),
          //   child: Column(
          //     children: [
          //       Row(
          //         children: [
          //           Icon(
          //             _prayerIcon(_displayPrayer),
          //             size: 17.sp,
          //             color: _accentStrong,
          //           ),
          //           SizedBox(width: 7.w),
          //           Expanded(
          //             child: Text(
          //               _displayPrayerSummary(),
          //               maxLines: 1,
          //               overflow: TextOverflow.ellipsis,
          //               style: TextStyle(
          //                 color: _textPrimary,
          //                 fontSize: 12.sp,
          //                 fontWeight: FontWeight.w800,
          //               ),
          //             ),
          //           ),
          //           Text(
          //             _localizedPrayerTime(
          //               _prayerTimes[_displayPrayer] ?? '--:--',
          //             ),
          //             style: TextStyle(
          //               color: _accentGold,
          //               fontSize: 13.sp,
          //               fontWeight: FontWeight.w900,
          //             ),
          //           ),
          //         ],
          //       ),
          //       SizedBox(height: 9.h),
          //       ClipRRect(
          //         borderRadius: BorderRadius.circular(999.r),
          //         child: LinearProgressIndicator(
          //           minHeight: 5.h,
          //           value: _isShowingActivePrayer ? _activeProgress : null,
          //           backgroundColor: _isDarkTheme
          //               ? const Color(0xFF223545)
          //               : const Color(0xFFE0EDF5),
          //           valueColor: AlwaysStoppedAnimation<Color>(_accentStrong),
          //         ),
          //       ),
          //     ],
          //   ),
          // ),
          _ornamentDivider(
            padding: EdgeInsets.only(top: 8.h, bottom: 4.h),
          ),
          SizedBox(
            height: 116.h,
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
                  padding: EdgeInsets.symmetric(horizontal: 3.w),
                  child: _buildPrayerTimeChip(prayer, pageIndex: index),
                );
              },
            ),
          ),
          if (!_isShowingActivePrayer) ...[
            SizedBox(height: 8.h),
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
                icon: Icon(Icons.my_location_rounded, size: 15.sp),
                label: Text(_text('Back to current', 'বর্তমানে ফিরুন')),
              ),
            ),
          ],
          SizedBox(height: 10.h),
          _buildCalendarWaqtButton(),
        ],
      ),
    );
  }

  Widget _buildPrayerTimeChip(String prayer, {required int pageIndex}) {
    final isActive = prayer == _displayPrayer;
    final isCurrent = prayer == _activePrayer;
    final timeRange = _prayerTimeRangeLabel(prayer);
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
      borderRadius: BorderRadius.circular(14.r),
      child: AnimatedScale(
        scale: isActive ? 1.02 : 1,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 9.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14.r),
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
                  Container(
                    width: 24.w,
                    height: 24.h,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isActive
                          ? const Color(0x22032F35)
                          : (_isDarkTheme
                                ? const Color(0x332D5167)
                                : const Color(0xFFEFF7FB)),
                    ),
                    child: Icon(
                      icon,
                      size: 13.sp,
                      color: isActive
                          ? const Color(0xDD032F35)
                          : (_isDarkTheme
                                ? const Color(0xFF9BC1D8)
                                : const Color(0xFF56758A)),
                    ),
                  ),
                  SizedBox(width: 6.w),
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
                        fontSize: 10.8.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 7.h),
              Text(
                _arabicPrayerName(prayer),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isActive ? const Color(0xCC032F35) : _accentGold,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                  height: 1.05,
                ),
              ),
              SizedBox(height: 6.h),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  timeRange,
                  maxLines: 1,
                  style: TextStyle(
                    color: isActive
                        ? const Color(0xFF032F35)
                        : (_isDarkTheme
                              ? Colors.white
                              : const Color(0xFF214259)),
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
              ),
              const Spacer(),
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
                      fontSize: 9.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    constraints: BoxConstraints(maxWidth: 58.w),
                    padding: EdgeInsets.symmetric(
                      horizontal: 6.w,
                      vertical: 2.5.h,
                    ),
                    decoration: BoxDecoration(
                      color: isActive
                          ? const Color(0x22032F35)
                          : (isCurrent
                                ? _accentStrong.withValues(alpha: 0.14)
                                : Colors.transparent),
                      borderRadius: BorderRadius.circular(999.r),
                      border: Border.all(
                        color: isActive
                            ? const Color(0x33032F35)
                            : (isCurrent
                                  ? _accentStrong.withValues(alpha: 0.42)
                                  : _surfaceBorder.withValues(alpha: 0.55)),
                      ),
                    ),
                    child: Text(
                      _prayerStatusLabel(prayer),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isActive
                            ? const Color(0xDD032F35)
                            : (isCurrent ? _accentStrong : _textWeak),
                        fontSize: 8.4.sp,
                        fontWeight: FontWeight.w800,
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
}
