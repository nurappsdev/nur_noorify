import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:first_project/core/constants/route_names.dart';
import 'package:first_project/features/onboarding/widgets/onboarding_scaffold.dart';
import 'package:first_project/shared/services/app_globals.dart';
import 'package:first_project/shared/widgets/noorify_glass.dart';

/// Second onboarding step: pick the app language and request notification
/// access. "Skip Now" moves on without changing the language or prompting.
class OnboardingLanguageScreen extends StatefulWidget {
  const OnboardingLanguageScreen({super.key});

  @override
  State<OnboardingLanguageScreen> createState() =>
      _OnboardingLanguageScreenState();
}

class _OnboardingLanguageScreenState extends State<OnboardingLanguageScreen> {
  late AppLanguage _selected = appLanguageNotifier.value;
  bool _busy = false;

  bool get _isBangla => _selected == AppLanguage.bangla;

  String _t(String en, String bn) => _isBangla ? bn : en;

  Future<void> _continue() async {
    setState(() => _busy = true);
    appLanguageNotifier.value = _selected;
    await saveAppPreferences();
    try {
      await ensureNotificationPermissions();
    } catch (_) {
      // Permission prompt failures shouldn't block onboarding.
    }
    if (!mounted) return;
    Navigator.of(context).pushNamed(RouteNames.onboardingLocation);
  }

  void _skip() =>
      Navigator.of(context).pushNamed(RouteNames.onboardingLocation);

  @override
  Widget build(BuildContext context) {
    final glass = NoorifyGlassTheme(context);

    return OnboardingScaffold(
      step: 2,
      totalSteps: 3,
      title: _t('Select Your Language', 'আপনার ভাষা নির্বাচন করুন'),
      subtitle: _t(
        'We will also ask permission to send prayer and reminder notifications.',
        'নামাজ ও রিমাইন্ডার নোটিফিকেশন পাঠানোর অনুমতিও চাওয়া হবে।',
      ),
      content: Column(
        children: [
          _LanguageTile(
            label: 'English',
            sublabel: 'English',
            selected: _selected == AppLanguage.english,
            glass: glass,
            onTap: () => setState(() => _selected = AppLanguage.english),
          ),
          SizedBox(height: 12.h),
          _LanguageTile(
            label: 'বাংলা',
            sublabel: 'Bangla',
            selected: _selected == AppLanguage.bangla,
            glass: glass,
            onTap: () => setState(() => _selected = AppLanguage.bangla),
          ),
        ],
      ),
      primaryLabel: _t('Continue', 'এগিয়ে যান'),
      primaryBusy: _busy,
      onPrimary: _continue,
      secondaryLabel: _t('Skip Now', 'এখন এড়িয়ে যান'),
      onSecondary: _skip,
    );
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.label,
    required this.sublabel,
    required this.selected,
    required this.glass,
    required this.onTap,
  });

  final String label;
  final String sublabel;
  final bool selected;
  final NoorifyGlassTheme glass;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 16.h),
        decoration: BoxDecoration(
          color: selected
              ? glass.accent.withValues(alpha: glass.isDark ? 0.22 : 0.12)
              : glass.glassStart.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: selected ? glass.accent : glass.glassBorder,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: glass.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    sublabel,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: glass.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: selected ? glass.accent : glass.textSecondary,
              size: 22.sp,
            ),
          ],
        ),
      ),
    );
  }
}
