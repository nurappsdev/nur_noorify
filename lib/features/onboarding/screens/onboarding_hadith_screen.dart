import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:first_project/core/constants/route_names.dart';
import 'package:first_project/features/onboarding/widgets/onboarding_scaffold.dart';
import 'package:first_project/shared/services/app_globals.dart';
import 'package:first_project/shared/widgets/noorify_glass.dart';

/// First onboarding step: a welcoming Hadith and the privacy agreement gate.
class OnboardingHadithScreen extends StatelessWidget {
  const OnboardingHadithScreen({super.key});

  bool get _isBangla => appLanguageNotifier.value == AppLanguage.bangla;

  String _t(String en, String bn) => _isBangla ? bn : en;

  @override
  Widget build(BuildContext context) {
    final glass = NoorifyGlassTheme(context);

    return OnboardingScaffold(
      step: 1,
      totalSteps: 3,
      title: _t('Welcome to Noorify', 'নুরিফাইতে স্বাগতম'),
      subtitle: _t(
        'Your daily companion for prayer, Quran, and remembrance.',
        'নামাজ, কুরআন ও জিকিরের জন্য আপনার দৈনন্দিন সঙ্গী।',
      ),
      content: NoorifyGlassCard(
        padding: EdgeInsets.fromLTRB(18.w, 20.h, 18.w, 20.h),
        radius: BorderRadius.circular(20.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.auto_stories_rounded, size: 30.sp, color: glass.accent),
            SizedBox(height: 14.h),
            Text(
              'إِنَّمَا الأَعْمَالُ بِالنِّيَّاتِ',
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontSize: 22.sp,
                height: 1.6,
                fontWeight: FontWeight.w600,
                color: glass.textPrimary,
              ),
            ),
            SizedBox(height: 14.h),
            Text(
              _t(
                '"Actions are judged only by intentions, and every person will have only what they intended."',
                '"নিশ্চয়ই কাজের ফলাফল নিয়তের উপর নির্ভরশীল, এবং প্রত্যেক ব্যক্তি তা-ই পাবে যা সে নিয়ত করেছে।"',
              ),
              style: TextStyle(
                fontSize: 14.5.sp,
                height: 1.5,
                color: glass.textSecondary,
              ),
            ),
            SizedBox(height: 10.h),
            Text(
              _t('— Sahih al-Bukhari', '— সহীহ বুখারি'),
              style: TextStyle(
                fontSize: 12.5.sp,
                fontWeight: FontWeight.w700,
                color: glass.accent,
              ),
            ),
          ],
        ),
      ),
      footer: _PrivacyNote(glass: glass, isBangla: _isBangla),
      primaryLabel: _t('Agree and Continue', 'সম্মত হয়ে এগিয়ে যান'),
      onPrimary: () => Navigator.of(
        context,
      ).pushNamed(RouteNames.onboardingLanguage),
    );
  }
}

class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote({required this.glass, required this.isBangla});

  final NoorifyGlassTheme glass;
  final bool isBangla;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          isBangla
              ? 'এগিয়ে যাওয়ার মাধ্যমে আপনি আমাদের '
              : 'By continuing you agree to our ',
          style: TextStyle(fontSize: 12.5.sp, color: glass.textSecondary),
        ),
        GestureDetector(
          onTap: () =>
              Navigator.of(context).pushNamed(RouteNames.privacyPolicy),
          child: Text(
            isBangla ? 'প্রাইভেসি পলিসি' : 'Privacy Policy',
            style: TextStyle(
              fontSize: 12.5.sp,
              fontWeight: FontWeight.w700,
              color: glass.accent,
              decoration: TextDecoration.underline,
              decorationColor: glass.accent,
            ),
          ),
        ),
        Text(
          isBangla ? ' মেনে নিচ্ছেন।' : '.',
          style: TextStyle(fontSize: 12.5.sp, color: glass.textSecondary),
        ),
      ],
    );
  }
}
