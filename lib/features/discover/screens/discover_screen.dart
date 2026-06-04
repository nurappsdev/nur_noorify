import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:first_project/core/constants/route_names.dart';
import 'package:first_project/shared/providers/language_provider.dart';
import 'package:first_project/shared/services/app_globals.dart';
import 'package:first_project/shared/widgets/noorify_glass.dart';

class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({super.key});

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

  @override
  Widget build(BuildContext context) {
    final language = context.watch<LanguageProvider>().current;
    final isBangla = language == AppLanguage.bangla;
    final glass = NoorifyGlassTheme(context);

    String t(String english, String bangla) {
      if (!isBangla) return english;
      final repaired = _repairMojibake(bangla);
      if (_looksMojibake(repaired)) return english;
      return _containsBangla(repaired) ? repaired : english;
    }

        void openRoute(String route) {
          Navigator.of(context).pushNamed(route);
        }

        Future<void> openZakatCalculator() async {
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

          if (!launchedExternal && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  t(
                    'Unable to open Zakat calculator',
                    'যাকাত ক্যালকুলেটর খোলা যাচ্ছে না',
                  ),
                ),
              ),
            );
          }
        }

        return Scaffold(
          backgroundColor: glass.bgBottom,
          body: NoorifyGlassBackground(
            child: SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.fromLTRB(14.w, 10.h, 14.w, 12.h),
                      children: [
                        _DiscoverHeaderCard(
                          title: t(
                            'Discover',
                            '\u09a1\u09bf\u09b8\u0995\u09ad\u09be\u09b0',
                          ),
                          subtitle: t(
                            'Read, learn and practice daily',
                            '\u09aa\u09a1\u09bc\u09c1\u09a8, \u09b6\u09bf\u0996\u09c1\u09a8, \u09aa\u09cd\u09b0\u09a4\u09bf\u09a6\u09bf\u09a8 \u0986\u09ae\u09b2 \u0995\u09b0\u09c1\u09a8',
                          ),
                          onCalendarTap: () =>
                              openRoute(RouteNames.islamicCalendar),
                          onSettingsTap: () =>
                              openRoute(RouteNames.preferences),
                        ),
                        SizedBox(height: 12.h),
                        NoorifyGlassCard(
                          radius: BorderRadius.circular(16.r),
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 4.h,
                          ),
                          child: TextField(
                            style: TextStyle(color: glass.textPrimary),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              prefixIcon: Icon(
                                Icons.search_rounded,
                                color: glass.textMuted,
                              ),
                              hintText: t(
                                'Search resource',
                                '\u09b0\u09bf\u09b8\u09cb\u09b0\u09cd\u09b8 \u0996\u09c1\u0981\u099c\u09c1\u09a8',
                              ),
                              hintStyle: TextStyle(color: glass.textMuted),
                            ),
                          ),
                        ),
                        SizedBox(height: 12.h),
                        _SectionTitle(
                          title: t(
                            'Quick Access',
                            '\u09a6\u09cd\u09b0\u09c1\u09a4 \u09b8\u09c7\u09ac\u09be',
                          ),
                        ),
                        GridView.count(
                          crossAxisCount: 2,
                          childAspectRatio: 1.95,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            if (kQuranFeatureEnabled)
                              _ActionCard(
                                title: t(
                                  'Quran',
                                  '\u0995\u09c1\u09b0\u0986\u09a8',
                                ),
                                subtitle: t(
                                  'Read and listen',
                                  '\u09aa\u09be\u09a0 \u0993 \u09b6\u09c1\u09a8\u09c1\u09a8',
                                ),
                                icon: Icons.auto_stories_rounded,
                                accentColor: const Color(0xFF16A6C7),
                                onTap: () => openRoute(RouteNames.quran),
                              ),
                            _ActionCard(
                              title: t(
                                'Prayer Times',
                                '\u09a8\u09be\u09ae\u09be\u099c\u09c7\u09b0 \u09b8\u09ae\u09df',
                              ),
                              subtitle: t(
                                'Today schedule',
                                '\u0986\u099c\u0995\u09c7\u09b0 \u09b8\u09ae\u09df\u09b8\u09c2\u099a\u09bf',
                              ),
                              icon: Icons.access_time_filled_rounded,
                              accentColor: const Color(0xFF24A197),
                              onTap: () => openRoute(RouteNames.prayerTimes),
                            ),
                            _ActionCard(
                              title: t(
                                'Islamic Calendar',
                                '\u09b9\u09bf\u099c\u09b0\u09bf \u0995\u09cd\u09af\u09be\u09b2\u09c7\u09a8\u09cd\u09a1\u09be\u09b0',
                              ),
                              subtitle: t(
                                'Hijri dates & events',
                                '\u09b9\u09bf\u099c\u09b0\u09bf \u09a4\u09be\u09b0\u09bf\u0996 \u0993 \u0987\u09ad\u09c7\u09a8\u09cd\u099f',
                              ),
                              icon: Icons.event_note_rounded,
                              accentColor: const Color(0xFF1EA8B8),
                              onTap: () =>
                                  openRoute(RouteNames.islamicCalendar),
                            ),
                            _ActionCard(
                              title: t(
                                'Qibla',
                                '\u0995\u09bf\u09ac\u09b2\u09be',
                              ),
                              subtitle: t(
                                'Direction compass',
                                '\u09a6\u09bf\u0995\u09a8\u09bf\u09b0\u09cd\u09a6\u09c7\u09b6\u0995',
                              ),
                              icon: Icons.near_me_rounded,
                              accentColor: const Color(0xFF2C9ED8),
                              onTap: () => openRoute(RouteNames.prayerCompass),
                            ),
                            _ActionCard(
                              title: t(
                                'Asmaul Husna',
                                '\u0986\u09b8\u09ae\u09be\u0989\u09b2 \u09b9\u09c1\u09b8\u09a8\u09be',
                              ),
                              subtitle: t(
                                '99 Names of Allah',
                                '\u0986\u09b2\u09cd\u09b2\u09be\u09b9\u09b0 \u09ef\u09ef \u09a8\u09be\u09ae',
                              ),
                              icon: Icons.nightlight_round,
                              accentColor: const Color(0xFF28A8B0),
                              onTap: () => openRoute(RouteNames.asma),
                            ),
                            _ActionCard(
                              title: t(
                                'Hadith',
                                '\u09b9\u09be\u09a6\u09bf\u09b8',
                              ),
                              subtitle: t(
                                'Bukhari collection',
                                '\u09ac\u09c1\u0996\u09be\u09b0\u09bf \u09b8\u0982\u0997\u09cd\u09b0\u09b9',
                              ),
                              icon: Icons.library_books_rounded,
                              accentColor: const Color(0xFF21A8C8),
                              onTap: () => openRoute(RouteNames.hadith),
                            ),
                            _ActionCard(
                              title: t('Dua', '\u09a6\u09cb\u09af\u09bc\u09be'),
                              subtitle: t(
                                'Daily duas',
                                '\u09a6\u09c8\u09a8\u09bf\u0995 \u09a6\u09cb\u09af\u09bc\u09be',
                              ),
                              icon: Icons.pan_tool_alt_rounded,
                              accentColor: const Color(0xFF1FAEA7),
                              onTap: () => openRoute(RouteNames.dua),
                            ),
                            _ActionCard(
                              title: t(
                                'Zakat Calculator',
                                '\u09af\u09be\u0995\u09be\u09a4 \u0995\u09cd\u09af\u09be\u09b2\u0995\u09c1\u09b2\u09c7\u099f\u09b0',
                              ),
                              subtitle: t(
                                'Calculate zakat',
                                '\u09af\u09be\u0995\u09be\u09a4 \u09b9\u09bf\u09b8\u09be\u09ac',
                              ),
                              icon: Icons.savings_rounded,
                              accentColor: const Color(0xFF2A9CB4),
                              onTap: openZakatCalculator,
                            ),
                          ],
                        ),
                        SizedBox(height: 12.h),
                        _SectionTitle(
                          title: t(
                            'Daily Picks',
                            '\u0986\u099c\u0995\u09c7\u09b0 \u09a8\u09bf\u09b0\u09cd\u09ac\u09be\u099a\u09a8',
                          ),
                        ),
                        _FeatureListTile(
                          title: t(
                            'Featured Name: Ar-Rahman',
                            '\u09ab\u09bf\u099a\u09be\u09b0\u09cd\u09a1 \u09a8\u09be\u09ae: \u0986\u09b0-\u09b0\u09b9\u09ae\u09be\u09a8',
                          ),
                          subtitle: t(
                            'Tap to explore Asmaul Husna',
                            '\u0986\u09b8\u09ae\u09be\u0989\u09b2 \u09b9\u09c1\u09b8\u09a8\u09be \u09a6\u09c7\u0996\u09c1\u09a8',
                          ),
                          icon: Icons.menu_book_rounded,
                          onTap: () => openRoute(RouteNames.asma),
                        ),
                        SizedBox(height: 8.h),
                        _FeatureListTile(
                          title: t(
                            'Hadith Collection',
                            '\u09b9\u09be\u09a6\u09bf\u09b8 \u09b8\u0982\u0997\u09cd\u09b0\u09b9',
                          ),
                          subtitle: t(
                            'Read short authentic references',
                            '\u09b8\u0982\u0995\u09cd\u09b7\u09bf\u09aa\u09cd\u09a4 \u09b8\u09b9\u09bf\u09b9 \u09b0\u09c7\u09ab\u09be\u09b0\u09c7\u09a8\u09cd\u09b8 \u09aa\u09a1\u09bc\u09c1\u09a8',
                          ),
                          icon: Icons.auto_stories_rounded,
                          onTap: () => openRoute(RouteNames.hadith),
                        ),
                        SizedBox(height: 8.h),
                        _FeatureListTile(
                          title: t(
                            'Dua & Zikr',
                            '\u09a6\u09cb\u09af\u09bc\u09be \u0993 \u099c\u09bf\u0995\u09bf\u09b0',
                          ),
                          subtitle: t(
                            'Daily duas and adhkar',
                            '\u09a6\u09c8\u09a8\u09bf\u0995 \u09a6\u09cb\u09af\u09bc\u09be \u0993 \u099c\u09bf\u0995\u09bf\u09b0',
                          ),
                          icon: Icons.favorite_outline_rounded,
                          onTap: () => openRoute(RouteNames.dua),
                        ),
                        SizedBox(height: 12.h),
                        _SectionTitle(
                          title: t('Tools', '\u099f\u09c1\u09b2\u09b8'),
                        ),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _MiniToolChip(
                              title: t(
                                'Tasbih',
                                '\u09a4\u09be\u09b8\u09ac\u09bf\u09b9',
                              ),
                              icon: Icons.exposure_plus_1_rounded,
                              onTap: () => openRoute(RouteNames.tasbih),
                            ),
                            _MiniToolChip(
                              title: t(
                                'Find Mosque',
                                '\u09a8\u09bf\u0995\u099f \u09ae\u09b8\u099c\u09bf\u09a6',
                              ),
                              icon: Icons.location_city_rounded,
                              onTap: () => openRoute(RouteNames.findMosque),
                            ),
                            _MiniToolChip(
                              title: t(
                                'Islamic Tips',
                                '\u0987\u09b8\u09b2\u09be\u09ae\u09bf\u0995 \u099f\u09bf\u09aa\u09b8',
                              ),
                              icon: Icons.tips_and_updates_rounded,
                              onTap: () => openRoute(RouteNames.about),
                            ),
                            _MiniToolChip(
                              title: t(
                                'Settings',
                                '\u09b8\u09c7\u099f\u09bf\u0982\u09b8',
                              ),
                              icon: Icons.settings_rounded,
                              onTap: () => openRoute(RouteNames.preferences),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
  }
}

