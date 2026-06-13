import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:first_project/features/mosque/utils/mosque_utils.dart';
import 'package:first_project/shared/widgets/noorify_glass.dart';

class MosqueEmptyState extends StatelessWidget {
  const MosqueEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onRetry,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final glass = NoorifyGlassTheme(context);
    return Padding(
      padding: EdgeInsets.only(top: 14.h),
      child: NoorifyGlassCard(
        padding: EdgeInsets.all(16.r),
        radius: BorderRadius.circular(16.r),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: glass.textSecondary),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700, color: glass.textPrimary)),
                  SizedBox(height: 2.h),
                  Text(subtitle, style: TextStyle(fontSize: 12.sp, color: glass.textSecondary, fontWeight: FontWeight.w500)),
                  if (onRetry != null) ...[
                    SizedBox(height: 10.h),
                    SizedBox(
                      height: 30.h,
                      child: FilledButton(
                        onPressed: onRetry,
                        style: FilledButton.styleFrom(
                          backgroundColor: glass.accent,
                          foregroundColor: glass.isDark ? const Color(0xFF072734) : Colors.white,
                          textStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.sp),
                          shape: const StadiumBorder(),
                        ),
                        child: Text(MosqueUtils.text('Retry', 'আবার চেষ্টা করুন')),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
