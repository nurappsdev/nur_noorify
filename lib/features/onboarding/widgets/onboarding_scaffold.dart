import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:first_project/shared/widgets/noorify_glass.dart';

/// Shared layout for the first-launch onboarding steps: glass background, a step
/// indicator, scrollable content, an optional footer, and the action buttons.
class OnboardingScaffold extends StatelessWidget {
  const OnboardingScaffold({
    super.key,
    required this.step,
    required this.totalSteps,
    required this.title,
    required this.content,
    required this.primaryLabel,
    required this.onPrimary,
    this.subtitle,
    this.footer,
    this.primaryBusy = false,
    this.secondaryLabel,
    this.onSecondary,
  });

  final int step;
  final int totalSteps;
  final String title;
  final String? subtitle;
  final Widget content;
  final Widget? footer;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final bool primaryBusy;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    final glass = NoorifyGlassTheme(context);

    return Scaffold(
      backgroundColor: glass.bgBottom,
      body: NoorifyGlassBackground(
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20.w, 18.h, 20.w, 18.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _StepDots(step: step, totalSteps: totalSteps, glass: glass),
                SizedBox(height: 26.h),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 24.sp,
                            fontWeight: FontWeight.w800,
                            color: glass.textPrimary,
                          ),
                        ),
                        if (subtitle != null) ...[
                          SizedBox(height: 8.h),
                          Text(
                            subtitle!,
                            style: TextStyle(
                              fontSize: 14.sp,
                              height: 1.4,
                              color: glass.textSecondary,
                            ),
                          ),
                        ],
                        SizedBox(height: 22.h),
                        content,
                      ],
                    ),
                  ),
                ),
                if (footer != null) ...[
                  SizedBox(height: 12.h),
                  footer!,
                ],
                SizedBox(height: 14.h),
                SizedBox(
                  height: 50.h,
                  child: FilledButton(
                    onPressed: primaryBusy ? null : onPrimary,
                    style: FilledButton.styleFrom(
                      backgroundColor: glass.accent,
                      foregroundColor: glass.isDark
                          ? const Color(0xFF072734)
                          : Colors.white,
                      shape: const StadiumBorder(),
                    ),
                    child: primaryBusy
                        ? SizedBox(
                            width: 20.r,
                            height: 20.r,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            primaryLabel,
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
                if (secondaryLabel != null)
                  TextButton(
                    onPressed: primaryBusy ? null : onSecondary,
                    child: Text(
                      secondaryLabel!,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: glass.textSecondary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StepDots extends StatelessWidget {
  const _StepDots({
    required this.step,
    required this.totalSteps,
    required this.glass,
  });

  final int step;
  final int totalSteps;
  final NoorifyGlassTheme glass;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(totalSteps, (index) {
        final active = index == step - 1;
        return Padding(
          padding: EdgeInsets.only(right: 6.w),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: active ? 26.w : 10.w,
            height: 6.h,
            decoration: BoxDecoration(
              color: active ? glass.accent : glass.textSecondary.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(3.r),
            ),
          ),
        );
      }),
    );
  }
}
