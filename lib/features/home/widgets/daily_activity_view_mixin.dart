part of '../screens/daily_activity_screen.dart';

/// Assembles the home screen from the section mixins below. Each section lives
/// in its own file under `widgets/sections/`; this mixin only owns the overall
/// scaffold, background, and the scrolling list that stitches the sections
/// together.
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
        DailyMosqueSectionMixin,
        DailyQuickActionsSectionMixin,
        DailyLastReadSectionMixin,
        DailyActivitySectionMixin,
        DailyForbiddenTimesSectionMixin {
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
                          // const SizedBox(height: 12),
                          // _buildTopHeader(),
                          const SizedBox(height: 12),
                          _buildPrayerStrip(),
                          const SizedBox(height: 12),
                          _buildForbiddenTimesCard(),
                          const SizedBox(height: 12),
                          _buildQiblaAndCountdownRow(),
                          const SizedBox(height: 12),
                          // _buildMosquePreviewCard(),
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
