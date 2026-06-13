part of '../../screens/daily_activity_screen.dart';

/// The side-by-side row holding the live Qibla mini-compass and the Sehri &
/// Iftar countdown card.
mixin DailyQiblaMealSectionMixin
    on
        State<DailyActivityScreen>,
        DailyActivityControllerMixin,
        DailyActivityViewBaseMixin {
  double? _miniCompassDelta() {
    final heading = _homeHeading;
    final bearing = _homeQiblaBearing;
    if (heading == null || bearing == null) return null;
    return _signedQiblaDelta(bearing, heading);
  }

  String _miniQiblaValueText() {
    const degree = '°';
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
      width: 108.r,
      height: 108.r,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 108.r,
            height: 108.r,
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
                  blurRadius: hasLiveQibla ? (_isDarkTheme ? 18.r : 14.r) : 8.r,
                  spreadRadius: hasLiveQibla ? 1.r : 0,
                ),
              ],
            ),
          ),
          AnimatedRotation(
            turns: dialTurns,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            child: SizedBox(
              width: 96.r,
              height: 96.r,
              child: CustomPaint(
                painter: MiniCompassMarksPainter(isDark: _isDarkTheme),
              ),
            ),
          ),
          AnimatedRotation(
            turns: dialTurns,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            child: SizedBox(
              width: 86.r,
              height: 86.r,
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.topCenter,
                    child: Text(
                      'N',
                      style: TextStyle(
                        color: northColor,
                        fontSize: 10.sp,
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
                        fontSize: 9.sp,
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
                        fontSize: 9.sp,
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
                        fontSize: 9.sp,
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
                width: 82.r,
                height: 82.r,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: Size(82.r, 82.r),
                      painter: MiniQiblaNeedlePainter(isDark: _isDarkTheme),
                    ),
                    Align(
                      alignment: Alignment.topCenter,
                      child: MiniKaabaMarker(isDark: _isDarkTheme),
                    ),
                  ],
                ),
              ),
            ),
          Container(
            width: 9.r,
            height: 9.r,
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
              borderRadius: BorderRadius.circular(18.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _text('Qibla', 'কিবলা'),
                    style: TextStyle(
                      color: _textPrimary,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Center(child: _buildMiniCompassDial()),
                  SizedBox(height: 8.h),
                  Text(
                    _text('Qibla Direction: ', 'কিবলার দিক: ') +
                        _miniQiblaValueText(),
                    style: TextStyle(
                      color: _textMuted,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(width: 12.w),
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
            _text('Sehri & Iftar', 'সেহরি ও ইফতার'),
            style: TextStyle(
              color: _textPrimary,
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 9.h),
          Container(
            decoration: BoxDecoration(
              color: _surfaceSubtle,
              borderRadius: BorderRadius.circular(12.r),
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
          SizedBox(height: 10.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: _isDarkTheme
                  ? const Color(0x1F1FD5C0)
                  : const Color(0x1A1EA8B8),
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(
                color: _isDarkTheme
                    ? const Color(0x339DEFE5)
                    : const Color(0x3351BFC9),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.timelapse_rounded, size: 15.sp, color: _accentSoft),
                SizedBox(width: 6.w),
                Expanded(
                  child: Text(
                    '${_localizedRemainingLabel()}: ${_formattedIftarRemaining()}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _accentStrong,
                      fontSize: 10.sp,
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
      padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 9.h),
      decoration: BoxDecoration(
        color: highlight
            ? (_isDarkTheme ? const Color(0x1F1FD5C0) : const Color(0x1A1EA8B8))
            : Colors.transparent,
        borderRadius: highlight
            ? BorderRadius.circular(10.r)
            : BorderRadius.zero,
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
            width: 28.r,
            height: 28.r,
            decoration: BoxDecoration(
              color: _isDarkTheme
                  ? const Color(0x332FD8C7)
                  : const Color(0x221EA8B8),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(icon, size: 17.sp, color: _accentSoft),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _textPrimary,
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(width: 6.w),
          Text(
            time,
            style: TextStyle(
              color: highlight ? _accentStrong : _textPrimary,
              fontSize: 14.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
