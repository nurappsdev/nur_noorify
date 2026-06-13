import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:first_project/features/age_calculator/utils/age_utils.dart';

class AgeResultView extends StatelessWidget {
  const AgeResultView({super.key, required this.age, required this.isBangla, required this.isDark, required this.colors});

  final ({int years, int months, int days, int totalMinutes}) age;
  final bool isBangla;
  final bool isDark;
  final Map<String, Color> colors;

  String _t(String en, String bn) => isBangla ? bn : en;

  @override
  Widget build(BuildContext context) {
    final cells = [
      (label: _t('Years', 'বছর'), value: AgeUtils.digits(age.years.toString(), isBangla)),
      (label: _t('Months', 'মাস'), value: AgeUtils.digits(age.months.toString(), isBangla)),
      (label: _t('Days', 'দিন'), value: AgeUtils.digits(age.days.toString(), isBangla)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_t('Calculated Age', 'গণনাকৃত বয়স'), style: TextStyle(color: colors['textPrimary'], fontSize: 15.sp, fontWeight: FontWeight.w700)),
        SizedBox(height: 12.h),
        Row(
          children: [
            for (var i = 0; i < cells.length; i++) ...[
              Expanded(child: _buildStatCell(cells[i].value, cells[i].label)),
              if (i != cells.length - 1) SizedBox(width: 10.w),
            ],
          ],
        ),
        SizedBox(height: 10.h),
        _buildMinutesCell(AgeUtils.digits(age.totalMinutes.toString(), isBangla)),
      ],
    );
  }

  Widget _buildStatCell(String value, String label) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 8.w),
      decoration: BoxDecoration(color: colors['cardBg'], borderRadius: BorderRadius.circular(14.r), border: Border.all(color: colors['cardBorder']!)),
      child: Column(
        children: [
          Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: colors['accent'], fontSize: 24.sp, fontWeight: FontWeight.w800)),
          SizedBox(height: 4.h),
          Text(label, style: TextStyle(color: colors['textSecondary'], fontSize: 12.sp, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildMinutesCell(String value) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark ? const [Color(0xFF13404B), Color(0xFF0F2F3A)] : const [Color(0xFFE3F4F7), Color(0xFFD3ECF1)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14.r), border: Border.all(color: colors['cardBorder']!),
      ),
      child: Row(
        children: [
          Icon(Icons.timer_outlined, color: colors['accent'], size: 22.sp),
          SizedBox(width: 12.w),
          Expanded(child: Text(_t('Total Minutes', 'মোট মিনিট'), style: TextStyle(color: colors['textSecondary'], fontSize: 13.sp, fontWeight: FontWeight.w600))),
          Text(value, style: TextStyle(color: colors['textPrimary'], fontSize: 18.sp, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
