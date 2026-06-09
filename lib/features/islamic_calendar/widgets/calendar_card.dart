import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:first_project/features/islamic_calendar/utils/islamic_calendar_utils.dart';
import 'package:first_project/shared/widgets/noorify_glass.dart';

class CalendarCard extends StatelessWidget {
  final DateTime displayedMonth;
  final DateTime selectedDate;
  final List<DateTime> visibleDays;
  final Function(int) onMonthChange;
  final Function(DateTime) onSelectDate;
  final List<String> Function(DateTime) eventsForDateProvider;

  const CalendarCard({
    super.key,
    required this.displayedMonth,
    required this.selectedDate,
    required this.visibleDays,
    required this.onMonthChange,
    required this.onSelectDate,
    required this.eventsForDateProvider,
  });

  bool _isSameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _isInDisplayedMonth(DateTime date) =>
      date.year == displayedMonth.year && date.month == displayedMonth.month;

  String _monthHeaderTitle() {
    final h = HijriCalendar.fromDate(displayedMonth);
    final raw = '${IslamicCalendarUtils.hijriMonth(h.longMonthName)} ${h.hYear}';
    return IslamicCalendarUtils.isBangla ? '${IslamicCalendarUtils.digits(raw)} হিজরি' : '${IslamicCalendarUtils.digits(raw)} AH';
  }

  String _monthHeaderSubtitle() =>
      '${IslamicCalendarUtils.gregorianMonth(displayedMonth.month)} ${IslamicCalendarUtils.digits(displayedMonth.year.toString())}';

  @override
  Widget build(BuildContext context) {
    final glass = NoorifyGlassTheme(context);
    final today = DateTime.now();

    return NoorifyGlassCard(
      radius: BorderRadius.circular(22.r),
      padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 12.h),
      boxShadow: [
        BoxShadow(
          color: glass.isDark ? const Color(0x1F000000) : const Color(0x120E3853),
          blurRadius: 11,
          offset: const Offset(0, 4),
        ),
      ],
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => onMonthChange(-1),
                icon: Icon(Icons.chevron_left_rounded, color: glass.textPrimary),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      _monthHeaderTitle(),
                      style: TextStyle(
                        color: glass.textPrimary,
                        fontSize: 24.sp,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      _monthHeaderSubtitle(),
                      style: TextStyle(
                        color: glass.textSecondary,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => onMonthChange(1),
                icon: Icon(Icons.chevron_right_rounded, color: glass.textPrimary),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            children: List<Widget>.generate(
              7,
              (i) => Expanded(
                child: Center(
                  child: Text(
                    IslamicCalendarUtils.weekday(i),
                    style: TextStyle(
                      color: glass.textSecondary,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 8.h),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: visibleDays.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              childAspectRatio: 1.02,
            ),
            itemBuilder: (context, index) {
              final date = visibleDays[index];
              final selected = _isSameDate(date, selectedDate);
              final isToday = _isSameDate(date, today);
              final inMonth = _isInDisplayedMonth(date);
              final hasEvent = eventsForDateProvider(date).isNotEmpty;

              return InkWell(
                borderRadius: BorderRadius.circular(12.r),
                onTap: () => onSelectDate(date),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12.r),
                    color: selected
                        ? (glass.isDark ? const Color(0xFF1F5F6F) : const Color(0xFF85DFE6))
                        : (glass.isDark ? const Color(0x241B3B4E) : const Color(0x66FFFFFF)),
                    border: Border.all(
                      color: isToday
                          ? glass.accent.withValues(alpha: 0.95)
                          : glass.glassBorder.withValues(alpha: 0.7),
                      width: isToday ? 1.5 : 1,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Text(
                          IslamicCalendarUtils.digits(date.day.toString()),
                          style: TextStyle(
                            color: selected
                                ? (glass.isDark ? const Color(0xFFE9FBFF) : const Color(0xFF0B4A52))
                                : (inMonth ? glass.textPrimary : glass.textMuted.withValues(alpha: 0.58)),
                            fontSize: 20.sp,
                            fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
                          ),
                        ),
                      ),
                      if (hasEvent)
                        Positioned(
                          top: 4.h,
                          right: 4.w,
                          child: Icon(
                            Icons.circle,
                            size: 6.sp,
                            color: selected ? const Color(0xFF0B4A52) : glass.accent,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
