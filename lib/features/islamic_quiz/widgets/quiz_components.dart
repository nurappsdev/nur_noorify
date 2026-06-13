import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:first_project/shared/widgets/noorify_glass.dart';

/// Screen header with an optional back button, a title and an optional subtitle.
class QuizHeader extends StatelessWidget {
  const QuizHeader({
    super.key,
    required this.title,
    this.subtitle = '',
    this.onBack,
  });

  final String title;
  final String subtitle;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final glass = NoorifyGlassTheme(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (onBack != null)
              Padding(
                padding: EdgeInsets.only(right: 6.w),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20.r),
                  onTap: onBack,
                  child: Icon(
                    Icons.arrow_back_rounded,
                    color: glass.textPrimary,
                    size: 24.r,
                  ),
                ),
              ),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w700,
                  color: glass.textPrimary,
                ),
              ),
            ),
          ],
        ),
        if (subtitle.isNotEmpty) ...[
          SizedBox(height: 2.h),
          Text(
            subtitle,
            style: TextStyle(fontSize: 12.5.sp, color: glass.textSecondary),
          ),
        ],
      ],
    );
  }
}

/// A large menu card with a leading icon, title and subtitle. Used for the
/// home actions (Start / Settings) and the topic segments.
class QuizMenuCard extends StatelessWidget {
  const QuizMenuCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final glass = NoorifyGlassTheme(context);
    return InkWell(
      borderRadius: BorderRadius.circular(16.r),
      onTap: onTap,
      child: NoorifyGlassCard(
        radius: BorderRadius.circular(16.r),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        child: Row(
          children: [
            Container(
              width: 44.r,
              height: 44.r,
              decoration: BoxDecoration(
                color: glass.accent.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(icon, color: glass.accent, size: 24.r),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15.5.sp,
                      fontWeight: FontWeight.w700,
                      color: glass.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11.5.sp,
                      color: glass.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: glass.textMuted, size: 22.r),
          ],
        ),
      ),
    );
  }
}

/// A compact, vertically-stacked card sized for a 2-column grid (used by the
/// topic chooser): icon on top, then a centred title and subtitle.
class QuizTopicCard extends StatelessWidget {
  const QuizTopicCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final glass = NoorifyGlassTheme(context);
    return InkWell(
      borderRadius: BorderRadius.circular(16.r),
      onTap: onTap,
      child: NoorifyGlassCard(
        radius: BorderRadius.circular(16.r),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 16.h),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48.r,
              height: 48.r,
              decoration: BoxDecoration(
                color: glass.accent.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(14.r),
              ),
              child: Icon(icon, color: glass.accent, size: 26.r),
            ),
            SizedBox(height: 10.h),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                color: glass.textPrimary,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 10.5.sp, color: glass.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
