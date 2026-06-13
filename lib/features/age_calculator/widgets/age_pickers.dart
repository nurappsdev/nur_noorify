import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:first_project/features/age_calculator/utils/age_utils.dart';

class AgePickers {
  static Future<DateTime?> pickHijri(BuildContext context, {required bool isBirth, required DateTime initial, required Map<String, Color> colors, required bool isBangla}) {
    final cal = HijriCalendar();
    final start = HijriCalendar.fromDate(initial);
    var y = start.hYear.clamp(1318, 1525), m = start.hMonth, d = start.hDay;
    final t = (String en, String bn) => isBangla ? bn : en;

    return showDialog<DateTime>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          final maxD = cal.getDaysInMonth(y, m);
          if (d > maxD) d = maxD;
          return AlertDialog(
            backgroundColor: colors['cardBg'],
            title: Text(isBirth ? t('Birth (Hijri)', 'জন্ম (হিজরি)') : t('Present (Hijri)', 'বর্তমান (হিজরি)'), style: TextStyle(color: colors['textPrimary'], fontSize: 16.sp, fontWeight: FontWeight.w700)),
            content: Row(children: [
              Expanded(flex: 3, child: _dropdown(label: t('Day', 'দিন'), value: d, items: [for (var i = 1; i <= maxD; i++) DropdownMenuItem(value: i, child: Text(AgeUtils.digits(i.toString(), isBangla), style: TextStyle(color: colors['textPrimary'])))], onChanged: (v) => setState(() => d = v!), colors: colors)),
              SizedBox(width: 8.w),
              Expanded(flex: 5, child: _dropdown(label: t('Month', 'মাস'), value: m, items: [for (var i = 1; i <= 12; i++) DropdownMenuItem(value: i, child: Text(AgeUtils.hijriMonthName(i, isBangla), overflow: TextOverflow.ellipsis, style: TextStyle(color: colors['textPrimary'])))], onChanged: (v) => setState(() => m = v!), colors: colors)),
              SizedBox(width: 8.w),
              Expanded(flex: 4, child: _dropdown(label: t('Year', 'বছর'), value: y, items: [for (var i = 1525; i >= 1318; i--) DropdownMenuItem(value: i, child: Text(AgeUtils.digits(i.toString(), isBangla), style: TextStyle(color: colors['textPrimary'])))], onChanged: (v) => setState(() => y = v!), colors: colors)),
            ]),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(t('Cancel', 'বাতিল'), style: TextStyle(color: colors['textSecondary']))),
              TextButton(onPressed: () { final g = cal.hijriToGregorian(y, m, d); Navigator.of(ctx).pop(DateTime(g.year, g.month, g.day)); }, child: Text(t('OK', 'ঠিক আছে'), style: TextStyle(color: colors['accent'], fontWeight: FontWeight.w700))),
            ],
          );
        },
      ),
    );
  }

  static Future<DateTime?> pickBangla(BuildContext context, {required bool isBirth, required DateTime initial, required Map<String, Color> colors, required bool isBangla}) {
    final start = AgeUtils.toBangla(initial);
    var y = start.year.clamp(1306, 1507), m = start.month, d = start.day;
    final t = (String en, String bn) => isBangla ? bn : en;

    return showDialog<DateTime>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          final maxD = AgeUtils.banglaMonthDays(y + 593)[m - 1];
          if (d > maxD) d = maxD;
          return AlertDialog(
            backgroundColor: colors['cardBg'],
            title: Text(isBirth ? t('Birth (Bengali)', 'জন্ম (বাংলা)') : t('Present (Bengali)', 'বর্তমান (বাংলা)'), style: TextStyle(color: colors['textPrimary'], fontSize: 16.sp, fontWeight: FontWeight.w700)),
            content: Row(children: [
              Expanded(flex: 3, child: _dropdown(label: t('Day', 'দিন'), value: d, items: [for (var i = 1; i <= maxD; i++) DropdownMenuItem(value: i, child: Text(AgeUtils.digits(i.toString(), isBangla), style: TextStyle(color: colors['textPrimary'])))], onChanged: (v) => setState(() => d = v!), colors: colors)),
              SizedBox(width: 8.w),
              Expanded(flex: 5, child: _dropdown(label: t('Month', 'মাস'), value: m, items: [for (var i = 1; i <= 12; i++) DropdownMenuItem(value: i, child: Text(AgeUtils.banglaMonthName(i, isBangla), overflow: TextOverflow.ellipsis, style: TextStyle(color: colors['textPrimary'])))], onChanged: (v) => setState(() => m = v!), colors: colors)),
              SizedBox(width: 8.w),
              Expanded(flex: 4, child: _dropdown(label: t('Year', 'বছর'), value: y, items: [for (var i = 1507; i >= 1306; i--) DropdownMenuItem(value: i, child: Text(AgeUtils.digits(i.toString(), isBangla), style: TextStyle(color: colors['textPrimary'])))], onChanged: (v) => setState(() => y = v!), colors: colors)),
            ]),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(t('Cancel', 'বাতিল'), style: TextStyle(color: colors['textSecondary']))),
              TextButton(onPressed: () => Navigator.of(ctx).pop(AgeUtils.fromBangla(y, m, d)), child: Text(t('OK', 'ঠিক আছে'), style: TextStyle(color: colors['accent'], fontWeight: FontWeight.w700))),
            ],
          );
        },
      ),
    );
  }

  static Widget _dropdown<T>({required String label, required T value, required List<DropdownMenuItem<T>> items, required ValueChanged<T?> onChanged, required Map<String, Color> colors}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(color: colors['textSecondary'], fontSize: 11.sp, fontWeight: FontWeight.w600)),
      SizedBox(height: 4.h),
      DropdownButton<T>(value: value, items: items, onChanged: onChanged, isExpanded: true, underline: Container(height: 1, color: colors['cardBorder']), dropdownColor: colors['cardBg'], style: TextStyle(color: colors['textPrimary'], fontSize: 14.sp), iconEnabledColor: colors['accent']),
    ]);
  }
}