class _DiscoverHeaderCard extends StatelessWidget {
  const _DiscoverHeaderCard({
    required this.title,
    required this.subtitle,
    required this.onCalendarTap,
    required this.onSettingsTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onCalendarTap;
  final VoidCallback onSettingsTap;

  @override
  Widget build(BuildContext context) {
    final glass = NoorifyGlassTheme(context);
    return NoorifyGlassCard(
      radius: BorderRadius.circular(24.r),
      padding: EdgeInsets.fromLTRB(16.w, 14.h, 12.w, 12.h),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 30.sp,
                        fontWeight: FontWeight.w800,
                        color: glass.textPrimary,
                        height: 1.05,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: glass.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton.filledTonal(
                onPressed: onCalendarTap,
                style: IconButton.styleFrom(
                  backgroundColor: glass.isDark
                      ? const Color(0x332EB8E6)
                      : const Color(0x221EA8B8),
                  foregroundColor: glass.accent,
                ),
                icon: const Icon(Icons.calendar_today_rounded),
              ),
              SizedBox(width: 4.w),
              IconButton.filledTonal(
                onPressed: onSettingsTap,
                style: IconButton.styleFrom(
                  backgroundColor: glass.isDark
                      ? const Color(0x332EB8E6)
                      : const Color(0x221EA8B8),
                  foregroundColor: glass.accent,
                ),
                icon: const Icon(Icons.settings_rounded),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: 88.w,
              height: 3.h,
              decoration: BoxDecoration(
                color: glass.accent.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(999.r),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final glass = NoorifyGlassTheme(context);
    return Padding(
      padding: EdgeInsets.only(left: 4.w, bottom: 6.h),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13.sp,
          fontWeight: FontWeight.w700,
          color: glass.textSecondary,
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.accentColor,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final glass = NoorifyGlassTheme(context);
    final accent = accentColor ?? glass.accent;
    return InkWell(
      borderRadius: BorderRadius.circular(16.r),
      onTap: onTap,
      child: NoorifyGlassCard(
        radius: BorderRadius.circular(16.r),
        padding: EdgeInsets.fromLTRB(11.w, 10.h, 10.w, 10.h),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 38.r,
              height: 38.r,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    accent.withValues(alpha: glass.isDark ? 0.24 : 0.19),
                    accent.withValues(alpha: glass.isDark ? 0.13 : 0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(11.r),
                border: Border.all(
                  color: accent.withValues(alpha: glass.isDark ? 0.45 : 0.35),
                ),
              ),
              child: Icon(icon, size: 20.sp, color: accent),
            ),
            SizedBox(width: 9.w),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.fade,
                    style: TextStyle(
                      color: glass.textPrimary,
                      fontSize: 14.3.sp,
                      fontWeight: FontWeight.w700,
                      height: 1.1,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: glass.textSecondary,
                      fontSize: 11.3.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 6.w),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 12.sp,
              color: glass.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureListTile extends StatelessWidget {
  const _FeatureListTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final glass = NoorifyGlassTheme(context);
    return InkWell(
      borderRadius: BorderRadius.circular(16.r),
      onTap: onTap,
      child: NoorifyGlassCard(
        radius: BorderRadius.circular(16.r),
        padding: EdgeInsets.fromLTRB(12.w, 11.h, 12.w, 11.h),
        child: Row(
          children: [
            Icon(icon, size: 20.sp, color: glass.accent),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: glass.textPrimary,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: glass.textSecondary,
                      fontSize: 11.8.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14.sp,
              color: glass.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniToolChip extends StatelessWidget {
  const _MiniToolChip({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final glass = NoorifyGlassTheme(context);
    return InkWell(
      borderRadius: BorderRadius.circular(12.r),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: glass.isDark
              ? const Color(0x1F1A3348)
              : const Color(0xAFFFFFFF),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: glass.glassBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16.sp, color: glass.accent),
            SizedBox(width: 6.w),
            Text(
              title,
              style: TextStyle(
                color: glass.textPrimary,
                fontSize: 12.5.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
