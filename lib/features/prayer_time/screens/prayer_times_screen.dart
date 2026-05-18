import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:first_project/core/constants/route_names.dart';
import 'package:first_project/features/prayer_time/providers/prayer_times_provider.dart';
import 'package:first_project/shared/providers/language_provider.dart';
import 'package:first_project/shared/services/app_globals.dart';
import 'package:first_project/shared/widgets/noorify_glass.dart';

class PrayerTimesScreen extends StatelessWidget {
  const PrayerTimesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<PrayerTimesProvider>(
      create: (_) => PrayerTimesProvider(),
      child: const _PrayerTimesView(),
    );
  }
}

class _PrayerTimesView extends StatelessWidget {
  const _PrayerTimesView();

  bool _isSameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _toBanglaDigits(String input) {
    const latin = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const bangla = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
    var output = input;
    for (var i = 0; i < latin.length; i++) {
      output = output.replaceAll(latin[i], bangla[i]);
    }
    return output;
  }

  String _localizedPrayer(String key, bool isBangla) {
    if (!isBangla) return key;
    const map = {
      'Fajr': 'ফজর',
      'Sunrise': 'সূর্যোদয়',
      'Zuhr': 'যোহর',
      'Asr': 'আসর',
      'Maghrib': 'মাগরিব',
      'Isha': 'এশা',
    };
    return map[key] ?? key;
  }

  String _formatTime(DateTime? value, bool isBangla) {
    if (value == null) return '--:--';
    final hour12 = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final minute = value.minute.toString().padLeft(2, '0');
    final amPm = value.hour < 12 ? 'AM' : 'PM';
    final out = '$hour12:$minute $amPm';
    return isBangla ? _toBanglaDigits(out) : out;
  }

  String _formatRemaining(Duration remaining, bool isBangla) {
    final safe = remaining.isNegative ? Duration.zero : remaining;
    final hh = safe.inHours.toString().padLeft(2, '0');
    final mm = (safe.inMinutes % 60).toString().padLeft(2, '0');
    final ss = (safe.inSeconds % 60).toString().padLeft(2, '0');
    final out = '$hh:$mm:$ss';
    return isBangla ? _toBanglaDigits(out) : out;
  }

  List<({String key, IconData icon, DateTime? time, String subtitle})>
  _prayerCards(PrayerTimesProvider provider, String Function(String, String) t) {
    final today = provider.todaySchedule;
    return [
      (
        key: 'Fajr',
        icon: Icons.wb_twilight_rounded,
        time: today?.fajr,
        subtitle: t('Dawn prayer', 'ভোরের সালাত'),
      ),
      (
        key: 'Zuhr',
        icon: Icons.wb_sunny_rounded,
        time: today?.dzuhr,
        subtitle: t('Midday prayer', 'দুপুরের সালাত'),
      ),
      (
        key: 'Asr',
        icon: Icons.brightness_5_rounded,
        time: today?.asr,
        subtitle: t('Afternoon prayer', 'বিকালের সালাত'),
      ),
      (
        key: 'Maghrib',
        icon: Icons.bedtime_rounded,
        time: today?.maghrib,
        subtitle: t('Sunset prayer', 'সূর্যাস্তের সালাত'),
      ),
      (
        key: 'Isha',
        icon: Icons.nightlight_round,
        time: today?.isha,
        subtitle: t('Night prayer', 'রাতের সালাত'),
      ),
    ];
  }

