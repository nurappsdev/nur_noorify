import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:first_project/features/islamic_calendar/models/important_event_timeline_item.dart';
import 'package:first_project/features/islamic_calendar/utils/islamic_calendar_utils.dart';
import 'package:first_project/shared/widgets/noorify_glass.dart';

class ImportantEventsCard extends StatelessWidget {
  final List<String> events;
  final List<ImportantEventTimelineItem> timelineItems;
  final String eventSourceLabel;
  final String Function(DateTime) timelineDateLabelProvider;
  final ScrollController scrollController;

  const ImportantEventsCard({
    super.key,
    required this.events,
    required this.timelineItems,
    required this.eventSourceLabel,
    required this.timelineDateLabelProvider,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final glass = NoorifyGlassTheme(context);
    final timelineHeight = MediaQuery.of(context).size.width < 390 ? 176.0 : 148.0;

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
          Text(
            IslamicCalendarUtils.text('Important Events', 'গুরুত্বপূর্ণ তারিখসমূহ'),
            style: TextStyle(
              color: glass.textPrimary,
              fontSize: 16.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 8.h),
          Padding(
            padding: EdgeInsets.only(bottom: 6.h),
            child: Text(
              eventSourceLabel,
              style: TextStyle(
                color: glass.textSecondary,
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (events.isEmpty)
            Text(
              IslamicCalendarUtils.text('No major event today', 'আজ বড় কোনো ইভেন্ট নেই'),
              style: TextStyle(
                color: glass.textSecondary,
                fontSize: 12.5.sp,
                fontWeight: FontWeight.w600,
              ),
            )
          else
            ...events.take(4).map((event) => Padding(
              padding: EdgeInsets.only(bottom: 9.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle_rounded, size: 14.sp, color: glass.accent),
                  SizedBox(width: 7.w),
                  Expanded(
                    child: Text(
                      event,
                      style: TextStyle(
                        color: glass.textPrimary,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            )),
          SizedBox(height: 8.h),
          Text(
            IslamicCalendarUtils.text('Nearby Events', 'আগে ও পরের ইভেন্ট'),
            style: TextStyle(
              color: glass.textPrimary,
              fontSize: 12.5.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 6.h),
          if (timelineItems.isEmpty)
            Text(
              IslamicCalendarUtils.text(
                'No nearby events in this range',
                'এই সময়ে কাছাকাছি ইভেন্ট নেই',
              ),
              style: TextStyle(
                color: glass.textSecondary,
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
              ),
            )
          else
            SizedBox(
              height: timelineHeight,
              child: ListView.builder(
                controller: scrollController,
                padding: EdgeInsets.zero,
                itemCount: timelineItems.length,
                itemBuilder: (context, index) {
                  final item = timelineItems[index];
                  return Padding(
                    padding: EdgeInsets.only(bottom: 9.h),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: EdgeInsets.only(top: 2.h),
                          width: 7.r,
                          height: 7.r,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: item.isSelectedDate
                                ? glass.accent
                                : glass.textSecondary.withValues(alpha: 0.7),
                          ),
                        ),
                        SizedBox(width: 7.w),
                        Expanded(
                          child: Text(
                            '${timelineDateLabelProvider(item.date)} • ${item.event}',
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: item.isSelectedDate ? glass.textPrimary : glass.textSecondary,
                              fontSize: 12.7.sp,
                              height: 1.25,
                              fontWeight: item.isSelectedDate ? FontWeight.w700 : FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
