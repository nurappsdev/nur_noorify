part of '../screens/daily_activity_screen.dart';

mixin DailyActivityViewMixin
    on
        State<DailyActivityScreen>,
        DailyActivityControllerMixin,
        DailyActivityViewBaseMixin,
        DailySkySectionMixin,
        DailyTahajjudSectionMixin,
        DailyHeaderSectionMixin,
        DailyPrayerSectionMixin,
        DailyQiblaMealSectionMixin,
        DailyQuickActionsSectionMixin,
        DailyLastReadSectionMixin,
        DailyActivitySectionMixin,
        DailyForbiddenTimesSectionMixin {
  /// A compact card that opens the OpenStreetMap-based "Find Mosque" map where
  /// the user can browse and route to nearby mosques.
  Widget _buildFindMosqueCard() {
    return _buildGlassCard(
      padding: EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18.r),
          onTap: () => Navigator.of(context).pushNamed(RouteNames.findMosque),
          child: Padding(
            padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 12.h),
            child: Row(
              children: [
                Container(
                  width: 40.r,
                  height: 40.r,
                  decoration: BoxDecoration(
                    color: _surfaceStrong,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    Icons.mosque_rounded,
                    color: _accentSoft,
                    size: 21.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _text('Find Mosque', 'মসজিদ খুঁজুন'),
                        style: TextStyle(
                          color: _textPrimary,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        _text(
                          'Nearby mosques on the map',
                          'মানচিত্রে কাছের মসজিদ',
                        ),
                        style: TextStyle(
                          color: _textSecondary,
                          fontSize: 11.5.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 13.sp,
                  color: _textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
              top: -120.h,
              left: -80.w,
              child: Container(
                width: 220.w,
                height: 220.h,
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
              bottom: 80.h,
              right: -90.w,
              child: Container(
                width: 240.w,
                height: 240.h,
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
                        padding: EdgeInsets.fromLTRB(14.w, 10.h, 14.w, 18.h),
                        children: [


                          _buildAmolTrackCard(),
                          SizedBox(height: 12.h),
                          _buildSunArcCard(),

                          if (_isLastThirdOfNight()) ...[
                            SizedBox(height: 12.h),
                            _buildTahajjudReminderCard(),
                          ],

                          SizedBox(height: 12.h),
                          _buildPrayerStrip(),


                          SizedBox(height: 12.h),
                          _buildForbiddenTimesCard(),

                          SizedBox(height: 12.h),
                          _buildQiblaAndCountdownRow(),

                          SizedBox(height: 12.h),
                          _buildFindMosqueCard(),

                          SizedBox(height: 12.h),
                          _buildZakatCalculatorCard(),

                          SizedBox(height: 12.h),
                          _buildBoyosZacaiCard(),

                          SizedBox(height: 12.h),
                          _buildDuaJikirCard(),

                          SizedBox(height: 12.h),
                          _buildQuickActions(),

                          SizedBox(height: 12.h),


                          if (kQuranFeatureEnabled) ...[
                            SizedBox(height: 12.h),
                            _buildLastReadCard(),
                          ],

                          SizedBox(height: 12.h),
                          // _buildDailyActivityCard(),
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