  List<({String label, IconData icon, DateTime? time, bool emphasized})>
  _dayHighlights(PrayerTimesProvider provider, String Function(String, String) t) {
    final today = provider.todaySchedule;
    return [
      (
        label: t('Sehri Ends', 'সেহরি শেষ'),
        icon: Icons.nightlight_round,
        time: today?.fajr,
        emphasized: false,
      ),
      (
        label: t('Sunrise', 'সূর্যোদয়'),
        icon: Icons.wb_sunny_outlined,
        time: today?.sunrise,
        emphasized: false,
      ),
      (
        label: t('Iftar Starts', 'ইফতার শুরু'),
        icon: Icons.restaurant_rounded,
        time: today?.maghrib,
        emphasized: true,
      ),
      (
        label: t('Isha Starts', 'এশা শুরু'),
        icon: Icons.dark_mode_outlined,
        time: today?.isha,
        emphasized: false,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PrayerTimesProvider>();
    final language = context.watch<LanguageProvider>();
    final isBangla = language.isBangla;
    String t(String english, String bangla) => isBangla ? bangla : english;

    final glass = NoorifyGlassTheme(context);
    final ringProgress = (1.0 - provider.elapsedProgress).clamp(0.0, 1.0);
    // Silence "unused" hint while satisfying the reflective rebuild on day change.
    _isSameDate(provider.now, provider.now);

    return Scaffold(
      backgroundColor: glass.bgBottom,
      body: NoorifyGlassBackground(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  onRefresh: provider.refresh,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                    children: [
                      NoorifyGlassCard(
                        radius: BorderRadius.circular(24),
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: () {
                                if (Navigator.of(context).canPop()) {
                                  Navigator.of(context).pop();
                                  return;
                                }
                                Navigator.of(
                                  context,
                                ).pushReplacementNamed(RouteNames.discover);
                              },
                              style: IconButton.styleFrom(
                                backgroundColor: glass.isDark
                                    ? const Color(0x332EB8E6)
                                    : const Color(0x221EA8B8),
                                foregroundColor: glass.accent,
                              ),
                              icon: const Icon(Icons.arrow_back_rounded),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    t('Prayer Times', 'নামাজের সময়'),
                                    style: TextStyle(
                                      color: glass.textPrimary,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    provider.locationLabel,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: glass.textSecondary,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (provider.isSyncing) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      t(
                                        'Syncing location and online data...',
                                        'লোকেশন ও অনলাইন ডাটা সিংক হচ্ছে...',
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: glass.accentSoft,
                                        fontSize: 10.8,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  onPressed: () => Navigator.of(
                                    context,
                                  ).pushNamed(RouteNames.islamicCalendar),
                                  style: IconButton.styleFrom(
                                    backgroundColor: glass.isDark
                                        ? const Color(0x332EB8E6)
                                        : const Color(0x221EA8B8),
                                    foregroundColor: glass.accent,
                                  ),
                                  icon: const Icon(
                                    Icons.calendar_today_rounded,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                IconButton(
                                  onPressed: provider.isRefreshing
                                      ? null
                                      : provider.refresh,
                                  style: IconButton.styleFrom(
                                    backgroundColor: glass.isDark
                                        ? const Color(0x332EB8E6)
                                        : const Color(0x221EA8B8),
                                    foregroundColor: glass.accent,
                                  ),
                                  icon: provider.isRefreshing
                                      ? SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: glass.accent,
                                          ),
                                        )
                                      : const Icon(Icons.refresh_rounded),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      NoorifyGlassCard(
                        radius: BorderRadius.circular(24),
                        padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
                        child: provider.isLoading
                            ? SizedBox(
                                height: 130,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: glass.accent,
                                  ),
                                ),
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          t('Next Prayer', 'পরবর্তী সালাত'),
                                          style: TextStyle(
                                            color: glass.textSecondary,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: glass.isDark
                                              ? const Color(0x222EB8E6)
                                              : const Color(0x251EA8B8),
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                          border: Border.all(
                                            color: glass.glassBorder,
                                          ),
                                        ),
                                        child: Text(
                                          _localizedPrayer(
                                            provider.activePrayer,
                                            isBangla,
                                          ),
                                          style: TextStyle(
                                            color: glass.textPrimary,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _formatRemaining(provider.remaining, isBangla),
                                    style: TextStyle(
                                      color: glass.accentSoft,
                                      fontSize: 34,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  Text(
                                    t('remaining', 'বাকি'),
                                    style: TextStyle(
                                      color: glass.textMuted,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(99),
                                    child: LinearProgressIndicator(
                                      value: ringProgress,
                                      minHeight: 8,
                                      backgroundColor: glass.isDark
                                          ? const Color(0x2A9EE7F4)
                                          : const Color(0x331EA8B8),
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        glass.accent,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '${t('At', 'সময়')}: ${_formatTime(provider.nextPrayerAt, isBangla)}',
                                          style: TextStyle(
                                            color: glass.textPrimary,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.location_on_outlined,
                                        size: 15,
                                        color: glass.textMuted,
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          provider.locationLabel,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: glass.textSecondary,
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  if (provider.usingFallbackLocation ||
                                      provider.usingOfflineCalculation)
                                    Text(
                                      provider.usingOfflineCalculation
                                          ? t(
                                              'Using offline prayer calculation',
                                              'অফলাইন সালাত হিসাব চলছে',
                                            )
                                          : t(
                                              'Using saved location',
                                              'সংরক্ষিত লোকেশন ব্যবহার হচ্ছে',
                                            ),
                                      style: TextStyle(
                                        color: glass.textSecondary,
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                ],
                              ),
                      ),
                      const SizedBox(height: 12),
                      NoorifyGlassCard(
                        radius: BorderRadius.circular(20),
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t("Today's Schedule", 'আজকের সময়সূচি'),
                              style: TextStyle(
                                color: glass.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 10),
                            ..._prayerCards(provider, t).map((item) {
                              final isActive = item.key == provider.activePrayer;
                              return _PrayerTimeCard(
                                title: _localizedPrayer(item.key, isBangla),
                                subtitle: item.subtitle,
                                time: _formatTime(item.time, isBangla),
                                icon: item.icon,
                                isActive: isActive,
                              );
                            }),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      NoorifyGlassCard(
                        radius: BorderRadius.circular(20),
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t("Today's Highlights", 'আজকের গুরুত্বপূর্ণ সময়'),
                              style: TextStyle(
                                color: glass.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 10),
                            ..._dayHighlights(provider, t).map(
                              (item) => _PrayerHighlightTile(
                                label: item.label,
                                icon: item.icon,
                                time: _formatTime(item.time, isBangla),
                                emphasized: item.emphasized,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(44),
                                side: BorderSide(color: glass.glassBorder),
                                foregroundColor: glass.textPrimary,
                              ),
                              onPressed: () => Navigator.of(
                                context,
                              ).pushNamed(RouteNames.prayerCompass),
                              icon: const Icon(Icons.explore_rounded),
                              label: Text(
                                t('Open Qibla', 'কিবলা খুলুন'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(44),
                                side: BorderSide(color: glass.glassBorder),
                                foregroundColor: glass.textPrimary,
                              ),
                              onPressed: () => Navigator.of(
                                context,
                              ).pushNamed(RouteNames.islamicCalendar),
                              icon: const Icon(Icons.calendar_month_rounded),
                              label: Text(
                                t('Calendar', 'ক্যালেন্ডার'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FilledButton.icon(
                              style: FilledButton.styleFrom(
                                minimumSize: const Size.fromHeight(44),
                                backgroundColor: glass.accent,
                                foregroundColor: glass.isDark
                                    ? const Color(0xFF082733)
                                    : Colors.white,
                              ),
                              onPressed: provider.isRefreshing
                                  ? null
                                  : provider.refresh,
                              icon: const Icon(Icons.refresh_rounded),
                              label: Text(t('Refresh', 'রিফ্রেশ')),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrayerHighlightTile extends StatelessWidget {
  const _PrayerHighlightTile({
    required this.label,
    required this.icon,
    required this.time,
    required this.emphasized,
  });

  final String label;
  final IconData icon;
  final String time;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final glass = NoorifyGlassTheme(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: emphasized
            ? (glass.isDark ? const Color(0x2038D4C7) : const Color(0x1A1EA8B8))
            : (glass.isDark
                  ? const Color(0x161A3345)
                  : const Color(0x75FFFFFF)),
        border: Border.all(
          color: emphasized
              ? glass.accent.withValues(alpha: 0.72)
              : glass.glassBorder.withValues(alpha: 0.7),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      child: Row(
        children: [
          Icon(icon, size: 18, color: glass.accent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: glass.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            time,
            style: TextStyle(
              color: emphasized ? glass.accent : glass.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrayerTimeCard extends StatelessWidget {
  const _PrayerTimeCard({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.icon,
    required this.isActive,
  });

  final String title;
  final String subtitle;
  final String time;
  final IconData icon;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final glass = NoorifyGlassTheme(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: isActive
            ? (glass.isDark ? const Color(0x2038D4C7) : const Color(0x1A1EA8B8))
            : (glass.isDark
                  ? const Color(0x161A3345)
                  : const Color(0x75FFFFFF)),
        border: Border.all(
          color: isActive
              ? glass.accent.withValues(alpha: 0.72)
              : glass.glassBorder.withValues(alpha: 0.7),
          width: isActive ? 1.2 : 1,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: glass.accent.withValues(alpha: isActive ? 0.22 : 0.14),
            ),
            child: Icon(icon, size: 19, color: glass.accent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: glass.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: glass.textSecondary,
                    fontSize: 11.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: TextStyle(
              color: isActive ? glass.accent : glass.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (isActive) ...[
            const SizedBox(width: 8),
            Icon(Icons.check_circle_rounded, size: 16, color: glass.accent),
          ],
        ],
      ),
    );
  }
}
