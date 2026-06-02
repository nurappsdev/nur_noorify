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
}
