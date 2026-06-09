import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:first_project/features/age_calculator/providers/boyos_zacai_provider.dart';

class AgeDateField extends StatelessWidget {
  const AgeDateField({
    super.key,
    required this.label,
    required this.icon,
    required this.value,
    required this.calendar,
    required this.onCalendarChanged,
    required this.onTap,
    required this.isBangla,
    required this.colors,
    this.placeholder = false,
  });

  final String label;
  final IconData icon;
  final String value;
  final CalendarType calendar;
  final ValueChanged<CalendarType> onCalendarChanged;
  final VoidCallback onTap;
  final bool isBangla;
  final bool placeholder;
  final Map<String, Color> colors;

  String _t(String en, String bn) => isBangla ? bn : en;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(color: colors['cardBg'], borderRadius: BorderRadius.circular(14.r), border: Border.all(color: colors['cardBorder']!)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: colors['textSecondary'], fontSize: 11.5.sp, fontWeight: FontWeight.w600))),
              SizedBox(width: 8.w),
              _buildCalendarToggle(),
            ],
          ),
          SizedBox(height: 10.h),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(11.r),
              onTap: onTap,
              child: Row(
                children: [
                  Container(
                    width: 40.r, height: 40.r,
                    decoration: BoxDecoration(color: colors['cellBg'], borderRadius: BorderRadius.circular(11.r)),
                    child: Icon(icon, color: colors['accent'], size: 21.sp),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(child: Text(value, style: TextStyle(color: placeholder ? colors['textSecondary'] : colors['textPrimary'], fontSize: 15.sp, fontWeight: FontWeight.w700))),
                  Icon(Icons.edit_calendar_rounded, color: colors['textSecondary'], size: 18.sp),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarToggle() {
    Widget segment(CalendarType type, String lbl) {
      final isActive = calendar == type;
      return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(9.r),
          onTap: isActive ? null : () => onCalendarChanged(type),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 5.h),
            decoration: BoxDecoration(color: isActive ? colors['accent'] : Colors.transparent, borderRadius: BorderRadius.circular(9.r)),
            child: Text(lbl, style: TextStyle(color: isActive ? Colors.white : colors['textSecondary'], fontSize: 11.sp, fontWeight: FontWeight.w700)),
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(2.r),
      decoration: BoxDecoration(color: colors['cellBg'], borderRadius: BorderRadius.circular(11.r), border: Border.all(color: colors['cardBorder']!)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          segment(CalendarType.gregorian, _t('English', 'ইংরেজি')),
          segment(CalendarType.hijri, _t('Arabic', 'আরবি')),
          segment(CalendarType.bengali, _t('Bengali', 'বাংলা')),
        ],
      ),
    );
  }
}
