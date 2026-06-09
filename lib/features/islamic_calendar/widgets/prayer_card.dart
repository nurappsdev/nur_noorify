import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:first_project/core/constants/route_names.dart';
import 'package:first_project/features/islamic_calendar/utils/islamic_calendar_utils.dart';
import 'package:first_project/shared/widgets/noorify_glass.dart';

class PrayerCard extends StatelessWidget {
  final PrayerTimes prayers;
  final DateTime selectedDate;

  const PrayerCard({
    super.key,
    required this.prayers,
    required this.selectedDate,
  });

  bool _isSameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _formatTime(DateTime dateTime) {
    final hour12 = (dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12).toString();
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final suffix = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '${IslamicCalendarUtils.digits('$hour12:$minute')} $suffix';
  }

  String _prayerLabel(String key) {
    switch (key) {
      case 'Fajr': return IslamicCalendarUtils.text('Fajr', '\u09ab\u099c\u09b0');
      case 'Sunrise': return IslamicCalendarUtils.text('Sunrise', '\u09b8\u09c2\u09b0\u09cd\u09af\u09cb\u09a6\u09af\u09bc');
      case 'Dhuhr': return IslamicCalendarUtils.text('Dhuhr', '\u09af\u09cb\u09b9\u09b0');
      case 'Asr': return IslamicCalendarUtils.text('Asr', '\u0986\u09b8\u09b0');
      case 'Maghrib': return IslamicCalendarUtils.text('Maghrib', '\u09ae\u09be\u0997\u09b0\u09bf\u09ac');
      case 'Isha': return IslamicCalendarUtils.text('Isha', '\u098f\u09b6\u09be');
      default: return key;
    }
  }

  Widget _buildPrayerTimeRow(
    NoorifyGlassTheme glass, {
    required IconData icon,
    required String key,
    required DateTime at,
    required bool highlighted,
  }) {
    final rowColor = highlighted
        ? (glass.isDark ? const Color(0x2038D4C7) : const Color(0x1A1EA8B8))
        : (glass.isDark ? const Color(0x181A3345) : const Color(0x80FFFFFF));

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 9.h),
      decoration: BoxDecoration(
        color: rowColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: highlighted ? glass.accent.withValues(alpha: 0.65) : glass.glassBorder.withValues(alpha: 0.55),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18.sp, color: glass.accent),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              _prayerLabel(key),
              style: TextStyle(
                color: glass.textPrimary,
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            _formatTime(at.toLocal()),
            style: TextStyle(
              color: glass.textPrimary,
              fontSize: 14.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final glass = NoorifyGlassTheme(context);
    final now = DateTime.now();
    final selectedIsToday = _isSameDate(selectedDate, now);
    final rows = <({String key, DateTime at, IconData icon})>[
      (key: 'Fajr', at: prayers.fajr, icon: Icons.wb_twilight_outlined),
      (key: 'Sunrise', at: prayers.sunrise, icon: Icons.wb_sunny_outlined),
      (key: 'Dhuhr', at: prayers.dhuhr, icon: Icons.light_mode_outlined),
      (key: 'Asr', at: prayers.asr, icon: Icons.sunny_snowing),
      (key: 'Maghrib', at: prayers.maghrib, icon: Icons.nights_stay_outlined),
      (key: 'Isha', at: prayers.isha, icon: Icons.dark_mode_outlined),
    ];

    String? nextKey;
    if (selectedIsToday) {
      for (final row in rows) {
        if (row.at.isAfter(now)) {
          nextKey = row.key;
          break;
        }
      }
      nextKey ??= rows.first.key;
    }

    return NoorifyGlassCard(
      radius: BorderRadius.circular(18.r),
      padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 12.h),
      boxShadow: [
        BoxShadow(
          color: glass.isDark ? const Color(0x1F000000) : const Color(0x120E3853),
          blurRadius: 11,
          offset: const Offset(0, 4),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  IslamicCalendarUtils.text('Prayer Times', 'সালাতের সময়'),
                  style: TextStyle(
                    color: glass.textPrimary,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pushNamed(RouteNames.prayerTimes),
                child: Text(
                  IslamicCalendarUtils.text('View all', 'রেফারেন্স দেখুন'),
                  style: TextStyle(
                    color: glass.accent,
                    fontSize: 12.5.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          ...rows.map((row) => _buildPrayerTimeRow(
            glass,
            icon: row.icon,
            key: row.key,
            at: row.at,
            highlighted: row.key == nextKey,
          )),
          SizedBox(height: 2.h),
          Text(
            '${IslamicCalendarUtils.text('Sehri ends', 'সেহরি শেষ')}: ${_formatTime(prayers.fajr.toLocal())}',
            style: TextStyle(
              color: glass.textSecondary,
              fontSize: 12.2.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            '${IslamicCalendarUtils.text('Iftar starts', 'ইফতার শুরু')}: ${_formatTime(prayers.maghrib.toLocal())}',
            style: TextStyle(
              color: glass.textSecondary,
              fontSize: 12.2.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
