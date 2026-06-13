import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import 'package:first_project/features/age_calculator/providers/boyos_zacai_provider.dart';
import 'package:first_project/features/age_calculator/utils/age_utils.dart';
import 'package:first_project/features/age_calculator/widgets/age_date_field.dart';
import 'package:first_project/features/age_calculator/widgets/age_pickers.dart';
import 'package:first_project/features/age_calculator/widgets/age_result_widgets.dart';
import 'package:first_project/shared/providers/language_provider.dart';

class BoyosZacaiScreen extends StatelessWidget {
  const BoyosZacaiScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<BoyosZacaiProvider>(create: (_) => BoyosZacaiProvider(), child: const _BoyosZacaiView());
  }
}

class _BoyosZacaiView extends StatefulWidget {
  const _BoyosZacaiView();
  @override
  State<_BoyosZacaiView> createState() => _BoyosZacaiViewState();
}

class _BoyosZacaiViewState extends State<_BoyosZacaiView> {
  BoyosZacaiProvider get _calc => context.read<BoyosZacaiProvider>();
  bool get _isBn => context.read<LanguageProvider>().isBangla;
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  Map<String, Color> get _colors => {
    'bg': _isDark ? const Color(0xFF060C17) : const Color(0xFFF0F7FC),
    'cardBg': _isDark ? const Color(0xFF101C2A) : Colors.white,
    'cellBg': _isDark ? const Color(0xFF16283A) : const Color(0xFFEEF5FA),
    'cardBorder': _isDark ? const Color(0x22D2F4FF) : const Color(0xFFDCE8F1),
    'textPrimary': _isDark ? Colors.white : const Color(0xFF143349),
    'textSecondary': _isDark ? const Color(0xFF9BC1D8) : const Color(0xFF5F7E94),
    'accent': _isDark ? const Color(0xFF1FD5C0) : const Color(0xFF1EA8B8),
  };

  String _t(String en, String bn) => _isBn ? bn : en;

  Future<void> _pick(bool isBirth) async {
    final cType = isBirth ? _calc.birthCalendar : _calc.presentCalendar;
    final init = isBirth ? (_calc.birthDate ?? DateTime(2000, 1, 1)) : _calc.presentDate;
    final DateTime? picked;
    if (cType == CalendarType.hijri) {
      picked = await AgePickers.pickHijri(context, isBirth: isBirth, initial: init, colors: _colors, isBangla: _isBn);
    } else if (cType == CalendarType.bengali) {
      picked = await AgePickers.pickBangla(context, isBirth: isBirth, initial: init, colors: _colors, isBangla: _isBn);
    } else {
      picked = await showDatePicker(context: context, initialDate: init, firstDate: DateTime(1900), lastDate: DateTime(2100, 12, 31), helpText: isBirth ? _t('Select DOB', 'জন্ম তারিখ নির্বাচন') : _t('Select Present Date', 'বর্তমান তারিখ নির্বাচন'));
    }
    if (picked != null) isBirth ? _calc.setBirthDate(picked) : _calc.setPresentDate(picked);
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LanguageProvider>();
    context.watch<BoyosZacaiProvider>();
    final age = AgeUtils.calculateAge(_calc.birthDate, _calc.presentDate);
    return Scaffold(
      backgroundColor: _colors['bg'],
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, foregroundColor: _colors['textPrimary'], title: Text(_t('Boyos Zacai', 'বয়স যাচাই'), style: TextStyle(color: _colors['textPrimary'], fontSize: 18.sp, fontWeight: FontWeight.w700))),
      body: SafeArea(
        child: ListView(padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h), children: [
          AgeDateField(label: _t('Present date', 'বর্তমান তারিখ'), icon: Icons.today_rounded, value: AgeUtils.formatDate(_calc.presentDate, _calc.presentCalendar, _isBn), calendar: _calc.presentCalendar, onCalendarChanged: (c) => _calc.setPresentCalendar(c), onTap: () => _pick(false), isBangla: _isBn, colors: _colors),
          SizedBox(height: 12.h),
          AgeDateField(label: _t('Date of birth', 'জন্ম তারিখ'), icon: Icons.cake_rounded, value: _calc.birthDate == null ? _t('Tap to select', 'নির্বাচন করতে চাপুন') : AgeUtils.formatDate(_calc.birthDate!, _calc.birthCalendar, _isBn), calendar: _calc.birthCalendar, onCalendarChanged: (c) => _calc.setBirthCalendar(c), onTap: () => _pick(true), isBangla: _isBn, colors: _colors, placeholder: _calc.birthDate == null),
          SizedBox(height: 20.h),
          if (age == null) Container(padding: EdgeInsets.all(16.r), decoration: BoxDecoration(color: _colors['cardBg'], borderRadius: BorderRadius.circular(14.r), border: Border.all(color: _colors['cardBorder']!)), child: Row(children: [Icon(Icons.info_outline_rounded, color: _colors['textSecondary'], size: 20.sp), SizedBox(width: 10.w), Expanded(child: Text(_calc.birthDate != null ? _t('DOB must be before present.', 'জন্ম তারিখ অবশ্যই বর্তমানের আগে হতে হবে।') : _t('Select DOB to calculate.', 'বয়স গণনা করতে জন্ম তারিখ নির্বাচন করুন।'), style: TextStyle(color: _colors['textSecondary'], fontSize: 13.sp, fontWeight: FontWeight.w600)))]))
          else AgeResultView(age: age, isBangla: _isBn, isDark: _isDark, colors: _colors),
        ]),
      ),
    );
  }
}
