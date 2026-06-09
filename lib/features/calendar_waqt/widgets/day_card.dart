import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:ponjika/ponjika.dart';
import 'package:first_project/features/calendar_waqt/utils/calendar_waqt_utils.dart';

class DayCard extends StatelessWidget {
  const DayCard({
    super.key,
    required this.date,
    required this.isToday,
    required this.lat,
    required this.lng,
    required this.isBangla,
    required this.colors,
  });

  final DateTime date;
  final bool isToday;
  final double lat;
  final double lng;
  final bool isBangla;
  final Map<String, Color> colors;

  String _t(String en, String bn) => isBangla ? bn : en;

  @override
  Widget build(BuildContext context) {
    final pr = CalendarWaqtUtils.prayerTimes(date, lat, lng);
    final f = pr.fajr.toLocal(),
        s = pr.sunrise.toLocal(),
        d = pr.dhuhr.toLocal(),
        a = pr.asr.toLocal(),
        m = pr.maghrib.toLocal(),
        i = pr.isha.toLocal();

    return Container(
      decoration: BoxDecoration(
        color: colors['cardBg'],
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: colors['cardBorder']!),
        boxShadow: [
          BoxShadow(
            color: colors['isDark']! == Colors.black
                ? const Color(0x40000000)
                : const Color(0x1A0E3853),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          Padding(
            padding: EdgeInsets.all(12.r),
            child: Column(
              children: [
                _buildGrid(f, d, a, m, i),
                SizedBox(height: 10.h),
                Row(
                  children: [
                    Expanded(
                      child: _buildPair(
                        _t('Sunrise', 'সূর্যোদয়'),
                        CalendarWaqtUtils.clock(s, isBangla),
                        _t('Sunset', 'সূর্যাস্ত'),
                        CalendarWaqtUtils.clock(m, isBangla),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: _buildPair(
                        _t('Sahri', 'সাহরি'),
                        CalendarWaqtUtils.clock(f, isBangla),
                        _t('Iftar', 'ইফতার'),
                        CalendarWaqtUtils.clock(m, isBangla),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                _buildForbidden(s, d, m),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final h = HijriCalendar.fromDate(date);
    final hl =
        '${CalendarWaqtUtils.digits(h.hDay.toString(), isBangla)} ${CalendarWaqtUtils.hijriMonthName(h.hMonth, isBangla)} ${CalendarWaqtUtils.digits(h.hYear.toString(), isBangla)} ${_t('AH', 'হিজরি')}';
    final bl = Ponjika.format(date: date, format: 'DD MM YY');
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors['greenStart']!, colors['greenEnd']!],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${CalendarWaqtUtils.digits('${date.day}', isBangla)} ${CalendarWaqtUtils.monthName(date.month, isBangla)}, ${CalendarWaqtUtils.digits(date.year.toString(), isBangla)} • ${CalendarWaqtUtils.weekdayName(date.weekday, isBangla)}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (isToday)
                Container(
                  margin: EdgeInsets.only(left: 8.w),
                  padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(999.r),
                  ),
                  child: Text(
                    _t('Today', 'আজ'),
                    style: TextStyle(
                      color: colors['greenEnd'],
                      fontSize: 10.5.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 4.h),
          Text(
            '$hl • $bl',
            style:  TextStyle(
              color: Color(0xFFE6F6EF),
              fontSize: 11.5.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(
    DateTime f,
    DateTime d,
    DateTime a,
    DateTime m,
    DateTime i,
  ) {
    final c = [
      (lbl: _t('Fajr', 'ফজর'), at: f),
      (lbl: _t('Dhuhr', 'যুহর'), at: d),
      (lbl: _t('Asr', 'আসর'), at: a),
      (lbl: _t('Maghrib', 'মাগরিব'), at: m),
      (lbl: _t('Isha', 'ইশা'), at: i),
    ];
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 6.w),
      decoration: BoxDecoration(
        color: colors['cellBg'],
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          for (final x in c)
            Expanded(
              child: Column(
                children: [
                  Text(
                    x.lbl,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors['textSecondary'],
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    CalendarWaqtUtils.clock(x.at, isBangla),
                    style: TextStyle(
                      color: colors['textPrimary'],
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPair(String l1, String v1, String l2, String v2) {
    it(String l, String v) => Expanded(
      child: Column(
        children: [
          Text(
            l,
            maxLines: 1,
            style: TextStyle(
              color: colors['textSecondary'],
              fontSize: 10.5.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 3.h),
          Text(
            v,
            style: TextStyle(
              color: colors['textPrimary'],
              fontSize: 12.5.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
    return Container(
      padding: EdgeInsets.symmetric(vertical: 9.h, horizontal: 6.w),
      decoration: BoxDecoration(
        color: colors['cellBg'],
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(children: [it(l1, v1), it(l2, v2)]),
    );
  }

  Widget _buildForbidden(DateTime s, DateTime d, DateTime m) {
    final p = [
      (l: _t('Morning', 'সকাল'), s: s, e: s.add(const Duration(minutes: 15))),
      (l: _t('Noon', 'দুপুর'), s: d.subtract(const Duration(minutes: 2)), e: d),
      (
        l: _t('Evening', 'সন্ধ্যা'),
        s: m.subtract(const Duration(minutes: 14)),
        e: m,
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _t('Forbidden Times', 'নিষিদ্ধ সময়'),
          style: TextStyle(
            color: colors['textPrimary'],
            fontSize: 12.5.sp,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 8.h),
        Row(
          children: [
            for (var i = 0; i < p.length; i++) ...[
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 9.h, horizontal: 4.w),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colors['forbiddenStart']!,
                        colors['forbiddenEnd']!,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Column(
                    children: [
                      Text(
                        p[i].l,
                        maxLines: 1,
                        style:  TextStyle(
                          color: Color(0xFFF3D9D2),
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        '${CalendarWaqtUtils.clock(p[i].s, isBangla)} - ${CalendarWaqtUtils.clock(p[i].e, isBangla)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:  TextStyle(
                          color: Colors.white,
                          fontSize: 10.5.sp,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (i != p.length - 1) SizedBox(width: 8.w),
            ],
          ],
        ),
      ],
    );
  }
}
