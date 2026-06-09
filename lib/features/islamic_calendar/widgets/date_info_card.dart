import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:first_project/features/islamic_calendar/utils/islamic_calendar_utils.dart';
import 'package:first_project/shared/widgets/noorify_glass.dart';

class DateInfoCard extends StatelessWidget {
  final DateTime selectedDate;

  const DateInfoCard({super.key, required this.selectedDate});

  @override
  Widget build(BuildContext context) {
    final glass = NoorifyGlassTheme(context);
    return NoorifyGlassCard(
      radius: BorderRadius.circular(16.r),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
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
          _DateInfoRow(
            label: IslamicCalendarUtils.text('Gregorian', 'ইংরেজি'),
            value: IslamicCalendarUtils.formatGregorian(selectedDate),
          ),
          SizedBox(height: 6.h),
          _DateInfoRow(
            label: IslamicCalendarUtils.text('Hijri', 'হিজরি'),
            value: IslamicCalendarUtils.formatHijri(selectedDate),
          ),
          SizedBox(height: 6.h),
          _DateInfoRow(
            label: IslamicCalendarUtils.text('Bangla', 'বাংলা'),
            value: IslamicCalendarUtils.formatBanglaDate(selectedDate),
          ),
        ],
      ),
    );
  }
}

class _DateInfoRow extends StatelessWidget {
  const _DateInfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final glass = NoorifyGlassTheme(context);
    return Row(
      children: [
        SizedBox(
          width: 78.w,
          child: Text(
            label,
            style: TextStyle(
              color: glass.textSecondary,
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: glass.textPrimary,
              fontSize: 13.5.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
