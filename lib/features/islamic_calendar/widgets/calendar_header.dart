import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:first_project/core/constants/route_names.dart';
import 'package:first_project/features/islamic_calendar/utils/islamic_calendar_utils.dart';
import 'package:first_project/shared/widgets/noorify_glass.dart';

class CalendarHeader extends StatelessWidget {
  const CalendarHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final glass = NoorifyGlassTheme(context);
    return NoorifyGlassCard(
      radius: BorderRadius.circular(24.r),
      padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 10.h),
      boxShadow: [
        BoxShadow(
          color: glass.isDark ? const Color(0x1F000000) : const Color(0x120E3853),
          blurRadius: 11,
          offset: const Offset(0, 4),
        ),
      ],
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                Navigator.of(context).pushReplacementNamed(RouteNames.discover);
              }
            },
            style: IconButton.styleFrom(
              backgroundColor: glass.isDark ? const Color(0x2B1EA8B8) : const Color(0x1A1EA8B8),
              foregroundColor: glass.accent,
            ),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              IslamicCalendarUtils.text('Hijri Calendar', 'হিজরি ক্যালেন্ডার'),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: glass.textPrimary,
                fontSize: 28.sp,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pushNamed(RouteNames.preferences),
            style: IconButton.styleFrom(
              backgroundColor: glass.isDark ? const Color(0x2B1EA8B8) : const Color(0x1A1EA8B8),
              foregroundColor: glass.accent,
            ),
            icon: const Icon(Icons.settings_rounded),
          ),
          SizedBox(width: 6.w),
          IconButton(
            onPressed: () =>
                Navigator.of(context).pushNamed(RouteNames.notifications),
            style: IconButton.styleFrom(
              backgroundColor: glass.isDark ? const Color(0x2B1EA8B8) : const Color(0x1A1EA8B8),
              foregroundColor: glass.accent,
            ),
            icon: const Icon(Icons.notifications_none_rounded),
          ),
        ],
      ),
    );
  }
}
