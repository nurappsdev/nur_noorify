import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:first_project/features/islamic_calendar/utils/islamic_calendar_utils.dart';
import 'package:first_project/shared/widgets/noorify_glass.dart';

class EventChips extends StatelessWidget {
  final List<String> events;

  const EventChips({super.key, required this.events});

  @override
  Widget build(BuildContext context) {
    final glass = NoorifyGlassTheme(context);

    if (events.isEmpty) {
      return Padding(
        padding: EdgeInsets.only(top: 10.h),
        child: Text(
          IslamicCalendarUtils.text(
            'No highlighted event on this date',
            'এই তারিখে উল্লেখযোগ্য ইভেন্ট নেই',
          ),
          style: TextStyle(
            color: glass.textSecondary,
            fontSize: 12.5.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(top: 10.h),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: events.take(3).map((event) {
          return Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: glass.isDark ? const Color(0xFF163244) : const Color(0xFFDDF4FA),
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: glass.accent.withValues(alpha: 0.55)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.event_available_rounded, size: 14.sp, color: glass.accent),
                SizedBox(width: 6.w),
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 180.w),
                  child: Text(
                    event,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: glass.textPrimary,
                      fontSize: 12.5.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(growable: false),
      ),
    );
  }
}
