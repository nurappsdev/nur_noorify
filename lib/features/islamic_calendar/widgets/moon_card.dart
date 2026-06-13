import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:first_project/features/islamic_calendar/utils/islamic_calendar_utils.dart';
import 'package:first_project/shared/widgets/noorify_glass.dart';

class MoonCard extends StatelessWidget {
  final DateTime selectedDate;

  const MoonCard({super.key, required this.selectedDate});

  double _moonProgress() {
    final day = HijriCalendar.fromDate(selectedDate).hDay;
    return (day / 30).clamp(0.05, 1.0);
  }

  String _moonPhaseLabel() {
    final day = HijriCalendar.fromDate(selectedDate).hDay;
    if (day <= 2) return IslamicCalendarUtils.text('New moon', 'নতুন চাঁদ');
    if (day <= 7) return IslamicCalendarUtils.text('Waxing crescent', 'বাড়ন্ত চাঁদ');
    if (day <= 14) return IslamicCalendarUtils.text('First half', 'অর্ধেক চাঁদ');
    if (day == 15) return IslamicCalendarUtils.text('Full moon', 'পূর্ণিমা');
    if (day <= 22) return IslamicCalendarUtils.text('Waning moon', 'ক্ষয়িষ্ণু চাঁদ');
    return IslamicCalendarUtils.text('Last crescent', 'শেষ ক্রিসেন্ট');
  }

  @override
  Widget build(BuildContext context) {
    final glass = NoorifyGlassTheme(context);
    final hijri = HijriCalendar.fromDate(selectedDate);
    final dayLabel = IslamicCalendarUtils.isBangla
        ? 'আজ ${IslamicCalendarUtils.digits(hijri.hDay.toString())}তম দিন'
        : 'Day ${IslamicCalendarUtils.digits(hijri.hDay.toString())}';

    return NoorifyGlassCard(
      radius: BorderRadius.circular(22.r),
      padding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 14.h),
      boxShadow: [
        BoxShadow(
          color: glass.isDark ? const Color(0x1F000000) : const Color(0x120E3853),
          blurRadius: 11,
          offset: const Offset(0, 4),
        ),
      ],
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  IslamicCalendarUtils.hijriMonth(hijri.longMonthName),
                  style: TextStyle(
                    color: glass.textPrimary,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  dayLabel,
                  style: TextStyle(
                    color: glass.textSecondary,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  _moonPhaseLabel(),
                  style: TextStyle(
                    color: glass.accentSoft,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 122.r,
            height: 122.r,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 118.r,
                  height: 118.r,
                  child: CircularProgressIndicator(
                    value: _moonProgress(),
                    strokeWidth: 8,
                    backgroundColor: glass.isDark ? const Color(0x2A9EE7F4) : const Color(0x2A1EA8B8),
                    valueColor: AlwaysStoppedAnimation<Color>(glass.accent),
                  ),
                ),
                Container(
                  width: 92.r,
                  height: 92.r,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: glass.isDark
                          ? const [Color(0xFF435D70), Color(0xFF1A2837)]
                          : const [Color(0xFFF4F9FC), Color(0xFFBED4E0)],
                    ),
                    border: Border.all(
                      color: glass.isDark ? const Color(0x44D4ECF8) : const Color(0x66FFFFFF),
                    ),
                  ),
                  child: Text(
                    IslamicCalendarUtils.digits(hijri.hDay.toString()),
                    style: TextStyle(
                      color: glass.textPrimary,
                      fontSize: 34.sp,
                      fontWeight: FontWeight.w800,
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
}
