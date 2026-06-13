part of '../../screens/daily_activity_screen.dart';

/// The Quick Menu card: primary action tiles plus the scrollable menu-link chips.
mixin DailyQuickActionsSectionMixin
    on
        State<DailyActivityScreen>,
        DailyActivityControllerMixin,
        DailyActivityViewBaseMixin {
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
          // (
          //   titleEn: 'Find Mosque',
          //   titleBn: '\u09ae\u09b8\u099c\u09bf\u09a6',
          //   icon: Icons.location_city_rounded,
          //   onTap: () => Navigator.of(context).pushNamed(RouteNames.findMosque),
          // ),

          // (
          //   titleEn: 'Prayer',
          //   titleBn: '\u09a8\u09be\u09ae\u09be\u099c',
          //   icon: Icons.schedule_rounded,
          //   onTap: () => Navigator.of(context).push<void>(
          //     MaterialPageRoute<void>(
          //       builder: (_) => const PrayerTimesScreen(),
          //     ),
          //   ),
          // ),
          (
            titleEn: 'Tasbih',
            titleBn: '\u09a4\u09be\u09b8\u09ac\u09bf\u09b9',
            icon: Icons.exposure_plus_1_rounded,
            onTap: () => Navigator.of(context).pushNamed(RouteNames.tasbih),
          ),
          // (
          //   titleEn: 'Zakat',
          //   titleBn: '\u09af\u09be\u0995\u09be\u09a4',
          //   icon: Icons.savings_rounded,
          //   onTap: () => unawaited(_openZakatCalculator()),
          // ),
          (
            titleEn: 'Settings',
            titleBn: '\u09b8\u09c7\u099f\u09bf\u0982\u09b8',
            icon: Icons.settings_rounded,
            onTap: () => Navigator.of(context).push<void>(
              MaterialPageRoute<void>(
                builder: (_) => const ProfilePreferencesScreen(),
              ),
            ),
          ),
        ];

    return _buildGlassCard(
      padding: EdgeInsets.fromLTRB(11.w, 10.h, 11.w, 11.h),
      ornamentedCorners: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row(
          //   children: [
          //     Icon(
          //       Icons.auto_awesome_outlined,
          //       size: 13.sp,
          //       color: _accentGold,
          //     ),
          //     SizedBox(width: 6.w),
          //     Text(
          //       _text(
          //         'Quick Menu',
          //         '\u09a6\u09cd\u09b0\u09c1\u09a4 \u09ae\u09c7\u09a8\u09c1',
          //       ),
          //       style: TextStyle(
          //         color: _textPrimary,
          //         fontSize: 14.sp,
          //         fontWeight: FontWeight.w700,
          //         letterSpacing: 0.3,
          //       ),
          //     ),
          //     const Spacer(),
          //     TextButton.icon(
          //       style: TextButton.styleFrom(
          //         visualDensity: VisualDensity.compact,
          //         foregroundColor: _accentStrong,
          //       ),
          //       onPressed: () => Navigator.of(context).push<void>(
          //         MaterialPageRoute<void>(
          //           builder: (_) => const DiscoverScreen(),
          //         ),
          //       ),
          //       icon: Icon(Icons.grid_view_rounded, size: 15.sp),
          //       label: Text(
          //         _text(
          //           'Open Discover',
          //           '\u09a1\u09bf\u09b8\u0995\u09ad\u09be\u09b0',
          //         ),
          //       ),
          //     ),
          //   ],
          // ),
          _ornamentDivider(
            padding: EdgeInsets.only(top: 4.h, bottom: 8.h),
          ),
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
                if (i != actions.length - 1) SizedBox(width: 7.w),
              ],
            ],
          ),
          SizedBox(height: 8.h),
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
                  if (i != menuLinks.length - 1) SizedBox(width: 7.w),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Maps each time-bound deed id to the moment it becomes trackable today,
  /// taken from today's prayer schedule. The Amol tracker uses this to block
  /// marking a deed (e.g. Maghrib or Isha) before its time has arrived.
  Map<String, DateTime> _amolAvailableFromTimes() {
    final schedule = _todaySchedule;
    if (schedule == null) return const {};
    final times = <String, DateTime>{
      'fajr': schedule.fajr,
      'zuhr': schedule.dzuhr,
      'asr': schedule.ashr,
      'maghrib': schedule.maghrib,
      'isha': schedule.isha,
      'tahajjud': schedule.isha,
      'witr': schedule.isha,
      'morning_adhkar': schedule.fajr,
      'evening_adhkar': schedule.ashr,
    };
    final sunrise = schedule.sunrise;
    if (sunrise != null) {
      times['ishraq'] = sunrise;
      times['chasht'] = sunrise;
    }
    return times;
  }

  Future<void> _openAmolTrackScreen() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => AmolTrackScreen(
          availableFrom: _amolAvailableFromTimes(),
        ),
      ),
    );
    // Pick up any deeds the user toggled while on the tracker.
    await _loadAmolProgress();
  }

  /// A compact card that opens the "Today Amol Track" daily deeds tracker and
  /// shows today's completion percentage.
  Widget _buildAmolTrackCard() {
    final total = kAmolMaxScore;
    final done = _amolScoreToday.clamp(0, total);
    final progress = total == 0 ? 0.0 : done / total;
    final percent = (progress * 100).round();

    return _buildGlassCard(
      padding: EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18.r),
          onTap: () => unawaited(_openAmolTrackScreen()),
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
                    Icons.checklist_rtl_rounded,
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
                        _text('Today Amol Track', 'আজকের আমল ট্র্যাক'),
                        style: TextStyle(
                          color: _textPrimary,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(999.r),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 6.h,
                                backgroundColor: _isDarkTheme
                                    ? const Color(0xFF1B2D3E)
                                    : const Color(0xFFD8E7F1),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  _accentStrong,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            '${_localizedCountLabel(done)}/${_localizedCountLabel(total)}',
                            style: TextStyle(
                              color: _textSecondary,
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 12.w),
                Text(
                  _isBangla
                      ? '${_toBanglaDigits(percent.toString())}%'
                      : '$percent%',
                  style: TextStyle(
                    color: _accentStrong,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(width: 8.w),
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

  String _localizedCountLabel(int value) =>
      _isBangla ? _toBanglaDigits(value.toString()) : value.toString();

  /// A compact card that opens the in-app "Zakat Calculator" screen where the
  /// user enters their gold, silver, cash, deposits and loans to work out the
  /// zakat payable.
  Widget _buildZakatCalculatorCard() {
    return _buildGlassCard(
      padding: EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18.r),
          onTap: () =>
              Navigator.of(context).pushNamed(RouteNames.zakatCalculator),
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
                    Icons.savings_rounded,
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
                        _text('Zakat Calculator', 'যাকাত ক্যালকুলেটর'),
                        style: TextStyle(
                          color: _textPrimary,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        _text(
                          'Gold, silver, cash, deposits & loans',
                          'স্বর্ণ, রুপা, নগদ, আমানত ও ঋণ',
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

  /// A compact card that opens the "Boyos Zacai" age calculator screen.
  Widget _buildBoyosZacaiCard() {
    return _buildGlassCard(
      padding: EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18.r),
          onTap: () => Navigator.of(context).push<void>(
            MaterialPageRoute<void>(
              builder: (_) => const BoyosZacaiScreen(),
            ),
          ),
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
                    Icons.cake_rounded,
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
                        _text('Boyos Zacai', 'বয়স যাচাই'),
                        style: TextStyle(
                          color: _textPrimary,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        _text(
                          'Calculate age in years, months & more',
                          'বছর, মাস ও আরও বয়স গণনা',
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

  /// A compact card that opens the "Dua o Jikir" hub of dhikr and dua
  /// categories.
  Widget _buildDuaJikirCard() {
    return _buildGlassCard(
      padding: EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18.r),
          onTap: () => Navigator.of(context).push<void>(
            MaterialPageRoute<void>(
              builder: (_) => const DuaJikirScreen(),
            ),
          ),
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
                    Icons.self_improvement_rounded,
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
                        _text('Dua o Jikir', 'দোয়া ও জিকির'),
                        style: TextStyle(
                          color: _textPrimary,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        _text(
                          'Jikir, daily duas & more',
                          'জিকির, দৈনন্দিন দোয়া ও আরও',
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

  Widget _buildQuickActionCard({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Ink(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 9.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
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
                width: 34.r,
                height: 34.r,
                decoration: BoxDecoration(
                  color: _surfaceStrong,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(icon, color: _accentSoft, size: 19.sp),
              ),
              SizedBox(height: 6.h),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 11.sp,
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
        borderRadius: BorderRadius.circular(999.r),
        child: Ink(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999.r),
            color: _isDarkTheme
                ? const Color(0xFF162433)
                : const Color(0xF8FFFFFF),
            border: Border.all(color: _surfaceBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16.sp, color: _accentSoft),
              SizedBox(width: 6.w),
              Text(
                title,
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 11.2.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(width: 4.w),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 10.sp,
                color: _textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
