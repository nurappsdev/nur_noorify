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
    return _isBangla ? '$value বাকি' : 'in $value';
  }

  String _prayerMeridiem(String prayer) {
    return prayer == 'Fajr' ? 'AM' : 'PM';
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
      padding: EdgeInsets.fromLTRB(10.w, 12.h, 10.w, 10.h),
      ornamentedCorners: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.brightness_5_outlined,
                size: 13.sp,
                color: _accentGold,
              ),
              SizedBox(width: 6.w),
              Text(
                _text('Prayer Times', 'নামাজের সময়'),
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 4.h),
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
                      ? '${_localizedActiveRemainingLabel()}: ${_activePrayerShortCountdown()}'
                      : '${_localizedPrayerTimeLabel()}: ${_localizedPrayerTime(_prayerTimes[_displayPrayer] ?? '--:--')}',
                  style: TextStyle(
                    color: _isDarkTheme
                        ? const Color(0xFFF5E2B8)
                        : const Color(0xFF7A5A1F),
                    fontSize: 10.8.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Text(
            _localizedCountdownLabel(),
            style: TextStyle(
              color: _textSecondary,
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 9.h),
          Row(
            children: [
              Icon(
                Icons.access_time_filled_rounded,
                size: 14.sp,
                color: _accentSoft,
              ),
              SizedBox(width: 5.w),
              Text(
                '${_localizedPrayerName(_displayPrayer)} · ',
                style: TextStyle(
                  color: _textSecondary,
                  fontSize: 11.2.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                _arabicPrayerName(_displayPrayer),
                style: TextStyle(
                  color: _accentGold,
                  fontSize: 12.5.sp,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
              SizedBox(width: 6.w),
              Text(
                _localizedPrayerTime(_prayerTimes[_displayPrayer] ?? '--:--'),
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          _ornamentDivider(
            padding: EdgeInsets.only(top: 8.h, bottom: 4.h),
          ),
          SizedBox(
            height: 104.h,
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
      borderRadius: BorderRadius.circular(12.r),
      child: AnimatedScale(
        scale: isActive ? 1.02 : 1,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 8.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r),
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
                    size: 12.5.sp,
                    color: isActive
                        ? const Color(0xDD032F35)
                        : (_isDarkTheme
                              ? const Color(0xFF9BC1D8)
                              : const Color(0xFF56758A)),
                  ),
                  SizedBox(width: 4.w),
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
                  Text(
                    _arabicPrayerName(prayer),
                    style: TextStyle(
                      color: isActive ? const Color(0xCC032F35) : _accentGold,
                      fontSize: 11.5.sp,
                      fontWeight: FontWeight.w700,
                      height: 1,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 5.h),
              Text(
                time,
                style: TextStyle(
                  color: isActive
                      ? const Color(0xFF032F35)
                      : (_isDarkTheme ? Colors.white : const Color(0xFF214259)),
                  fontSize: 15.5.sp,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
              SizedBox(height: 3.h),
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
                  if (isActive)
                    Transform.rotate(
                      angle: 0.785398,
                      child: Container(
                        width: 6.w,
                        height: 6.h,
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
}
